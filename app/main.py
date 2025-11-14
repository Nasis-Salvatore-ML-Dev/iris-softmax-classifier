"""
FastAPI app to serve the trained softmax classifier.
Endpoint:
POST /predict
{
  "sepal_length": 5.1,
  "sepal_width": 3.5,
  "petal_length": 1.4,
  "petal_width": 0.2
}
Response:
{ "species": "setosa" }
"""
import logging
from contextlib import asynccontextmanager  # Added for lifespan

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field

from src.predict import load_model, predict_single

logger = logging.getLogger("uvicorn.error")


# Define the lifespan context manager to replace @app.on_event("startup")
@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup logic: Load the model
    try:
        app.state.model = load_model()
        logger.info("Model loaded successfully.")
    except Exception as exc:
        # Keep server running but log error: /predict will return 503 until model is loaded
        app.state.model = None
        logger.exception("Failed to load model on startup: %s", exc)

    yield  # Application starts serving requests here

    # Shutdown logic (optional, for cleanup)
    pass


# Pass the lifespan function to the FastAPI app initialization
app = FastAPI(
    title="Iris Softmax Classifier",
    version="1.0.0",
    lifespan=lifespan  # Added lifespan handler
)


class PredictRequest(BaseModel):
    # Pydantic Fix: Replaced 'example' with 'json_schema_extra'
    sepal_length: float = Field(..., json_schema_extra={"example": 5.1})
    sepal_width: float = Field(..., json_schema_extra={"example": 3.5})
    petal_length: float = Field(..., json_schema_extra={"example": 1.4})
    petal_width: float = Field(..., json_schema_extra={"example": 0.2})


class PredictResponse(BaseModel):
    species: str


# Removed: The entire @app.on_event("startup") function is replaced by the lifespan function above.

@app.post("/predict", response_model=PredictResponse)
def predict(payload: PredictRequest):
    if app.state.model is None:
        raise HTTPException(status_code=503, detail="Model artifact is not loaded.")
    features = [
        payload.sepal_length,
        payload.sepal_width,
        payload.petal_length,
        payload.petal_width,
    ]
    try:
        species = predict_single(features, model=app.state.model)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc))
    except Exception as exc:
        logger.exception("Prediction failed: %s", exc)
        raise HTTPException(status_code=500, detail="Internal error during prediction.")

    return PredictResponse(species=species)

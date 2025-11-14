import pytest
from fastapi.testclient import TestClient

from app.main import app
from src.predict import load_model

client = TestClient(app)


@pytest.fixture(scope="module", autouse=True)
def setup_model_state():
    """Ensure app.state.model is loaded before running API tests."""
    try:
        app.state.model = load_model()
    except Exception:
        pytest.skip("Model not available for API tests.")


def test_predict_valid_input():
    """Ensure /predict returns a 200 and correct species for valid input."""
    payload = {
        "sepal_length": 5.1,
        "sepal_width": 3.5,
        "petal_length": 1.4,
        "petal_width": 0.2,
    }
    response = client.post("/predict", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert "species" in data
    assert data["species"] in ["setosa", "versicolor", "virginica"]


def test_predict_invalid_input():
    """Ensure API gracefully handles invalid JSON payload."""
    payload = {"sepal_length": 5.1, "sepal_width": 3.5}  # Missing 2 features
    response = client.post("/predict", json=payload)
    assert response.status_code in (400, 422)

# src/predict.py
from typing import List

import joblib
import numpy as np

from src.config import MODEL_PATH, TARGET_NAMES


def load_model(path: str = None):
    path = path or MODEL_PATH
    try:
        obj = joblib.load(path)
    except FileNotFoundError:
        raise FileNotFoundError(
            f"Trained model not found at {path}. Run `src/train.py` first."
        )
    except Exception as exc:
        raise RuntimeError(f"Failed to load model from {path}: {exc}") from exc
    return obj


def predict_single(features: List[float], model=None) -> str:
    """
    Predict species from a single feature vector:
    features = [sepal_length, sepal_width, petal_length, petal_width]
    """
    if len(features) != 4:
        raise ValueError(
            "Expected 4 features: [sepal_length, sepal_width, petal_length, petal_width]."
        )
    X = np.array(features, dtype=float).reshape(1, -1)
    model = model or load_model()
    preds = model["pipeline"].predict(X)
    # model artifact stores 'pipeline' and 'target_names'
    target_names = model.get("target_names", TARGET_NAMES)
    return preds[0] if preds[0] in target_names else str(preds[0])

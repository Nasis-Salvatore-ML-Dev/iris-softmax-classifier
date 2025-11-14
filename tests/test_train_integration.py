# tests/test_train_integration.py
"""
Purpose
*   Runs the entire training pipeline end-to-end in isolation.
*   Validates serialization to disk (joblib) and artifact structure.
*   Covers src/train.py thoroughly — without touching your production artifacts.
"""
# import tempfile
from pathlib import Path

import joblib

from src import train


def test_training_creates_artifact(tmp_path: Path, monkeypatch):
    """Run training pipeline and ensure artifact is created with accuracy metric."""

    # Patch MODEL_PATH to temporary directory so we don't overwrite real model
    fake_model_path = tmp_path / "model.pkl"
    monkeypatch.setattr(train, "MODEL_PATH", fake_model_path)

    exit_code = train.main()
    assert exit_code == 0
    assert fake_model_path.exists()

    artifact = joblib.load(fake_model_path)
    assert "pipeline" in artifact
    assert "metrics" in artifact
    assert "accuracy" in artifact["metrics"] or "accuracy" in artifact["metrics"].keys()

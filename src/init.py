# src/__init__.py
"""
Iris Softmax Classifier - Core ML Package

This package contains the complete ML pipeline for training and serving
a softmax (multinomial logistic regression) classifier on the Iris dataset.

Modules:
    - config: Configuration and path management
    - data_processing: Data loading and preprocessing
    - model: Softmax classifier implementation
    - train: Training script
    - predict: Prediction and model loading utilities
"""

__version__ = "1.0.0"
__author__ = "ML Team"

from src.data_processing import load_iris_dataframe, prepare_train_test
from src.model import SoftmaxClassifier
from src.predict import load_model, predict_single

__all__ = [
    "SoftmaxClassifier",
    "predict_single",
    "load_model",
    "load_iris_dataframe",
    "prepare_train_test",
]

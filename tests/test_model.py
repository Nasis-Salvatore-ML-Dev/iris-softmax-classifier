# tests/test_model.py
"""
Purpose:
*   Directly tests the core model class (fit/predict).
*   Confirms model pipeline structure and label integrity.
*   Provides significant coverage of src/model.py.
"""

import numpy as np

from src.data_processing import load_iris_dataframe, prepare_train_test
from src.model import SoftmaxClassifier


def test_softmax_classifier_training_and_prediction():
    """Ensure SoftmaxClassifier can train and predict with correct labels."""
    df = load_iris_dataframe()
    X_train, X_test, y_train, y_test = prepare_train_test(df)

    model = SoftmaxClassifier()
    model.fit(X_train, y_train)
    preds = model.predict(X_test)

    assert isinstance(preds, np.ndarray)
    assert len(preds) == len(y_test)
    assert set(preds).issubset(set(y_train))

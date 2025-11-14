# tests/test_predictions.py

import pytest

from src.predict import load_model, predict_single


@pytest.fixture(scope="session")
def model():
    """Load the model once for all tests."""
    return load_model()


def test_predict_setosa(model):
    """
    From the real Iris dataset, we know that
    such a flower is labeled as "setosa".
    It checks the model indeed captures this
    true value
    """

    result = predict_single([5.1, 3.5, 1.4, 0.2], model)
    assert result == "setosa"


def test_predict_versicolor(model):
    result = predict_single([7.0, 3.2, 4.7, 1.4], model)
    assert result == "versicolor"


def test_predict_virginica(model):
    result = predict_single([6.3, 3.3, 6.0, 2.5], model)
    assert result == "virginica"


def test_invalid_input_length(model):
    """Ensure model raises an error if feature length is wrong."""
    with pytest.raises(ValueError):
        predict_single([1.0, 2.0, 3.0], model)

# tests/test_data_processing.py
"""
Purpose
*   Exercises the data I/O and preprocessing pipeline.
*   Validates that train/test splits and features are correctly structured.
*   Boosts coverage of src/data_processing.py.
"""

import pandas as pd

from src.data_processing import load_iris_dataframe, prepare_train_test


def test_load_iris_dataframe_shape():
    """Ensure dataset loads correctly with expected shape and columns."""
    df = load_iris_dataframe()
    assert isinstance(df, pd.DataFrame)
    expected_cols = {
        "sepal_length",
        "sepal_width",
        "petal_length",
        "petal_width",
        "species",
    }
    assert expected_cols.issubset(df.columns)
    assert len(df) == 150  # Iris dataset has 150 rows


def test_prepare_train_test_splits():
    """Ensure training and test splits are consistent."""
    df = load_iris_dataframe()
    X_train, X_test, y_train, y_test = prepare_train_test(df)
    assert len(X_train) > 0 and len(X_test) > 0
    assert len(X_train) + len(X_test) == len(df)
    assert X_train.shape[1] == 4

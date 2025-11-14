# src/data_processing.py
from typing import Tuple

import pandas as pd
from sklearn.model_selection import train_test_split

from src.config import IRIS_CSV, RANDOM_STATE, TEST_SIZE


def load_iris_dataframe(csv_path: str = None) -> pd.DataFrame:
    """Load iris CSV into a DataFrame. Raises helpful errors."""
    path = csv_path or IRIS_CSV
    try:
        df = pd.read_csv(path)
    except FileNotFoundError as exc:
        raise FileNotFoundError(f"Could not find data file at {path}") from exc
    except Exception as exc:
        raise RuntimeError(f"Failed to read CSV at {path}: {exc}") from exc

    expected_cols = {
        "sepal_length",
        "sepal_width",
        "petal_length",
        "petal_width",
        "species",
    }
    if not expected_cols.issubset(set(df.columns)):
        raise ValueError(
            f"CSV file at {path} is missing required columns. Found: {list(df.columns)}"
        )
    return df


def prepare_train_test(
    df, test_size: float = TEST_SIZE, random_state: int = RANDOM_STATE
) -> Tuple:
    """Return X_train, X_test, y_train, y_test."""
    X = df[["sepal_length", "sepal_width", "petal_length", "petal_width"]].values
    y = df["species"].values
    return train_test_split(
        X, y, test_size=test_size, random_state=random_state, stratify=y
    )

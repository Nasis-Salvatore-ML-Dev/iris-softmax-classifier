#!/usr/bin/env python3
"""
Fetch the Iris dataset and save it as CSV.
This script downloads the Iris dataset from sklearn and saves it to data/iris.csv
"""
import logging
from pathlib import Path

import pandas as pd
from sklearn import datasets

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
logger = logging.getLogger("fetch_data")


def fetch_iris_dataset():
    """Download Iris dataset from sklearn and save as CSV."""
    logger.info("Loading Iris dataset from sklearn...")
    iris = datasets.load_iris()
    
    # Create DataFrame
    df = pd.DataFrame(
        data=iris.data,
        columns=['sepal_length', 'sepal_width', 'petal_length', 'petal_width']
    )
    df['species'] = iris.target_names[iris.target]
    
    # Ensure data directory exists
    data_dir = Path(__file__).resolve().parents[1] / "data"
    data_dir.mkdir(parents=True, exist_ok=True)
    
    # Save to CSV
    csv_path = data_dir / "iris.csv"
    df.to_csv(csv_path, index=False)
    logger.info(f"Iris dataset saved to {csv_path}")
    logger.info(f"Dataset shape: {df.shape}")
    logger.info(f"Species distribution:\n{df['species'].value_counts()}")
    
    return csv_path


if __name__ == "__main__":
    fetch_iris_dataset()







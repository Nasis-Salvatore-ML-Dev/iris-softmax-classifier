# src/tune.py
"""
Hyperparameter tuning for SoftmaxClassifier using GridSearchCV
Saves best model and parameters to artifacts/tuned_model.pkl
"""
import logging
import sys
from time import time

import joblib
# import pandas as pd
from sklearn.model_selection import GridSearchCV

from src.config import ARTIFACTS_DIR, MODEL_PATH
from src.data_processing import load_iris_dataframe, prepare_train_test
from src.model import SoftmaxClassifier

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
logger = logging.getLogger("tune")

# Tuned model path
TUNED_MODEL_PATH = ARTIFACTS_DIR / "tuned_model.pkl"


def main():
    start = time()
    logger.info("Starting hyperparameter tuning...")

    try:
        df = load_iris_dataframe()
    except Exception as exc:
        logger.error("Failed to load data: %s", exc)
        sys.exit(2)

    X_train, X_test, y_train, y_test = prepare_train_test(df)

    # Initialize base model
    base_model = SoftmaxClassifier()

    # Define comprehensive parameter grid
    param_grid = {
        'clf__C': [0.001, 0.01, 0.1, 1, 10, 100, 1000],
        'clf__max_iter': [100, 200, 500, 1000],
        'clf__tol': [1e-4, 1e-3, 1e-2]
    }

    logger.info(
        "Starting GridSearchCV with %d parameter combinations...",
        len(param_grid["clf__C"])  # FIXED: Changed from "logisticregression__C"
        * len(param_grid["clf__max_iter"])  # FIXED: Changed from "logisticregression__max_iter"
        * len(param_grid["clf__tol"]),  # FIXED: Changed from "logisticregression__tol"
    )

    # Perform grid search
    grid_search = GridSearchCV(
        base_model.pipeline,
        param_grid,
        cv=5,
        scoring="accuracy",
        n_jobs=-1,  # Use all available cores
        return_train_score=True,
        verbose=1,
    )

    grid_search.fit(X_train, y_train)

    # Results analysis
    logger.info("GridSearchCV completed!")
    logger.info("Best CV score: %.4f", grid_search.best_score_)
    logger.info("Best parameters: %s", grid_search.best_params_)

    # Evaluate on test set
    test_score = grid_search.score(X_test, y_test)
    logger.info("Test score with best params: %.4f", test_score)

    # Compare with original model
    try:
        original_artifact = joblib.load(MODEL_PATH)
        original_test_acc = original_artifact["metrics"]["accuracy"]
        improvement = test_score - original_test_acc
        logger.info("Original test accuracy: %.4f", original_test_acc)
        logger.info("Improvement: %+.4f", improvement)
    except FileNotFoundError:
        logger.warning("Original model not found for comparison")

    # Save tuned model artifact
    artifact = {
        "pipeline": grid_search.best_estimator_,
        "target_names": list(sorted(set(y_train))),
        "metrics": {
            "accuracy": float(test_score),
            "cv_mean": float(grid_search.best_score_),
            "best_params": grid_search.best_params_,
        },
    }

    logger.info("Saving tuned model to %s", TUNED_MODEL_PATH)
    try:
        joblib.dump(artifact, TUNED_MODEL_PATH)
    except Exception as exc:
        logger.exception("Failed to save tuned model: %s", exc)
        sys.exit(3)

    training_time = time() - start

    # Clear summary output
    print("\n" + "=" * 60)
    print("HYPERPARAMETER TUNING SUMMARY")
    print("=" * 60)
    print(f"Best CV accuracy: {grid_search.best_score_:.4f}")
    print(f"Test accuracy: {test_score:.4f}")
    print(f"Best parameters: {grid_search.best_params_}")
    print(f"Training time: {training_time:.2f}s")
    print("=" * 60)

    return 0


if __name__ == "__main__":
    sys.exit(main())

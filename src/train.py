# src/train.py
"""
Train script for softmax (multinomial logistic) classifier on Iris dataset.
Saves model artifact at artifacts/model.pkl as a dict:
{
    "pipeline": trained_pipeline,
    "target_names": list_of_target_names,
    "metrics": { "accuracy": ..., "cv_mean": ..., "cv_std": ... }
}
"""
import logging
import sys
from time import time

import joblib
from sklearn.metrics import accuracy_score
from sklearn.model_selection import cross_val_score  # ✅ Added import

from src.config import MODEL_PATH
from src.data_processing import load_iris_dataframe, prepare_train_test
from src.model import SoftmaxClassifier

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
logger = logging.getLogger("train")

ACCURACY_THRESHOLD = 0.95  # acceptance criteria for CI checks


def main():
    start = time()
    logger.info("Loading data...")
    try:
        df = load_iris_dataframe()
    except Exception as exc:
        logger.error("Failed to load data: %s", exc)
        sys.exit(2)

    X_train, X_test, y_train, y_test = prepare_train_test(df)

    # Selects the model
    logger.info("Initializing model...")
    model = SoftmaxClassifier()

    # -------------------------------------------------------------
    # K-Fold Cross-Validation (robust evaluation before final training)
    # -------------------------------------------------------------
    try:
        logger.info("Performing 5-Fold Cross-Validation...")
        cv_scores = cross_val_score(
            model.pipeline, X_train, y_train, cv=5, scoring="accuracy"
        )
        mean_acc = cv_scores.mean()
        std_acc = cv_scores.std()
        logger.info("CV accuracy: %.4f ± %.4f", mean_acc, std_acc)
    except Exception as exc:
        logger.warning("Cross-validation failed: %s", exc)
        mean_acc, std_acc = None, None
    # -------------------------------------------------------------

    # Trains the model on the full training set
    logger.info("Training model on full training set...")
    model.fit(X_train, y_train)

    # Final evaluation on holdout test set
    logger.info("Evaluating model...")
    preds = model.predict(X_test)
    acc = accuracy_score(y_test, preds)  # compares predictions vs actual labels
    logger.info("Test accuracy: %.4f", acc)

    # Save model + metrics
    artifact = {
        "pipeline": model.pipeline,
        "target_names": list(sorted(set(y_train))),
        "metrics": {
            "accuracy": float(acc),
            "cv_mean": float(mean_acc) if mean_acc is not None else None,
            "cv_std": float(std_acc) if std_acc is not None else None,
        },
    }

    logger.info("Saving model to %s", MODEL_PATH)
    try:
        joblib.dump(artifact, MODEL_PATH)
    except Exception as exc:
        logger.exception("Failed to save model artifact: %s", exc)
        sys.exit(3)

    # Alert if below acceptance threshold
    if acc < ACCURACY_THRESHOLD:
        logger.warning(
            "Model accuracy (%.4f) below threshold %.2f. You may want to adjust hyperparameters or check data.",
            acc,
            ACCURACY_THRESHOLD,
        )

    training_time = time() - start
    logger.info("Training finished in %.2fs", training_time)

    # -------------------------------------------------------------
    # CLEAR SUMMARY OUTPUT
    # -------------------------------------------------------------
    print("\n" + "=" * 50)
    print("TRAINING SUMMARY")
    print("=" * 50)
    if mean_acc is not None and std_acc is not None:
        print(f"CV accuracy: {mean_acc:.4f} ± {std_acc:.4f}")
    print(f"Test accuracy: {acc:.4f}")
    print(f"Training time: {training_time:.2f}s")
    print("=" * 50)

    # exit 0 indicates success even if below threshold; CI can assert metric if desired.
    return 0


if __name__ == "__main__":
    sys.exit(main())

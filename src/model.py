# src/model.py
from typing import Any

from sklearn.linear_model import LogisticRegression
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import StandardScaler


class SoftmaxClassifier:
    """
    Wrapper around a scikit-learn pipeline implementing softmax (multinomial logistic regression).
    Provides fit/predict API.
    """

    def __init__(self, C: float = 1.0, max_iter: int = 200, random_state: int = 42):
        self.pipeline: Pipeline = Pipeline(
            [
                ("scaler", StandardScaler()),
                (
                    "clf",
                    LogisticRegression(
                        C=C,
                        max_iter=max_iter,
                        solver="lbfgs",
                        # multi_class="multinomial",  <------ deprecated!!!
                        random_state=random_state,
                    ),
                ),
            ]
        )

    def fit(self, X, y) -> "SoftmaxClassifier":
        self.pipeline.fit(X, y)
        return self

    def predict(self, X) -> Any:
        return self.pipeline.predict(X)

    def predict_proba(self, X) -> Any:
        return self.pipeline.predict_proba(X)

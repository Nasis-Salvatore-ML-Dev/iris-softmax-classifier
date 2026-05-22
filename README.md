# Iris Softmax Classifier — End-to-End MLOps Pipeline

A complete MLOps system built around a multinomial logistic regression (Softmax)
classifier on the Iris dataset. The model itself is intentionally simple — the
focus is the production infrastructure surrounding it: automated testing, CI/CD,
containerised deployment, and operational monitoring.

Built as a first end-to-end MLOps project before the BMW, aerospace, and fraud
detection pipelines.

---

## Model Performance

| Metric           | Value  |
| ---------------- | ------ |
| CV accuracy      | 0.9667 |
| Test accuracy    | 1.0000 |
| Best C           | 10     |
| Best max_iter    | 100    |
| Best tol         | 0.0001 |
| Training time    | 7.07s  |

> Test accuracy of 1.0000 reflects the Iris dataset's separability at optimised
> hyperparameters — not a generalisation claim. CV accuracy (0.9667) is the
> honest performance indicator.

---

## Architecture

```
GitHub push
  └── CI (GitHub Actions)
        ├── flake8 lint
        ├── isort + black format check
        ├── mypy type check
        └── pytest (unit + integration + API tests)
              └── merge to main → CD
                    ├── docker build
                    ├── push to Google Artifact Registry
                    └── deploy to Cloud Run
```

**Runtime:**
```
Client → Cloud Run (FastAPI)
           └── POST /predict → SoftmaxClassifier pipeline → species label
```

---

## Core Capabilities

**Reproducible environment**
```bash
make install    # Conda environment + dependencies
```

**Code quality**
```bash
make lint          # flake8
make type-check    # mypy
make test          # pytest unit + integration + API
make test-coverage # pytest with coverage report
```

**Training and tuning**
```bash
make train              # baseline model → artifacts/model.pkl
make tune               # GridSearchCV → artifacts/tuned_model.pkl
make test-tuned-model   # evaluate tuned model
```

**Deployment**
```bash
make deploy    # Docker build → Artifact Registry → Cloud Run
```

**Local API**
```bash
make run-app        # start FastAPI server
make test-prediction # send a test prediction
```

---

## Project Structure

```
iris-softmax-classifier/
├── .github/workflows/main.yml   # CI/CD pipeline
├── app/
│   └── main.py                  # FastAPI application
├── artifacts/
│   ├── model.pkl                # Baseline trained model
│   └── tuned_model.pkl          # GridSearchCV-tuned model
├── data/
│   └── iris.csv
├── docs/
│   ├── deployment_and_operations_guide.md
│   ├── ProcessMap.md
│   └── runbook.md
├── scripts/
│   ├── ci_cd.sh
│   ├── deploy.sh
│   └── monitor_health.sh
├── src/
│   ├── config.py                # Paths and YAML config loading
│   ├── data_processing.py       # Load + train/test split
│   ├── model.py                 # SoftmaxClassifier (sklearn Pipeline wrapper)
│   ├── train.py                 # Training script with CV and artifact export
│   ├── tune.py                  # GridSearchCV tuning script
│   └── predict.py               # Inference utilities
└── tests/
    ├── test_api.py
    ├── test_data_processing.py
    ├── test_model.py
    ├── test_predictions.py
    └── test_train_integration.py
```

---

## Monitoring

Operational metrics tracked via `scripts/monitor_health.sh`:

- Latency (P50 / P95 / P99)
- Error rates (4xx / 5xx)
- CPU and memory usage
- Request volume
- Cold-start performance
- Instance count and autoscaling behaviour

---

## Engineering Decisions

**Why Iris and Softmax?** The dataset and model are deliberately simple — the
goal was to build and validate the full MLOps stack (testing, CI/CD, containers,
cloud deployment, monitoring) without model complexity getting in the way. The
same infrastructure patterns scale directly to the subsequent BMW, aerospace, and
fraud detection projects.

**Why Cloud Run over Lambda?** This project predates the AWS Lambda work. Cloud
Run on GCP was the natural choice given the GCP stack used throughout the
portfolio.

---

## Context

First production MLOps project in the portfolio. Patterns established here —
CI/CD with quality gates, containerised deployment, artifact management, API
serving — were carried forward and extended in all subsequent projects.

# **Iris Softmax Classifier — End-to-End MLOps Pipeline**

This repository contains a complete, production-ready machine learning system for classifying Iris flowers using a multinomial logistic regression (Softmax classifier).
Beyond model training, the project implements a modern MLOps workflow inspired by practices used in large engineering organizations, including automated testing, CI/CD pipelines, containerized deployment, and service monitoring.

The objective was to design a system that moves reliably from experimentation to production, while maintaining reproducibility, test coverage, and operational visibility.

---

## **Project Summary**

The core model is a Softmax classifier trained on the Iris dataset.
Initial performance reached ~93% accuracy. After systematic hyperparameter tuning using GridSearchCV, the optimized model achieved the following:

```
Best CV accuracy: 0.9667
Test accuracy:    1.0000
Best parameters:   {'clf__C': 10, 'clf__max_iter': 100, 'clf__tol': 0.0001}
Training time:     7.07s
```

The trained models (`model.pkl`, `tuned_model.pkl`) are stored in the `artifacts/` directory and can be loaded for inference.

A FastAPI service exposes a prediction endpoint:

```
POST /predict
```

The system is fully containerized with Docker and deployed to Google Cloud Run through an automated CI/CD pipeline.

---

## **Repository Structure**

```
iris-softmax-classifier
├── .github
│   └── workflows
│       └── main.yml
├── .pytest_cache
├── .venv
├── app
│   ├── __init__.py
│   ├── init.py
│   └── main.py
├── artifacts
│   ├── model.pkl
│   └── tuned_model.pkl
├── data
│   └── iris.csv
├── docs
│   ├── deployment_and_operations_guide.md
│   ├── ProcessMap.md
│   └── runbook.md
├── htmlcov
│   └── (coverage reports)
├── images
│   ├── features_histogram.png
│   └── pairplot_iris.png
├── notebooks
│   └── exploratory_data_analysis.ipynb
├── scripts
│   ├── ci_cd.sh
│   ├── deploy.sh
│   ├── featurestore_setup.sh
│   ├── fetch_data.sh
│   ├── fix_linting.sh
│   └── monitor_health.sh
├── src
│   ├── __init__.py
│   ├── config.py
│   ├── config.yaml
│   ├── data_processing.py
│   ├── init.py
│   ├── model.py
│   ├── predict.py
│   ├── train.py
│   └── tune.py
├── tests
│   ├── test_api.py
│   ├── test_data_processing.py
│   ├── test_model.py
│   ├── test_predictions.py
│   └── test_train_integration.py
├── tf_env_clean
├── .coverage
├── .dockerignore
├── .gitignore
├── Dockerfile
├── Makefile
├── project_structure.txt
├── README.md
└── requirements.txt
```

---

## **Core Capabilities**

### **1. Reproducible Environment**

The project uses a Conda-based environment:

```
make install
```

This creates a dedicated environment and installs all dependencies, ensuring repeatable experiments and deployments.

---

### **2. Code Quality and Testing**

Quality gates include:

- **flake8** for linting
- **isort** and **black** for formatting
- **mypy** for static type checking
- **pytest** with coverage reports

Commands:

```
make lint
make type-check
make test
make test-coverage
```

The testing suite covers data preprocessing, model training, prediction correctness, API behavior, and integration with artifacts.

---

### **3. Model Training and Tuning**

Baseline training:

```
make train
```

Hyperparameter tuning with GridSearchCV:

```
make tune
make test-tuned-model
```

This tuning process produced a model achieving **100% test accuracy** while maintaining strong cross-validation robustness.

---

### **4. Deployment**

The FastAPI application in `app/main.py` is containerized via Docker and deployed to Google Cloud Run.

Deployment command:

```
make deploy
```

The deployment uses:

- Google Artifact Registry
- Cloud Run autoscaling
- Fully managed HTTPS endpoint

---

### **5. Monitoring**

Operational monitoring includes:

- Latency (P50 / P95 / P99)
- Error rates (4xx / 5xx)
- CPU and memory
- Request volume
- Cold-start performance
- Instance count and autoscaling behavior

A monitoring script is included:

```
scripts/monitor_health.sh
```

---

### **6. CI/CD Pipeline**

The workflow in:

```
.github/workflows/main.yml
```

implements:

1. Linting
2. Testing
3. Docker image build
4. Push to Artifact Registry
5. Deployment to Cloud Run

Every push to the `main` branch automatically updates the production service.

This mirrors the deployment processes used in modern ML engineering teams.

---

## **Running the System Locally**

Start the API:

```
make run-app
```

Send a test prediction:

```
make test-prediction
```

---

## **Training Models Locally**

Basic training:

```
make train
```

Tuning:

```
make tune
```

Check the tuned model’s output:

```
make test-tuned-model
```

                        ┌────────────────────────────┐
                        │        START / SETUP       │
                        │  (local machine or CI)     │
                        └──────────────┬─────────────┘
                                       │
                                       ▼
                           ┌────────────────────┐
                           │   Environment setup │
                           │   (.venv, Makefile) │
                           └────────────────────┘
                                       │
                                       ▼
                           ┌────────────────────┐
                           │  Install dependencies│
                           │ (requirements.txt)   │
                           └────────────────────┘
                                       │
                                       ▼
                           ┌────────────────────┐
                           │  Fetch / Prepare data│
                           │ (scripts/fetch_data.sh│
                           │  → data/iris.csv)     │
                           └────────────────────┘
                                       │
                                       ▼
                    ┌─────────────────────────────────────┐
                    │ Data preprocessing and model config │
                    │ src/config.py / src/config.yaml     │
                    │ src/data_processing.py              │
                    └─────────────────────────────────────┘
                                       │
                                       ▼
                        ┌────────────────────────────┐
                        │     Train the model        │
                        │   src/train.py (local)     │
                        │   or Vertex custom job     │
                        └────────────────────────────┘
                                       │
                        ┌──────────────┼──────────────┐
                        │                              │
                        ▼                              ▼
          ┌───────────────────────────┐      ┌────────────────────────────┐
          │ Local Training (dev env)  │      │ Vertex AI Training (prod)  │
          │ - make train              │      │ - scripts/vertex_train.sh  │
          │ - artifacts/model.pkl     │      │ - Trains in container env  │
          │ - Metrics printed locally │      │ - Saves to GCS bucket      │
          └──────────────┬────────────┘      └──────────────┬─────────────┘
                         │                                 │
                         ▼                                 ▼
         ┌───────────────────────────┐     ┌──────────────────────────────┐
         │ Evaluate accuracy metrics │     │ Vertex Vizier optimization   │
         │ - Accuracy > 95%?         │     │ - scripts/vertex_vizier.sh   │
         │ - Logs metrics            │     │ - Tunes hyperparameters      │
         └──────────────┬────────────┘     └──────────────────────────────┘
                         │
                         ▼
                ┌────────────────────────────┐
                │ Serialize trained model    │
                │ → artifacts/model.pkl      │
                │ (saved locally or GCS)     │
                └────────────────────────────┘
                         │
                         ▼
              ┌──────────────────────────┐
              │ Build & Containerize App │
              │ - Dockerfile             │
              │ - .dockerignore excludes │
              │   large/unneeded files   │
              └──────────────────────────┘
                         │
                         ▼
             ┌────────────────────────────────┐
             │ Local test via FastAPI         │
             │ - app/main.py                  │
             │ - uvicorn app.main:app         │
             │ - test with curl               │
             │   → localhost:8080/predict     │
             └────────────────────────────────┘
                         │
                         ▼
       ┌────────────────────────────────────────────────────┐
       │ Deploy to Cloud Run (Continuous Delivery pipeline) │
       │ - scripts/deploy.sh                                │
       │   1. Sets project vars (PROJECT_ID, REGION, etc.)  │
       │   2. Builds container via Cloud Build              │
       │   3. Pushes image to Artifact Registry             │
       │   4. Deploys Cloud Run service                     │
       │   5. Outputs SERVICE_URL                           │
       └────────────────────────────────────────────────────┘
                         │
                         ▼
          ┌─────────────────────────────────────┐
          │ Cloud Run serving stage (Production) │
          │ - Loads model.pkl from container     │
          │ - Exposes /predict API endpoint      │
          │ - Exposes /health endpoint           │
          │ - Accessible via HTTPS URL           │
          └─────────────────────────────────────┘
                         │
                         ▼
       ┌──────────────────────────────────────────┐
       │ Test predictions (real-time inference)   │
       │ curl -X POST $SERVICE_URL/predict        │
       │ → returns JSON { "species": "setosa" }   │
       └──────────────────────────────────────────┘
                         │
                         ▼
       ┌──────────────────────────────────────────┐
       │ Continuous Integration (GitHub Actions)  │
       │ - .github/workflows/main.yml             │
       │   1. Lint (flake8)                       │
       │   2. Test (pytest)                       │
       │   3. Build image & push to GCR           │
       │   4. Deploy to Cloud Run (dev/prod)      │
       └──────────────────────────────────────────┘
                         │
                         ▼
        ┌────────────────────────────────────────┐
        │ Monitoring & Runbook Operations        │
        │ - Check latency, error rate in Cloud   │
        │   Monitoring                           │
        │ - If accuracy < 95%, retrain           │
        │ - Rollback via previous image tag      │
        │ - Follow docs/runbook.md               │
        └────────────────────────────────────────┘
                         │
                         ▼
        ┌──────────────────────────────────────────┐
        │ Optional MLOps Enhancements              │
        │ - Vertex Feature Store (avoid skew)      │
        │ - MLflow experiment tracking             │
        │ - Canary deployments / rollback safety   │
        │ - Monitoring dashboards & alerts         │
        └──────────────────────────────────────────┘
                         │
                         ▼
                    ┌──────────────┐
                    │     END      │
                    │ (Healthy CD) │
                    └──────────────┘

| Domain                  | Responsibility                     | Key Artifacts                                  |
| ----------------------- | ---------------------------------- | ---------------------------------------------- |
| **Data & Training**     | Data prep → model train → artifact | `data_processing.py`, `train.py`, `model.pkl`  |
| **Experimentation**     | Track metrics / EDA                | `notebooks/`, `EDA.ipynb`, `MLflow` (optional) |
| **Packaging & Serving** | Serve model via REST               | `app/main.py`, `Dockerfile`                    |
| **CI/CD**               | Automate testing & deploy          | `.github/workflows/main.yml`, `deploy.sh`      |
| **Cloud Ops (Vertex)**  | Managed training, HPO              | `vertex_train.sh`, `vertex_vizier.sh`          |
| **Monitoring**          | Check model & API health           | `runbook.md`, Cloud Monitoring dashboards      |

| Symbol / Item                | Represents                                                     |
| ---------------------------- | -------------------------------------------------------------- |
| `scripts/*.sh`               | Automation entry points (deploy, Vertex AI ops, feature store) |
| `src/*.py`                   | Core ML logic — data, model, train, predict                    |
| `app/main.py`                | FastAPI serving entrypoint                                     |
| `.github/workflows/main.yml` | CI/CD automation                                               |
| `artifacts/`                 | Model outputs (model.pkl, metrics)                             |
| `data/`                      | Local raw data (iris.csv)                                      |
| `Dockerfile`                 | Container image definition                                     |
| `Makefile`                   | Developer shortcuts for training, testing, linting, running    |
| `docs/runbook.md`            | On-call guide & acceptance criteria                            |
| `Vertex AI scripts`          | Integration with GCP-managed ML training & tuning              |
| `Cloud Run`                  | Model deployment endpoint                                      |
| `GitHub Actions`             | Continuous integration & deployment automation                 |

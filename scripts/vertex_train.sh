#!/usr/bin/env bash
#
# scripts/vertex_train.sh
#
# Submits a Vertex AI custom training job that:
#  1. Builds the service image (already built by CI usually).
#  2. Starts a custom job which runs the container and:
#     - copies data from GCS to the container
#     - runs `python -m src.train` (training code must save artifact to artifacts/model.pkl)
#     - copies artifacts back to GCS
#
# Requirements / Environment variables (set before running):
#  - PROJECT_ID    : GCP project id
#  - REGION        : Vertex AI region (e.g., us-central1)
#  - GCS_BUCKET    : GCS bucket where iris.csv is stored and where model artifacts are written
#  - IMAGE_URI     : Container image URI available in Artifact Registry
#
# Example:
#   export PROJECT_ID="my-project"
#   export REGION="us-central1"
#   export GCS_BUCKET="my-bucket"
#   export IMAGE_URI="us-central1-docker.pkg.dev/PROJECT/iris-repo/iris-softmax:sha"
#   ./scripts/vertex_train.sh
#

set -euo pipefail

# --- Configuration (exported from CI or set manually) ---
PROJECT_ID="${PROJECT_ID:-}"
REGION="${REGION:-us-central1}"
GCS_BUCKET="${GCS_BUCKET:-}"
IMAGE_URI="${IMAGE_URI:-}"

if [[ -z "$PROJECT_ID" || -z "$GCS_BUCKET" || -z "$IMAGE_URI" ]]; then
  echo "ERROR: Please set PROJECT_ID, REGION (optional), GCS_BUCKET, and IMAGE_URI environment variables."
  echo "Example: PROJECT_ID=... REGION=us-central1 GCS_BUCKET=... IMAGE_URI=... ./scripts/vertex_train.sh"
  exit 2
fi

JOB_DISPLAY_NAME="iris-custom-train-$(date +%s)"
TRAIN_DATA_GCS="gs://${GCS_BUCKET}/data/iris.csv"
MODEL_DEST_GCS="gs://${GCS_BUCKET}/models/iris-$(date +%s).pkl"
# You can change worker pool specs below if you need GPUs etc.
WORKER_POOL_SPEC_FILE="/tmp/iris_worker_pool_spec.json"

cat > "${WORKER_POOL_SPEC_FILE}" << EOF
[
  {
    "machineSpec": {
      "machineType": "n1-standard-2"
    },
    "replicaCount": "1",
    "containerSpec": {
      "imageUri": "${IMAGE_URI}",
      "commands": [
        "/bin/bash",
        "-c",
        "echo 'Starting training container'; \
         mkdir -p /workspace/data /workspace/artifacts; \
         echo 'Downloading data from ${TRAIN_DATA_GCS}'; \
         gsutil cp ${TRAIN_DATA_GCS} /workspace/data/iris.csv; \
         ls -la /workspace; \
         python -m src.train || (echo 'train script failed' && exit 3); \
         if [ -f artifacts/model.pkl ]; then \
           echo 'Uploading model artifact to ${MODEL_DEST_GCS}'; \
           gsutil cp artifacts/model.pkl ${MODEL_DEST_GCS}; \
         else \
           echo 'Model artifact not found: artifacts/model.pkl'; exit 4; \
         fi; \
         echo 'Training container finished.'"
      ]
    }
  }
]
EOF

echo "Submitting Vertex AI Custom Job: ${JOB_DISPLAY_NAME}"
gcloud ai custom-jobs create \
  --region="${REGION}" \
  --display-name="${JOB_DISPLAY_NAME}" \
  --project="${PROJECT_ID}" \
  --worker-pool-spec-file="${WORKER_POOL_SPEC_FILE}"

echo "Custom training submitted. Model will be uploaded to ${MODEL_DEST_GCS} if successful."

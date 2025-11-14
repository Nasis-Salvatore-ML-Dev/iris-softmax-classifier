#!/usr/bin/env bash
#
# scripts/vertex_vizier.sh
#
# Create a Vertex AI Hyperparameter tuning job (HyperparameterTuningJob) that will
# run multiple trials using your custom container image. Each trial runs a small
# training job (same container) with different hyperparameters.
#
# Required environment variables:
#  - PROJECT_ID, REGION, GCS_BUCKET, IMAGE_URI (see vertex_train.sh)
#
# This script uses gcloud's `ai hp-tuning-jobs create` command (gcloud alpha/beta).
# Adapt ranges and hyperparameters as needed.
#
set -euo pipefail

PROJECT_ID="${PROJECT_ID:-}"
REGION="${REGION:-us-central1}"
GCS_BUCKET="${GCS_BUCKET:-}"
IMAGE_URI="${IMAGE_URI:-}"

if [[ -z "$PROJECT_ID" || -z "$GCS_BUCKET" || -z "$IMAGE_URI" ]]; then
  echo "ERROR: Set PROJECT_ID, REGION, GCS_BUCKET, IMAGE_URI before running."
  exit 2
fi

JOB_DISPLAY_NAME="iris-hp-tuning-$(date +%s)"
TRAIN_DATA_GCS="gs://${GCS_BUCKET}/data/iris.csv"
MODEL_OUTPUT_DIR="gs://${GCS_BUCKET}/models/hp-tuning-$(date +%s)/"

# Here we create a YAML spec for the hp tuning job. Adjust metric and hyperparams accordingly.
HP_TUNING_SPEC_FILE="/tmp/iris_hp_tuning.yaml"

cat > "${HP_TUNING_SPEC_FILE}" << EOF
displayName: "${JOB_DISPLAY_NAME}"
trialJobSpec:
  workerPoolSpecs:
    - machineSpec:
        machineType: "n1-standard-2"
      replicaCount: "1"
      containerSpec:
        imageUri: "${IMAGE_URI}"
        command:
          - "/bin/bash"
          - "-c"
        args:
          - |
            set -e
            mkdir -p /workspace/data /workspace/artifacts
            gsutil cp ${TRAIN_DATA_GCS} /workspace/data/iris.csv
            # The script below expects hyperparameters via environment variables set by Vizier.
            echo "TRAINING WITH HPs: C=\$HP_C, MAX_ITER=\$HP_MAXITER"
            python -m src.train || (echo "Train failed" && exit 3)
            # Upload artifact
            if [ -f artifacts/model.pkl ]; then
              gsutil cp artifacts/model.pkl ${MODEL_OUTPUT_DIR}\${TRIAL_ID}.pkl
            fi
parameterSpec:
  - parameterId: "HP_C"
    doubleValueSpec:
      minValue: 0.001
      maxValue: 10.0
    scaleType: "UNIT_LOG_SCALE"
  - parameterId: "HP_MAXITER"
    integerValueSpec:
      minValue: 100
      maxValue: 1000
maxTrialCount: 8
parallelTrialCount: 2
studySpec:
  metric:
    metricId: "validation_accuracy"
    goal: "MAXIMIZE"
EOF

echo "Creating Hyperparameter Tuning Job on Vertex AI..."
gcloud ai hp-tuning-jobs create \
  --region=${REGION} \
  --project=${PROJECT_ID} \
  --config=${HP_TUNING_SPEC_FILE}

echo "Hyperparameter tuning job created (displayName=${JOB_DISPLAY_NAME}). Monitor in the Vertex AI console."

#!/usr/bin/env bash
#
# scripts/featurestore_setup.sh
#
# Set up a Vertex AI Feature Store, create an entity type, and ingest the Iris CSV
# from GCS. This is a demo sequence to show how you can centralize features and
# avoid training-serving skew.
#
# Required environment variables:
#  - PROJECT_ID, REGION, GCS_BUCKET
#
# Usage:
#  PROJECT_ID=... REGION=us-central1 GCS_BUCKET=... ./scripts/featurestore_setup.sh
#
set -euo pipefail

PROJECT_ID="${PROJECT_ID:-}"
REGION="${REGION:-us-central1}"
GCS_BUCKET="${GCS_BUCKET:-}"

if [[ -z "$PROJECT_ID" || -z "$GCS_BUCKET" ]]; then
  echo "ERROR: Set PROJECT_ID and GCS_BUCKET before running."
  exit 2
fi

FEATURESTORE_ID="iris_featurestore"
ENTITY_TYPE="iris_entity_type"
IMPORT_FILE="gs://${GCS_BUCKET}/data/iris_for_fs.csv"  # You must prepare this CSV for ingestion.

echo "Creating Feature Store: ${FEATURESTORE_ID} (if not exists)..."
if gcloud ai featurestores describe ${FEATURESTORE_ID} --location=${REGION} --project=${PROJECT_ID} >/dev/null 2>&1; then
  echo "Featurestore already exists."
else
  gcloud ai featurestores create ${FEATURESTORE_ID} \
    --location=${REGION} \
    --project=${PROJECT_ID}
  echo "Created featurestore: ${FEATURESTORE_ID}"
fi

echo "Creating entity type: ${ENTITY_TYPE}..."
if gcloud ai featurestores entity-types describe ${ENTITY_TYPE} --featurestore=${FEATURESTORE_ID} --location=${REGION} --project=${PROJECT_ID} >/dev/null 2>&1; then
  echo "Entity type already exists."
else
  gcloud ai featurestores entity-types create ${ENTITY_TYPE} \
    --featurestore=${FEATURESTORE_ID} \
    --location=${REGION} \
    --project=${PROJECT_ID}
  echo "Created entity type."
fi

echo ""
echo "NEXT STEP (manual): Prepare CSV for import with a schema matching Feature Store requirements."
echo "Example CSV columns: entity_id, sepal_length, sepal_width, petal_length, petal_width, event_timestamp"
echo "Upload CSV to GCS at: ${IMPORT_FILE}"
echo ""
echo "To import features once the CSV is ready, run (example):"
echo "gcloud ai featurestores entity-types import feature-values \\"
echo "  --featurestore=${FEATURESTORE_ID} \\"
echo "  --entity-type=${ENTITY_TYPE} \\"
echo "  --dataset-file=${IMPORT_FILE} \\"
echo "  --location=${REGION} \\"
echo "  --project=${PROJECT_ID}"
echo ""
echo "After importing, you can read features via the Vertex AI Feature Store API in your serving code to avoid training-serving skew."

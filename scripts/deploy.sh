#!/bin/bash

################################################################################
# Iris Classifier Deployment Script (GCP)
#
# This script automates the deployment of the Iris classifier service
# to Google Cloud Run using Cloud Build and Artifact Registry.
#
# It includes:
#  - Project setup and API enablement
#  - Docker image build and push
#  - Cloud Run deployment
#  - URL retrieval and summary
#
# Prerequisites:
#  - gcloud CLI installed and authenticated
#  - IAM permissions for Cloud Run, Cloud Build, and Artifact Registry
#  - Dockerfile present in the project root
################################################################################

set -e  # Exit immediately if a command exits with a non-zero status.

# --------------------------- CONFIGURATION ------------------------------------
PROJECT_ID="erasmus-472716"
REGION="us-central1"
REPO="iris-repo"

ENV="dev"
SERVICE_NAME="iris-softmax-service-${ENV}"
GCS_BUCKET="iris-bucket-${ENV}"    # Example: separate bucket per environment
IMAGE="us-central1-docker.pkg.dev/${PROJECT_ID}/${REPO}/iris-softmax:${ENV}-latest"


RUN_VERTEX="${RUN_VERTEX:-0}" # set to 1 to run vertex training & vizier

################################################################################

# ----------------------------- COLORS -----------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
################################################################################

echo -e "${BLUE}======================================"
echo " Iris Classifier Deployment Script"
echo "======================================${NC}"
echo "Project ID: ${PROJECT_ID}"
echo "Region: ${REGION}"
echo "Repository: ${REPO}"
echo "Service: ${SERVICE_NAME}"
echo ""

# -------------------------- CONFIRMATION PROMPT -------------------------------
read -p "Proceed with deployment to Cloud Run? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Deployment cancelled.${NC}"
    exit 1
fi

# -------------------------- PROJECT SETUP -------------------------------------
echo -e "\n${BLUE}Setting active project...${NC}"
gcloud config set project ${PROJECT_ID}

echo -e "\n${BLUE}Enabling required APIs...${NC}"
gcloud services enable \
    run.googleapis.com \
    cloudbuild.googleapis.com \
    artifactregistry.googleapis.com \
    aiplatform.googleapis.com \
    storage.googleapis.com \
    --project=${PROJECT_ID}
echo -e "${GREEN}✓ Required APIs enabled${NC}"

# ----------------------- ARTIFACT REGISTRY SETUP ------------------------------
echo -e "\n${BLUE}Checking Artifact Registry...${NC}"
if gcloud artifacts repositories describe ${REPO} --location=${REGION} --project=${PROJECT_ID} >/dev/null 2>&1; then
    echo -e "${GREEN}✓ Repository exists: ${REPO}${NC}"
else
    echo -e "${YELLOW}Creating repository: ${REPO}${NC}"
    gcloud artifacts repositories create ${REPO} \
      --repository-format=docker \
      --location=${REGION} \
      --description="Docker repo for Iris classifier images" \
      --project=${PROJECT_ID}
    echo -e "${GREEN}✓ Repository created${NC}"
fi

# --------------------------- BUILD & PUSH -------------------------------------
echo -e "\n${BLUE}Building Docker image...${NC}"
gcloud builds submit \
  --tag ${IMAGE} \
  --timeout=10m \
  --project=${PROJECT_ID}

echo -e "${GREEN}✓ Docker image built and pushed: ${IMAGE}${NC}"

# ----------------------------- DEPLOY -----------------------------------------
echo -e "\n${BLUE}Deploying to Cloud Run...${NC}"
gcloud run deploy ${SERVICE_NAME} \
  --image ${IMAGE} \
  --region ${REGION} \
  --platform managed \
  --allow-unauthenticated \
  --memory 1Gi \
  --cpu 1 \
  --timeout 300 \
  --max-instances 5 \
  --set-env-vars PROJECT_ID=${PROJECT_ID},REGION=${REGION} \
  --project=${PROJECT_ID}

SERVICE_URL=$(gcloud run services describe ${SERVICE_NAME} \
  --region ${REGION} \
  --platform managed \
  --format='value(status.url)' \
  --project=${PROJECT_ID})

echo -e "${GREEN}✓ Service deployed successfully${NC}"
echo -e "Service URL: ${BLUE}${SERVICE_URL}${NC}"

# ----------------------------- TEST SUMMARY -----------------------------------
echo -e "\n${GREEN}======================================"
echo " Deployment Summary"
echo "======================================${NC}"
echo -e "Project ID:       ${PROJECT_ID}"
echo -e "Region:           ${REGION}"
echo -e "Service Name:     ${SERVICE_NAME}"
echo -e "Artifact Repo:    ${REPO}"
echo -e "Image:            ${IMAGE}"
echo -e "Service URL:      ${GREEN}${SERVICE_URL}${NC}"
echo ""
echo -e "${BLUE}Test your service with:${NC}"
echo "curl -X POST \"${SERVICE_URL}/predict\" \\"
echo "  -H \"Content-Type: application/json\" \\"
echo "  -d '{\"sepal_length\":5.1, \"sepal_width\":3.5, \"petal_length\":1.4, \"petal_width\":0.2}'"
echo ""
echo -e "${YELLOW}Expected output:${NC}"
echo "{\"species\":\"setosa\"}"
echo ""
echo -e "${GREEN}✓ Deployment complete!${NC}"

# ----------------------------- SAVE DETAILS -----------------------------------
cat > deployment_info.txt << EOF
Project ID: ${PROJECT_ID}
Region: ${REGION}
Repository: ${REPO}
Service Name: ${SERVICE_NAME}
Image: ${IMAGE}
Service URL: ${SERVICE_URL}
EOF

echo -e "${GREEN}✓ Deployment details saved to deployment_info.txt${NC}"


# Optionally trigger Vertex training & Vizier
if [[ "${RUN_VERTEX}" == "1" ]]; then
  if [[ -z "${GCS_BUCKET}" ]]; then
    echo "ERROR: set GCS_BUCKET to run vertex steps"
    exit 2
  fi
  echo -e "${BLUE}Triggering Vertex AI custom training...${NC}"
  export PROJECT_ID REGION GCS_BUCKET IMAGE_URI="${IMAGE}"
  chmod +x scripts/vertex_train.sh
  ./scripts/vertex_train.sh

  echo -e "${BLUE}Triggering Vertex AI Vizier hyperparameter tuning...${NC}"
  chmod +x scripts/vertex_vizier.sh
  ./scripts/vertex_vizier.sh
fi

echo -e "${GREEN}Deployment complete. Service URL: ${SERVICE_URL}${NC}"
echo "${SERVICE_URL}" > deployment_url.txt
















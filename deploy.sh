#!/bin/bash
# Demo Pre-Deployment Infrastructure Script
# Usage: ./deploy.sh [project_id] [region]

set -e

PROJECT_ID=$1
REGION=$2

# If project ID is not provided as an argument, try reading from GCP_PROJECT environment variable
if [ -z "$PROJECT_ID" ]; then
  PROJECT_ID=$GCP_PROJECT
fi

# If still not found, try getting the active gcloud configured project
if [ -z "$PROJECT_ID" ]; then
  echo "No project ID provided as parameter or environment variable. Attempting to detect active gcloud project..."
  PROJECT_ID=$(gcloud config get-value project 2>/dev/null || true)
fi

if [ -z "$PROJECT_ID" ] || [ "$PROJECT_ID" = "(unset)" ]; then
  echo "❌ Error: Google Cloud Project ID is required."
  echo "Usage: ./deploy.sh <project_id> [region]"
  echo "Alternatively, set the GCP_PROJECT environment variable or run 'gcloud config set project <project_id>'."
  exit 1
fi

# Default region to us-central1 if not specified
if [ -z "$REGION" ]; then
  REGION="us-central1"
fi

echo "=================================================="
echo " 🚀 Pre-deploying .NET Modernization Infrastructure"
echo " Project ID : $PROJECT_ID"
echo " Region     : $REGION"
echo "=================================================="
echo ""

# 1. Ensure required APIs are enabled (non-destructively)
echo "Step 1: Enabling required Google Cloud APIs..."
gcloud services enable \
  serviceusage.googleapis.com \
  run.googleapis.com \
  sqladmin.googleapis.com \
  artifactregistry.googleapis.com \
  cloudresourcemanager.googleapis.com \
  cloudbuild.googleapis.com \
  iam.googleapis.com \
  --project="$PROJECT_ID"

# 2. Create Artifact Registry repository if it doesn't exist
REPO_NAME="contoso-university-repo"
echo ""
echo "Step 2: Configuring Artifact Registry Repository..."
if gcloud artifacts repositories describe "$REPO_NAME" --location="$REGION" --project="$PROJECT_ID" &>/dev/null; then
  echo "Repository '$REPO_NAME' already exists in region '$REGION'."
else
  echo "Creating Docker repository '$REPO_NAME' in '$REGION'..."
  gcloud artifacts repositories create "$REPO_NAME" \
    --repository-format=docker \
    --location="$REGION" \
    --description="Docker repository for Contoso University" \
    --project="$PROJECT_ID"
fi

# 3. Create Cloud SQL for PostgreSQL instance if it doesn't exist
INSTANCE_NAME="contoso-university-db"
DB_PASSWORD="ContosoPostgresPassword123" # A robust password for demo environment

echo ""
echo "Step 3: Configuring Cloud SQL for PostgreSQL Instance..."
echo "This might take a few minutes if the instance doesn't exist yet..."

if gcloud sql instances describe "$INSTANCE_NAME" --project="$PROJECT_ID" &>/dev/null; then
  echo "Cloud SQL Instance '$INSTANCE_NAME' already exists."
else
  echo "Creating Cloud SQL Instance '$INSTANCE_NAME' (v13, db-g1-small)..."
  # Creating a lightweight instance to keep setup fast and cost-effective
  gcloud sql instances create "$INSTANCE_NAME" \
    --database-version=POSTGRES_13 \
    --tier=db-g1-small \
    --region="$REGION" \
    --root-password="$DB_PASSWORD" \
    --project="$PROJECT_ID" \
    --async
  
  echo "Cloud SQL instance creation requested in background."
  echo "You can check progress via 'gcloud sql operations list --instance=$INSTANCE_NAME'"
  echo "Waiting for instance to be ready before creating database..."
  
  # Wait loop
  while true; do
    STATUS=$(gcloud sql instances describe "$INSTANCE_NAME" --project="$PROJECT_ID" --format="value(state)" 2>/dev/null || echo "UNKNOWN")
    echo "Current Status: $STATUS"
    if [ "$STATUS" = "RUNNABLE" ]; then
      break
    elif [ "$STATUS" = "FAILED" ] || [ "$STATUS" = "SUSPENDED" ]; then
      echo "❌ Cloud SQL instance creation failed or is suspended."
      exit 1
    fi
    sleep 15
  done
fi

# Create database if it doesn't exist
echo "Ensuring 'contosouniversity' database exists..."
if gcloud sql databases describe contosouniversity --instance="$INSTANCE_NAME" --project="$PROJECT_ID" &>/dev/null; then
  echo "Database 'contosouniversity' already exists on instance '$INSTANCE_NAME'."
else
  echo "Creating database 'contosouniversity' on instance '$INSTANCE_NAME'..."
  gcloud sql databases create contosouniversity --instance="$INSTANCE_NAME" --project="$PROJECT_ID"
fi

# 4. Bind Cloud SQL and Cloud Build permissions for default Compute service account
echo ""
echo "Step 4: Configuring Service Account IAM Bindings..."
PROJECT_NUMBER=$(gcloud projects describe "$PROJECT_ID" --format="value(projectNumber)")
COMPUTE_SA="${PROJECT_NUMBER}-compute@developer.gserviceaccount.com"

echo "Binding IAM roles for service account: $COMPUTE_SA"
ROLES=(
  "roles/cloudsql.client"
  "roles/storage.objectViewer"
  "roles/logging.logWriter"
  "roles/artifactregistry.reader"
  "roles/artifactregistry.writer"
)

for ROLE in "${ROLES[@]}"; do
  echo "Granting role: $ROLE..."
  gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:$COMPUTE_SA" \
    --role="$ROLE" \
    --project="$PROJECT_ID" \
    --quiet >/dev/null || echo "Could not bind role $ROLE (it might already be bound or permissions are insufficient)."
done

echo ""
echo "=================================================="
echo " 🎉 Pre-Deployment Infrastructure Successfully Configured!"
echo " DB Password: $DB_PASSWORD"
echo "=================================================="
echo ""

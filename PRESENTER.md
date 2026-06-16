# Presenter Cheat-Sheet & Quick Reference

This cheat-sheet provides all commands, paths, and configurations needed to deliver the .NET Modernization Demo smoothly.

---

## Pre-Demo Checklist

1. **GCP Project setup**: Ensure you have an active Google Cloud Project and you are logged into the gcloud CLI.
2. **Configure Active Project**:
   ```bash
   export PROJECT_ID="[YOUR_PROJECT_ID]"
   gcloud config set project $PROJECT_ID
   ```
3. **Pre-deploy Cloud Infrastructure**: Run the deploy script to spin up Cloud SQL and configure permissions ahead of time. This saves 10 minutes of waiting during the presentation!
   ```bash
   ./deploy.sh $PROJECT_ID us-central1
   ```

---

## Stage-by-Stage Guide

### Stage 1: Modernization
* **Reset Command**:
  ```bash
  ./reset.sh 1
  ```
* **Live Action**: Open and explain `.antigravity.md` and `.agents/skills/dotnet-modernizer/SKILL.md`. Run `agy` in `dotnet-migration-sample`:
  ```bash
  cd dotnet-migration-sample
  agy "modernize this .NET application to .NET 8, convert EF6 to EF Core, use PostgreSQL, and containerize"
  ```
* **Fallback Command**:
  ```bash
  cd ..
  ./reset.sh 1-backup
  ```
* **Local Verification**:
  ```bash
  cd dotnet-migration-sample
  docker compose up --build --detach
  # Wait 10 seconds for DB seeding
  curl -i http://localhost:8080/Student
  # Tear down
  docker compose down -v
  cd ..
  ```

---

### Stage 2: Deployment
* **Reset Command**:
  ```bash
  ./reset.sh 2
  ```
* **Live Action**: Explain how the image is built using Cloud Build and pushed to Artifact Registry, then deployed to Cloud Run using gcloud.
* **Build command**:
  ```bash
  cd dotnet-migration-sample
  gcloud builds submit --tag us-central1-docker.pkg.dev/$PROJECT_ID/contoso-university-repo/contoso-university:latest .
  ```
* **Deploy command**:
  ```bash
  export CONNECTION_NAME=$(gcloud sql instances describe contoso-university-db --format='value(connectionName)')
  gcloud run deploy contoso-university \
    --image=us-central1-docker.pkg.dev/$PROJECT_ID/contoso-university-repo/contoso-university:latest \
    --platform managed \
    --allow-unauthenticated \
    --add-cloudsql-instances=$CONNECTION_NAME \
    --region us-central1 \
    --set-env-vars "ConnectionStrings__SchoolContext=Host=/cloudsql/$CONNECTION_NAME;Database=contosouniversity;Username=postgres;Password=ContosoPostgresPassword123"
  ```
* **Fallback Command**:
  ```bash
  cd ..
  ./reset.sh 2-backup
  ```
  Open the deployed live URL printed in the output to demonstrate the final working web app.

---

## Troubleshooting & Tips

* **Docker Issues**: If a previous run didn't terminate properly, run:
  ```bash
  docker compose down -v
  docker ps -aq | xargs -r docker stop
  docker ps -aq | xargs -r docker rm
  ```
* **Cloud SQL Slowness**: Cloud SQL creation takes around 5-7 minutes. Make sure `deploy.sh` is completed successfully *before* starting the presentation.
* **GCP Credentials**: If gcloud commands fail with authorization errors, verify you are logged in:
  ```bash
  gcloud auth login
  gcloud auth application-default login
  ```

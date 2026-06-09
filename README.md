# .NET Modernization with Antigravity CLI

A live demo repository demonstrating how to modernize a monolithic legacy .NET Framework application to a containerized, Linux-ready, cloud-native .NET 8 application using **Antigravity CLI** and Google Cloud's **Migration Center**.

---

## Quick Start

1. **Clone the repository**:
   ```bash
   git clone https://github.com/ejmadkins/agy-modernisation-demo.git
   cd agy-modernisation-demo
   ```

2. **Pre-deploy Cloud Infrastructure**: (Run this 10 minutes *before* your presentation to avoid waiting on slow resource creation)
   ```bash
   gcloud auth login
   ./deploy.sh [YOUR_PROJECT_ID] us-central1
   ```

3. **Start the Demo**:
   ```bash
   ./reset.sh 1
   ```

---

## Technical Progression

The demo guides the audience through three progressive stages, mirroring the path of an actual modernization project:

| Stage | Branch | Live Action | backup Branch | Backup Purpose |
| :--- | :--- | :--- | :--- | :--- |
| **Stage 1: Assessment** | `stage-1-assessment` | Run `codmod` to analyze the legacy app. | `stage-1-backup` | Shows pre-generated HTML assessment report instantly. |
| **Stage 2: Modernization** | `stage-2-modernize` | Use `agy` with `.antigravity.md` and `dotnet-modernizer` skill to refactor the app. | `stage-2-backup` | Provides fully modernized C# code + `Dockerfile` + local `compose.yaml`. |
| **Stage 3: Deployment** | `stage-3-deploy` | Build with Cloud Build & deploy container to Cloud Run live. | `stage-3-backup` | Live working URL link + verified deployed configurations. |

---

## Presentation Resources

To help you deliver a flawless and highly engaging talk, we have provided two guides in the root directory:

*   **[TALK_TRACK.md](TALK_TRACK.md)**: A minute-by-minute speaking script containing narrative, files to show, and punchlines for each stage.
*   **[PRESENTER.md](PRESENTER.md)**: A quick cheat-sheet listing all exact commands to copy-paste during the presentation, plus troubleshooting tips.

---

## Resetting the Environment

To switch stages or reset to a clean state if something goes wrong, run `./reset.sh` with the desired stage name. This command cleanly terminates any running local containers, discards any uncommitted edits, and checks out the clean stage branch.

```bash
./reset.sh 1          # Start Stage 1 (Assessment)
./reset.sh 1-backup   # Load Stage 1 backup (Pre-generated report)
./reset.sh 2          # Start Stage 2 (Modernization)
./reset.sh 2-backup   # Load Stage 2 backup (Completed local .NET 8 codebase)
./reset.sh 3          # Start Stage 3 (Deployment)
./reset.sh 3-backup   # Load Stage 3 backup (Completed deployed state)
```

---

## Clean Up

When you are finished presenting, run the cleanup commands below to remove all deployed resources from your Google Cloud project:

```bash
# Delete Cloud Run service
gcloud run services delete contoso-university --platform managed --region=us-central1 --quiet

# Delete Artifact Registry repository
gcloud artifacts repositories delete contoso-university-repo --location=us-central1 --quiet

# Delete Cloud SQL PostgreSQL instance
gcloud sql instances delete contoso-university-db --quiet
```

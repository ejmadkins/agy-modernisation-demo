# .NET Modernization Demo - Talk Track & Script

**Target Duration**: 10-12 minutes.

---

## 1. Introduction (0:00 - 1:00)

**Presenter Action**: Open the terminal and point to a fresh terminal.

**Spoken Narrative**:
> "Modernizing legacy applications is one of the most common—and most painful—tasks facing enterprise developers. Today, we're taking a classic monolithic ASP.NET MVC application, **Contoso University**, which targets old .NET versions and Entity Framework 6 on SQL Server, and we're going to modernize it.
>
> We will upgrade it to **.NET 8 (Core)**, refactor the database layer to **PostgreSQL**, make it compliant with serverless container platforms, and deploy it live to **Google Cloud Run** in two streamlined stages: **Modernization** and **Deployment**.
>
> To do this, we'll be utilizing the power of Google's **Antigravity CLI**—a tool that does more than write simple code suggestions; it acts as an intelligent agent capable of architectural planning, containerization, and platform verification."

---

## 2. Stage 1: Modernization (1:00 - 5:30)

**Presenter Action**: Run `./reset.sh 1` to configure Stage 1.

```bash
./reset.sh 1
```

**Presenter Action**: Open `.antigravity.md` and `.agents/skills/dotnet-modernizer/SKILL.md`.

**Spoken Narrative**:
> "In Stage 1, we introduce the **Antigravity CLI**. But instead of giving a generic prompt and getting unstructured suggestions, we configure Antigravity using **Rules** and **Skills**.
>
> First, `.antigravity.md` defines our developer workflow: analyze the files, draft a comprehensive plan, refactor each class, generate docker configurations, compile, and run local verification.
>
> Second, we equip the agent with a specialist skill: `.agents/skills/dotnet-modernizer`. This skill acts as a packaging of senior-level engineering standards. It contains explicit guidelines for upgrading projects to .NET 8, refactoring SQL Server concurrency columns (RowVersion) into PostgreSQL `xmin` concurrency system columns, setting up DI registration, and configuring structured JSON logging."

**Presenter Action**: Run the modernization command (or explain that we can run it, and show what the agent does when running `agy`).

```bash
cd dotnet-migration-sample
agy "modernize this .NET application to .NET 8, convert EF6 to EF Core, use PostgreSQL, and containerize"
```

**Spoken Narrative**:
> "Antigravity begins by analyzing the project and compiling a step-by-step implementation plan. Because the modernization takes around 20 minutes to download NuGet packages, compile, and run, let's switch to our Stage 1 backup branch to inspect the fully modernized, working application."

**Presenter Action**: Run `./reset.sh 1-backup` and open `dotnet-migration-sample/ContosoUniversity/Program.cs` and `Dockerfile`.

```bash
./reset.sh 1-backup
```

**Spoken Narrative**:
> "Look at how cleanly this application has been refactored.
>
> 1. **Program.cs**: The old XML-based `Web.config` and obsolete `Startup.cs` registrations are merged into a modern .NET 8 Program.cs middleware pipeline.
> 2. **PostgreSQL Integration**: The `SchoolContext` data access layer uses `Npgsql.EntityFrameworkCore.PostgreSQL`.
> 3. **Logging**: Structured JSON logging is enabled using Kestrel logging format, which integrates natively with GCP Cloud Logging.
> 4. **Graceful Shutdown**: It catches SIGTERM and shuts down Kestrel cleanly.
> 5. **Local verification**: A fully optimized multi-stage Dockerfile and a healthchecked Docker Compose setup are created."

**Presenter Action**: Launch the modernized app locally via Docker Compose.

```bash
cd dotnet-migration-sample
docker compose up --build --detach
```

Wait a few seconds for the database to seed and Kestrel to start.

**Spoken Narrative**:
> "Let's check our local environment. Docker Compose has spun up a PostgreSQL 16 container, completed healthchecks, started the modernized .NET 8 app, and seeded the database with initial Student and Course records."

**Presenter Action**: Query the local application using `curl` to prove it works.

```bash
curl -i http://localhost:8080/Student
```

**Spoken Narrative**:
> "And there it is! A clean `200 OK` status, and our students list renders perfectly. We've taken a legacy framework app and converted it into a lightweight, containerized, PostgreSQL-powered service running locally.
> Now, let's put it on Google Cloud."

**Presenter Action**: Clean up Docker containers.

```bash
docker compose down -v
cd ..
```

---

## 3. Stage 2: Deployment (5:30 - 8:30)

**Presenter Action**: Run `./reset.sh 2` to switch to the deploy stage.

```bash
./reset.sh 2
```

**Spoken Narrative**:
> "Now that we have a verified modernized service, we are ready to deploy it to **Google Cloud Run**. To ensure that our live demo is lightning fast and does not stall on slow infrastructure tasks, we pre-deployed the cloud database and repository ahead of time using our idempotent `deploy.sh` script."

**Presenter Action**: Show the `deploy.sh` script (or point to it).
Explain how we can run the deployment via the agent or a single `gcloud` command:

```bash
cd dotnet-migration-sample
gcloud builds submit --tag us-central1-docker.pkg.dev/[PROJECT_ID]/contoso-university-repo/contoso-university:latest .
```

And then:

```bash
gcloud run deploy contoso-university \
    --image=us-central1-docker.pkg.dev/[PROJECT_ID]/contoso-university-repo/contoso-university:latest \
    --platform managed \
    --allow-unauthenticated \
    --add-cloudsql-instances=[CONNECTION_NAME] \
    --region us-central1 \
    --set-env-vars "ConnectionStrings__SchoolContext=Host=/cloudsql/[CONNECTION_NAME];Database=contosouniversity;Username=postgres;Password=ContosoPostgresPassword123"
```

**Spoken Narrative**:
> "Because the database, container registry, and service account IAM bindings are already set up, building the image on Cloud Build and deploying it to Cloud Run finishes in seconds.
>
> Let's transition to our completed Stage 2 backup branch to view the final, deployed live link."

**Presenter Action**: Run `./reset.sh 2-backup`.

```bash
./reset.sh 2-backup
```

**Spoken Narrative**:
> "Our application is now live on Google Cloud! We can navigate the home page, add students, assign courses, and manage departments. All of this is running on an autoscaling serverless Cloud Run instance, writing structured logs directly to Cloud Logging, and persisted in a managed Cloud SQL PostgreSQL database.
>
> We went from a legacy monolithic app stuck on older frameworks to a modern, secure, serverless cloud service—all powered by the intelligence and orchestration of Google's Antigravity CLI and Migration Center assessment tools."

---

## 4. Conclusion (8:30 - 9:30)

**Spoken Narrative**:
> "To summarize what we saw today:
>
> 1. **Standardize using Skills**: We used Antigravity CLI with specific skills to enforce enterprise architectural patterns, logging, and database changes automatically.
> 2. **Verify and Deploy**: We validated the modernized service locally with Docker Compose, and deployed it seamlessly to Google Cloud Run.
>
> This demonstrates the power of developer-agent collaboration. Antigravity doesn't just guess—it plans, follows standards, and deploys. Thank you!"

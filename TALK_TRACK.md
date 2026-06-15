# .NET Modernization Demo - Talk Track & Script

**Target Duration**: 10-12 minutes.

---

## 1. Introduction (0:00 - 1:00)

**Presenter Action**: Open the terminal and point to a fresh terminal.

**Spoken Narrative**:
> "Modernizing legacy applications is one of the most common—and most painful—tasks facing enterprise developers. Today, we're taking a classic monolithic ASP.NET MVC application, **Contoso University**, which targets old .NET versions and Entity Framework 6 on SQL Server, and we're going to modernize it.
>
> We will upgrade it to **.NET 8 (Core)**, refactor the database layer to **PostgreSQL**, make it compliant with serverless container platforms, and deploy it live to **Google Cloud Run** in three streamlined stages: **Assessment**, **Modernization**, and **Deployment**.
>
> To do this, we'll be utilizing the power of Google's **Antigravity CLI**—a tool that does more than write simple code suggestions; it acts as an intelligent agent capable of architectural planning, visual checking, and platform verification."

---

## 2. Stage 1: Assessment (1:00 - 3:30)

**Presenter Action**: Run `./reset.sh 1` in the terminal to initialize the environment.

```bash
./reset.sh 1
```

**Spoken Narrative**:
> "Before refactoring a single line of code, any senior cloud architect starts with an assessment. Google Cloud provides the **Migration Center App Modernization Assessment tool**, or `codmod` CLI, to analyze our codebase and give us an exact readiness report."

**Presenter Action**: Point out the un-modernized files in `dotnet-migration-sample/ContosoUniversity/ContosoUniversity.csproj` using your editor or cat command.
Explain that the Migration Center App Modernization Assessment tool (`codmod` CLI) was used to analyze our codebase and generate a comprehensive readiness report.

Show the command used to run the assessment for reference:

```bash
# codmod create full \
#   --codebase ./dotnet-migration-sample \
#   --output-path ./codmod-full-report-dotnet-mod.html \
#   --experiments=enable_pdf,enable_images \
#   --improve-fidelity \
#   --intent=MICROSOFT_MODERNIZATION \
#   --optional-sections "files,classes"
```

**Spoken Narrative**:
> "Running a full assessment analyzes class diagrams, dependencies, SQL configurations, and compatibility APIs. Since a full assessment is a deep-dive process, we've pre-run this assessment and committed the full interactive HTML report directly to our repository root. Let's open and inspect the results immediately."

**Presenter Action**: Open the pre-generated `./codmod-full-report-dotnet-mod.html` report in your web browser.

```bash
# (Optional) You can still load the Stage 1 backup state using:
./reset.sh 1-backup
```

**Spoken Narrative**:
> "Here is our modernization report. Looking at the results, we have some critical modernisation needs:
>
> 1. **Framework Update**: Target framework must be upgraded to .NET 8.0.
> 2. **ORM migration**: Replace Entity Framework 6 with Entity Framework Core (`Microsoft.EntityFrameworkCore`).
> 3. **Database engine conversion**: Refactor SQL Server-specific syntax and drivers to PostgreSQL (`Npgsql`).
> 4. **Cloud Run compliance**: Ensure the container binds to the proper `PORT` environment variable and writes structured JSON logs to standard output for Google Cloud Logging ingestion.
>
> Now that we have a clear, data-driven plan, let's let Antigravity do the heavy lifting."

---

## 3. Stage 2: Modernization (3:30 - 7:30)

**Presenter Action**: Run `./reset.sh 2` to configure Stage 2.

```bash
./reset.sh 2
```

**Presenter Action**: Open `.antigravity.md` and `.agents/skills/dotnet-modernizer/SKILL.md`.

**Spoken Narrative**:
> "In Stage 2, we introduce the **Antigravity CLI**. But instead of giving a generic prompt and getting unstructured suggestions, we configure Antigravity using **Rules** and **Skills**.
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
> "Antigravity begins by analyzing the project and compiling a step-by-step implementation plan. Because the modernization takes around 20 minutes to download NuGet packages, compile, and run, let's switch to our Stage 2 backup branch to inspect the fully modernized, working application."

**Presenter Action**: Run `./reset.sh 2-backup` and open `dotnet-migration-sample/ContosoUniversity/Program.cs` and `Dockerfile`.

```bash
./reset.sh 2-backup
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

## 4. Stage 3: Deployment (7:30 - 10:00)

**Presenter Action**: Run `./reset.sh 3` to switch to the deploy stage.

```bash
./reset.sh 3
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
> Let's transition to our completed Stage 3 backup branch to view the final, deployed live link."

**Presenter Action**: Run `./reset.sh 3-backup`.

```bash
./reset.sh 3-backup
```

**Spoken Narrative**:
> "Our application is now live on Google Cloud! We can navigate the home page, add students, assign courses, and manage departments. All of this is running on an autoscaling serverless Cloud Run instance, writing structured logs directly to Cloud Logging, and persisted in a managed Cloud SQL PostgreSQL database.
>
> We went from a legacy monolithic app stuck on older frameworks to a modern, secure, serverless cloud service—all powered by the intelligence and orchestration of Google's Antigravity CLI and Migration Center assessment tools."

---

## 5. Conclusion (10:00 - 11:00)

**Spoken Narrative**:
> "To summarize what we saw today:
>
> 1. **Assess first**: We generated a detailed Migration Center modernization report to locate technical debt.
> 2. **Standardize using Skills**: We used Antigravity CLI with specific skills to enforce enterprise architectural patterns, logging, and database changes automatically.
> 3. **Verify and Deploy**: We validated the modernized service locally with Docker Compose, and deployed it seamlessly to Google Cloud Run.
>
> This demonstrates the power of developer-agent collaboration. Antigravity doesn't just guess—it plans, follows standards, and deploys. Thank you!"

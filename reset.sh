#!/bin/bash
# Demo Reset Script
# Usage: ./reset.sh <stage>
# Stages: 1, 2, 3, 1-backup, 2-backup, 3-backup

set -e

STAGE=$1

if [ -z "$STAGE" ]; then
  echo "Usage: ./reset.sh <1|2|3|1-backup|2-backup|3-backup>"
  echo ""
  echo "Stages:"
  echo "  1          Stage 1: Assessment (unmodernized code)"
  echo "  2          Stage 2: Modernization (unmodernized code + .antigravity.md + skill)"
  echo "  3          Stage 3: Deployment (modernized code + deployment setup)"
  echo "  1-backup   Pre-generated Stage 1 assessment report"
  echo "  2-backup   Pre-generated Stage 2 modernized .NET 8 codebase"
  echo "  3-backup   Pre-deployed verified state"
  exit 1
fi

# Map stage number to branch name
case "$STAGE" in
  1)         BRANCH="stage-1-assessment" ;;
  2)         BRANCH="stage-2-modernize" ;;
  3)         BRANCH="stage-3-deploy" ;;
  1-backup)  BRANCH="stage-1-backup" ;;
  2-backup)  BRANCH="stage-2-backup" ;;
  3-backup)  BRANCH="stage-3-backup" ;;
  *)
    echo "Error: Unknown stage '${STAGE}'"
    echo "Usage: ./reset.sh <1|2|3|1-backup|2-backup|3-backup>"
    exit 1
    ;;
esac

# Verify branch exists locally or on remote
if ! git show-ref --verify --quiet "refs/heads/${BRANCH}" && ! git show-ref --verify --quiet "refs/remotes/origin/${BRANCH}"; then
  echo "Error: Branch '${BRANCH}' does not exist yet"
  exit 1
fi

echo ""
echo "Resetting to ${BRANCH}..."
echo ""

# Discard running docker compose
if command -v docker &>/dev/null; then
  echo "Stopping any running Docker containers..."
  docker compose down -v 2>/dev/null || true
  docker ps -q | xargs -r docker stop 2>/dev/null || true
fi

# Discard any local modifications and checkout target branch
git checkout -- . 2>/dev/null || true
git clean -fd 2>/dev/null || true
git checkout "${BRANCH}"

# Install node dependencies for MCP server if present in this stage
if [ -d "mcp-server" ] && [ -f "mcp-server/package.json" ]; then
  echo "Installing MCP server dependencies..."
  cd mcp-server
  if command -v bun &>/dev/null; then
    bun install --silent
  elif command -v npm &>/dev/null; then
    npm install --silent
  fi
  cd ..
fi

echo ""
echo "=================================================="
echo "  Ready for Stage ${STAGE}!"
echo "=================================================="
echo ""

case "$STAGE" in
  1)
    echo "Run the Migration Center App Modernization Assessment:"
    echo "  codmod create full --codebase ./dotnet-migration-sample --output-path ./codmod-full-report-dotnet-mod.html --experiments=enable_pdf,enable_images --improve-fidelity --intent=MICROSOFT_MODERNIZATION --optional-sections \"files,classes\""
    ;;
  2)
    echo "Modernize the .NET application using Antigravity CLI:"
    echo "  cd dotnet-migration-sample"
    echo "  agy \"modernize this .NET application to .NET 8, convert EF6 to EF Core, use PostgreSQL, and containerize\""
    ;;
  3)
    echo "Deploy the application to Google Cloud Run:"
    echo "  cd dotnet-migration-sample"
    echo "  agy \"deploy our application to Cloud Run and verify the deployment URL\""
    ;;
  *-backup)
    echo "This is the pre-generated backup stage."
    if [ "$STAGE" = "2-backup" ]; then
      echo "To run the application locally:"
      echo "  cd dotnet-migration-sample"
      echo "  docker compose up --build"
    fi
    ;;
esac

echo ""

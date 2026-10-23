# URL Shortener — Blue/Green Demo

## What you can see
- Blue v1: blue-themed landing page, Swagger title `URL Shortener API`, version `1.0.0`.
- Green v2: green-themed landing page, Swagger title `Smart URL Manager API`, version `2.0.0`, plus v2 link-details and analytics endpoints.
- Both versions expose `/health`, `/shorten`, `/stats/{short_code}` and `/{short_code}`.
- Compose uses a shared local named volume for demo persistence. For multi-VM Azure deployment, configure both versions with the same shared PostgreSQL `DATABASE_URL`; do not use separate local SQLite files for production.

## Run both versions locally (Docker required)
From this folder:
```bash
docker compose up --build -d
```
Open:
- Blue UI: http://localhost:8001/
- Blue Swagger: http://localhost:8001/docs
- Green UI: http://localhost:8002/
- Green Swagger: http://localhost:8002/docs
- Health: http://localhost:8001/health and http://localhost:8002/health

Stop:
```bash
docker compose down
```
Keep the named data volume to retain local test data. To remove it too, use `docker compose down -v`.

## No-Docker local run
```bash
python -m venv .venv
# Windows PowerShell:
.venv\\Scripts\\Activate.ps1
pip install -r requirements.txt
$env:APP_VERSION="1.0.0"
$env:APP_COLOR="blue"
uvicorn app.main:app --reload --port 8001
```
For Green, use a second terminal with `APP_VERSION=2.0.0`, `APP_COLOR=green`, and port 8002. Use a shared `DATABASE_URL` for data continuity. SQLite is the local default.

## Notes
This is the application starter. Azure infrastructure and GitHub Actions blue/green switching/rollback are the next phase. Do not deploy to Azure until the app passes local tests and the shared production database is configured.

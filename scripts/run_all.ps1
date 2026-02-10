$ErrorActionPreference = "Stop"

Write-Host "== Watt'sUp: run_all =="

# 1) Start services (Postgres + Metabase)
Write-Host "== Starting Docker services (postgres, metabase) =="
docker compose up -d postgres metabase

# 2) Wait for Postgres
Write-Host "== Waiting for Postgres to be ready =="
for ($i = 1; $i -le 60; $i++) {
  try {
    docker compose exec -T postgres pg_isready -U energy -d wattsup | Out-Null
    Write-Host "Postgres is ready."
    break
  } catch {
    Start-Sleep -Seconds 2
  }

  if ($i -eq 60) {
    Write-Host "Postgres did not become ready in time."
    docker compose logs postgres
    throw "Postgres not ready"
  }
}

# 3) Install Python deps (in current venv)
Write-Host "== Installing Python dependencies =="
python -m pip install -r requirements.txt

# 4) Ingest CSV
Write-Host "== Ingesting supplier CSV =="
python .\ingest\ingest_supplier_csv.py

# 5) Run dbt (Docker)
Write-Host "== Running dbt build/test/docs (Docker) =="
docker compose run --rm dbt build
docker compose run --rm dbt test
docker compose run --rm dbt docs generate

Write-Host "== Done =="
Write-Host "Metabase: http://localhost:3001"
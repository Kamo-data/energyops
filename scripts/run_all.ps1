$ErrorActionPreference = "Stop"

if (!(Test-Path ".\.venv")) {
  python -m venv .venv
}

. .\.venv\Scripts\Activate.ps1
pip install -r requirements.txt

python ingest\ingest_supplier_csv.py

Push-Location dbt\energyops
dbt run --profiles-dir ..
dbt test --profiles-dir ..
Pop-Location

Write-Host "✅ Pipeline terminé (ingest + dbt run + dbt test)"

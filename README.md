# EnergyOps — Suivi conso électricité (CSV fournisseur → Postgres → dbt → Metabase)

Projet "EnergyOps" : ingestion d’un export fournisseur d’électricité (CSV), chargement en PostgreSQL, modélisation avec dbt, visualisation dans Metabase.

![Dashboard EnergyOps](docs/screenshots/Dashboard.png)

## Stack
- Python (ingestion CSV)
- PostgreSQL (stockage)
- dbt (modélisation + tests)
- Metabase (dashboard)
- Docker Compose (reproductibilité)

## Architecture (simplifiée)
CSV fournisseur → Python ingest → `raw.supplier_meter_readings`  
→ dbt staging → `analytics.stg_supplier_meter_readings`  
→ dbt marts → `analytics.fct_energy_period`, `analytics.agg_energy_calendar_month_est`  
→ Metabase (dashboards)

## Pré-requis
- Docker Desktop
- Git
- (Optionnel) Python 3.10+ si tu veux lancer l’ingestion en local

## Démarrage rapide
### 1) Lancer la stack
```bash
docker compose up -d

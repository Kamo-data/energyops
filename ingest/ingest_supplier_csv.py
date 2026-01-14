import os
import glob
import pandas as pd
import psycopg2
from psycopg2.extras import execute_values

DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = int(os.getenv("DB_PORT", "5432"))
DB_NAME = os.getenv("DB_NAME", "energyops")
DB_USER = os.getenv("DB_USER", "energy")
DB_PASS = os.getenv("DB_PASS", "energy")

RAW_GLOB = os.getenv("RAW_GLOB", "data/raw/*.csv")


def find_header_row(filepath: str) -> int:
    # Cherche une ligne qui contient "Date début" et "Consommation"
    with open(filepath, "r", encoding="utf-8-sig") as f:
        for i, line in enumerate(f):
            if ("Date début" in line) and ("Consommation" in line):
                return i
    raise ValueError("En-tête non trouvé (ligne contenant 'Date début' et 'Consommation').")


def read_supplier_csv(filepath: str) -> pd.DataFrame:
    header_idx = find_header_row(filepath)

    df = pd.read_csv(
        filepath,
        sep=";",
        skiprows=header_idx,   # saute le préambule, garde la ligne d'en-tête comme header
        encoding="utf-8-sig",
        engine="python",
    )

    # Nettoyage en-têtes avec espaces parasites (ex: "Date début ")
    df.columns = [c.strip() for c in df.columns]

    rename = {
        "Date début": "period_start",
        "Date fin": "period_end",
        "Type relève": "reading_type",
        "Type cadran": "cadran",
        "Index début": "index_start",
        "Index fin": "index_end",
        "Consommation (kWh)": "kwh",
    }
    df = df.rename(columns=rename)

    # Parsing dates FR
    df["period_start"] = pd.to_datetime(df["period_start"], dayfirst=True, errors="coerce").dt.date
    df["period_end"] = pd.to_datetime(df["period_end"], dayfirst=True, errors="coerce").dt.date

    # Normalisation valeurs numériques (gère virgule si jamais)
    for col in ["index_start", "index_end", "kwh"]:
        df[col] = (
            df[col].astype(str)
            .str.replace(",", ".", regex=False)
            .str.strip()
        )
        df[col] = pd.to_numeric(df[col], errors="coerce")

    df["cadran"] = df["cadran"].astype(str).str.strip().str.upper()
    df["reading_type"] = df["reading_type"].astype(str).str.strip()

    # Filtrage lignes invalides
    df = df.dropna(subset=["period_start", "period_end", "cadran", "kwh"])
    df = df[df["kwh"] >= 0]

    return df[["period_start", "period_end", "reading_type", "cadran", "index_start", "index_end", "kwh"]]


def start_run(conn, source_file: str) -> int:
    with conn.cursor() as cur:
        cur.execute(
            "insert into audit.ingestion_runs(source_file) values (%s) returning run_id",
            (source_file,),
        )
        return cur.fetchone()[0]


def finish_run(conn, run_id: int, status: str, rows: int, error: str | None):
    with conn.cursor() as cur:
        cur.execute(
            """
            update audit.ingestion_runs
            set finished_at = now(),
                status = %s,
                rows_upserted = %s,
                error = %s
            where run_id = %s
            """,
            (status, rows, error, run_id),
        )


def main():
    files = sorted(glob.glob(RAW_GLOB))
    if not files:
        print(f"Aucun fichier trouvé dans {RAW_GLOB}")
        return

    conn = psycopg2.connect(
        host=DB_HOST, port=DB_PORT, dbname=DB_NAME, user=DB_USER, password=DB_PASS
    )
    conn.autocommit = False

    try:
        for f in files:
            run_id = start_run(conn, os.path.basename(f))
            try:
                df = read_supplier_csv(f)
                rows = [
                    (
                        r.period_start,
                        r.period_end,
                        r.reading_type,
                        r.cadran,
                        r.index_start,
                        r.index_end,
                        r.kwh,
                        os.path.basename(f),
                    )
                    for r in df.itertuples(index=False)
                ]

                upsert_sql = """
                insert into raw.supplier_meter_readings
                  (period_start, period_end, reading_type, cadran, index_start, index_end, kwh, source_file)
                values %s
                on conflict (period_start, period_end, cadran) do update set
                  reading_type = excluded.reading_type,
                  index_start = excluded.index_start,
                  index_end = excluded.index_end,
                  kwh = excluded.kwh,
                  source_file = excluded.source_file,
                  ingested_at = now()
                """

                with conn.cursor() as cur:
                    execute_values(cur, upsert_sql, rows, page_size=1000)

                finish_run(conn, run_id, "SUCCESS", len(rows), None)
                conn.commit()
                print(f"[OK] {os.path.basename(f)} : {len(rows)} lignes upsertées")

            except Exception as e:
                conn.rollback()
                finish_run(conn, run_id, "FAILED", 0, str(e))
                conn.commit()
                print(f"[KO] {os.path.basename(f)} : {e}")

    finally:
        conn.close()


if __name__ == "__main__":
    main()

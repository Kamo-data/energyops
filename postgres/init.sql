create schema if not exists raw;
create schema if not exists audit;
create schema if not exists config;
create schema if not exists analytics;

create table if not exists raw.supplier_meter_readings (
  period_start date not null,
  period_end date not null,
  reading_type text not null,
  cadran text not null,
  index_start numeric(12,0),
  index_end numeric(12,0),
  kwh numeric(12,3) not null,
  source_file text not null,
  ingested_at timestamptz not null default now(),
  primary key (period_start, period_end, cadran)
);

create table if not exists audit.ingestion_runs (
  run_id bigserial primary key,
  started_at timestamptz not null default now(),
  finished_at timestamptz,
  status text not null default 'RUNNING',
  source_file text,
  rows_upserted int default 0,
  error text
);

create table if not exists config.tariff_hp_hc (
  effective_from date primary key,
  hp_eur_per_kwh numeric(10,4) not null,
  hc_eur_per_kwh numeric(10,4) not null
);

insert into config.tariff_hp_hc(effective_from, hp_eur_per_kwh, hc_eur_per_kwh)
values ('2020-01-01', 0.2500, 0.2000)
on conflict (effective_from) do nothing;

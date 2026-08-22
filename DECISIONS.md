# Project Decisions Log

## Data Loading
- Loaded via `\copy` (client-side) instead of `COPY` — Postgres server process lacked 
  read permission on local Windows file paths.
- Set `client_encoding = UTF8` before loading `order_reviews_raw` — file contains 
  Portuguese accented characters that failed under the default WIN1252 client encoding.
- Checked `product_category_name_translation.csv` for UTF-8 BOM (common with 
  Windows-exported CSVs); confirmed via LENGTH() on the first row that no BOM leaked in.
- Verified row counts against known Olist dataset counts after each load as a sanity check.

## Schema Design
- Used a two-layer approach: `staging` schema (loose TEXT columns, no constraints, 
  mirrors raw CSVs exactly including source typos like `product_name_lenght`) and a 
  `public` production schema (proper types, primary keys, foreign keys, CHECK constraints).
- Staging tables intentionally left unconstrained so a single bad/malformed row 
  doesn't block the entire load — validated the data first, then decided how to handle 
  issues before inserting into the constrained production schema.
- Composite primary keys used for order_items, order_payments, order_reviews, since 
  no single column uniquely identifies a row in these tables.

## Validation Findings & Handling
- 2,965 orders have a null `order_delivered_customer_date` — expected, represents 
  canceled/undelivered orders (cross-checked against order_status: shipped, unavailable, 
  invoiced, canceled, etc.).
- 610 products had a null `product_category_name` — kept the rows, mapped to 
  'uncategorized' via COALESCE during the transform step rather than dropping real 
  transaction data over a missing descriptive field.
- 2 orphan category names (`portateis_cozinha_e_preparadores_de_alimentos`, `pc_gamer`) 
  affecting 13 products — manually mapped to English translations rather than dropping.
- 166 orders had `order_delivered_carrier_date` before `order_purchase_timestamp`, and 
  23 had `order_delivered_customer_date` before `order_delivered_carrier_date` — both 
  logically impossible sequences. Flagged via a `date_anomaly_flag` boolean column on 
  `orders` (excluded from delivery-duration analysis, retained for revenue/review analysis).
- 2 order_payments rows had `payment_installments = 0` — [note your final choice: 
  excluded from the insert / flagged].

## Known Limitations
- `geolocation` has no unique key and duplicate zip/lat/lng rows are expected 
  (source data quirk, not a load error).
- `review_creation_date` stored as DATE (not TIMESTAMP) — source data only records 
  the day, not time-of-day, for review creation.
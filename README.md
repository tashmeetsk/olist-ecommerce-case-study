# Olist E-Commerce Case Study: Root-Cause Analysis of Customer Reviews

## Business Question
Why are review scores low in certain segments, and what should be fixed first — 
delivery delay, price, product category, seller quality, or region?

## Data
Real anonymized data from Olist, a Brazilian e-commerce marketplace (~100K orders, 
2016–2018). Source: Kaggle (olistbr/brazilian-ecommerce).

## Setup
1. Download the dataset from Kaggle: 
   [Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)
2. Extract the CSVs into `data/raw/`
3. Run the SQL scripts in order: `sql/01_staging_schema.sql` → `sql/02_load_staging.sql` → 
   `sql/03_validation_checks.sql` → `sql/04_production_schema.sql` → `sql/05_transform_load.sql`

## Approach
1. Loaded raw CSVs into staging tables, validated for uniqueness, orphan keys, 
   nulls, date logic, and range violations (see DECISIONS.md)
2. Transformed into a constrained production schema (PostgreSQL)
3. [Analysis — coming next]
4. [Dashboard — coming next]

## Findings
[TBD]

## Recommendation
[TBD]
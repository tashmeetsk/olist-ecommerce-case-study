-- \copy done with psql shell
\copy staging.customers_raw FROM 'data/raw/olist_customers_dataset.csv' CSV HEADER
\copy staging.sellers_raw FROM 'data/raw/olist_sellers_dataset.csv' CSV HEADER
\copy staging.products_raw FROM 'data/raw/olist_products_dataset.csv' CSV HEADER
\copy staging.orders_raw FROM 'data/raw/olist_orders_dataset.csv' CSV HEADER
\copy staging.order_items_raw FROM 'data/raw/olist_order_items_dataset.csv' CSV HEADER
\copy staging.order_payments_raw FROM 'data/raw/olist_order_payments_dataset.csv' CSV HEADER
\copy staging.order_reviews_raw FROM 'data/raw/olist_order_reviews_dataset.csv' CSV HEADER
\copy staging.geolocation_raw FROM 'data/raw/olist_geolocation_dataset.csv' CSV HEADER
\copy staging.product_category_translation_raw FROM 'data/raw/product_category_name_translation.csv' CSV HEADER

-- check for BOM issue with translation file
SELECT product_category_name, LENGTH(product_category_name)
FROM staging.product_category_translation_raw
LIMIT 5;

-- no issue found
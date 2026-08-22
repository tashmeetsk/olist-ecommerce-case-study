-- DATA STAGING

-- ============================================
-- 1. UNIQUENESS CHECKS
-- ============================================
select order_id from staging.orders_raw group by order_id having count(*) > 1;
SELECT customer_id FROM staging.customers_raw GROUP BY customer_id HAVING COUNT(*) > 1;
SELECT seller_id FROM staging.sellers_raw GROUP BY seller_id HAVING COUNT(*) > 1;
SELECT product_id FROM staging.products_raw GROUP BY product_id HAVING COUNT(*) > 1;
SELECT product_category_name FROM staging.product_category_translation_raw GROUP BY product_category_name HAVING COUNT(*) > 1;

-- composite keys — group by both columns together
SELECT order_id, order_item_id FROM staging.order_items_raw GROUP BY order_id, order_item_id HAVING COUNT(*) > 1;
SELECT order_id, payment_sequential FROM staging.order_payments_raw GROUP BY order_id, payment_sequential HAVING COUNT(*) > 1;
SELECT review_id, order_id FROM staging.order_reviews_raw GROUP BY review_id, order_id HAVING COUNT(*) > 1;

-- ============================================
-- 2. ORPHAN / FOREIGN-KEY CHECKS
-- ============================================
select * from staging.order_items_raw oir
left join staging.products_raw pr on oir.product_id = pr.product_id
where pr.product_id is null;

SELECT o.* FROM staging.orders_raw o
LEFT JOIN staging.customers_raw c ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

SELECT oi.* FROM staging.order_items_raw oi
LEFT JOIN staging.orders_raw o ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;

SELECT oi.* FROM staging.order_items_raw oi
LEFT JOIN staging.sellers_raw s ON oi.seller_id = s.seller_id
WHERE s.seller_id IS NULL;

SELECT p.* FROM staging.order_payments_raw p
LEFT JOIN staging.orders_raw o ON p.order_id = o.order_id
WHERE o.order_id IS NULL;

SELECT r.* FROM staging.order_reviews_raw r
LEFT JOIN staging.orders_raw o ON r.order_id = o.order_id
WHERE o.order_id IS NULL;

SELECT pr.product_id, pr.product_category_name FROM staging.products_raw pr
LEFT JOIN staging.product_category_translation_raw t ON pr.product_category_name = t.product_category_name
WHERE t.product_category_name IS NULL AND pr.product_category_name IS NOT NULL; -- found 13 records

-- ============================================
-- 3. NULL CHECKS
-- ============================================
select count(*) from staging.orders_raw where order_delivered_customer_date is null; -- 2965
SELECT COUNT(*) FROM staging.orders_raw WHERE order_approved_at IS NULL; -- 160
SELECT COUNT(*) FROM staging.products_raw WHERE product_category_name IS NULL; -- 610
SELECT COUNT(*) FROM staging.products_raw WHERE product_weight_g IS NULL; -- 2

-- ============================================
-- 4. DATE SANITY CHECKS
-- ============================================
select * from staging.orders_raw
where order_delivered_customer_date::timestamp < order_purchase_timestamp::timestamp;

SELECT * FROM staging.orders_raw
WHERE order_approved_at::timestamp < order_purchase_timestamp::timestamp;

SELECT * FROM staging.orders_raw
WHERE order_delivered_carrier_date::timestamp < order_purchase_timestamp::timestamp; -- found 166 records

SELECT * FROM staging.orders_raw
WHERE order_delivered_customer_date::timestamp < order_delivered_carrier_date::timestamp; -- found 23 records

-- ============================================
-- 5. RANGE / DOMAIN CHECKS
-- ============================================
select * from staging.order_reviews_raw where review_score::int not between 1 and 5;
SELECT * FROM staging.order_items_raw WHERE price::numeric <= 0;
SELECT * FROM staging.order_items_raw WHERE freight_value::numeric < 0;
SELECT * FROM staging.order_payments_raw WHERE payment_value::numeric < 0;
SELECT * FROM staging.order_payments_raw WHERE payment_installments::int <= 0; -- found 2 records

SELECT DISTINCT customer_state FROM staging.customers_raw
WHERE customer_state NOT IN ('AC','AL','AP','AM','BA','CE','DF','ES','GO','MA','MT','MS','MG','PA','PB','PR','PE','PI','RJ','RN','RS','RO','RR','SC','SP','SE','TO');

SELECT DISTINCT seller_state FROM staging.sellers_raw
WHERE seller_state NOT IN ('AC','AL','AP','AM','BA','CE','DF','ES','GO','MA','MT','MS','MG','PA','PB','PR','PE','PI','RJ','RN','RS','RO','RR','SC','SP','SE','TO');


-- OBSERVATIONS

-- NULL count observations
SELECT order_status, count(*) FROM staging.orders_raw 
WHERE order_delivered_customer_date IS NULL
GROUP BY order_status;

SELECT order_status, count(*) FROM staging.orders_raw
WHERE order_approved_at IS NULL
GROUP BY order_status;
	
-- ORPHAN observation
SELECT pr.product_category_name, count(*)
FROM staging.products_raw pr
LEFT JOIN staging.product_category_translation_raw t ON pr.product_category_name = t.product_category_name
WHERE t.product_category_name IS NULL AND pr.product_category_name IS NOT NULL
GROUP BY pr.product_category_name;

-- ============================================
-- 6. ANOMALIES & EXCEPTIONS (DATA QUALITY ISSUES)
-- ============================================
-- 6.1 Orders with delivery delays beyond reasonable limits
-- SELECT
--     COUNT(*)                                                            AS total_orders,
--     COUNT(*) FILTER (
--         WHERE EXTRACT(
--             DAY FROM
--                 (order_delivered_customer_date::timestamp
--                 - order_purchase_timestamp::timestamp)
--         ) > 60
--     )                                                                   AS orders_delayed_over_60_days,
--     ROUND(
--         COUNT(*) FILTER (
--             WHERE EXTRACT(
--                 DAY FROM
--                     (order_delivered_customer_date::timestamp
--                     - order_purchase_timestamp::timestamp)
--             ) > 60
--         ) * 100.0 / COUNT(*),
--         2
--     )                                                                   AS pct_delayed_over_60_days
-- FROM staging.orders_raw
-- WHERE order_status = 'delivered';


-- -- 6.2 Order cancellations by type
-- SELECT
--     order_status,
--     COUNT(*)                                                            AS num_orders,
--     ROUND(
--         COUNT(*) * 100.0 / (SELECT COUNT(*) FROM staging.orders_raw),
--         2
--     )                                                                   AS percentage
-- FROM staging.orders_raw
-- GROUP BY order_status
-- ORDER BY 2 DESC;


-- -- 6.3 Order items without seller
-- SELECT
--     COUNT(*)                                                            AS total_order_items,
--     COUNT(*) FILTER (
--         WHERE seller_id IS NULL
--     )                                                                   AS items_with_null_seller,
--     ROUND(
--         COUNT(*) FILTER (
--             WHERE seller_id IS NULL
--         ) * 100.0 / COUNT(*),
--         2
--     )                                                                   AS pct_with_null_seller
-- FROM staging.order_items_raw;


-- -- 6.4 Reviews with unexpected values (outside 1–5)
-- SELECT
--     review_score,
--     COUNT(*)                                                            AS num_reviews
-- FROM staging.order_reviews_raw
-- WHERE review_score::int NOT BETWEEN 1 AND 5
-- GROUP BY review_score;


-- -- 6.5 Payment value vs total value mismatch
-- SELECT
--     COUNT(*)                                                            AS total_payments,
--     COUNT(*) FILTER (
--         WHERE ABS(payment_value - (SELECT payment_value FROM staging.order_payments_raw p2 WHERE p2.order_id = order_payments_raw.order_id)
--         )
--     )                                                                   AS payments_with_mismatch,
--     ROUND(
--         COUNT(*) FILTER (
--             WHERE ABS(payment_value - (SELECT payment_value FROM staging.order_payments_raw p2 WHERE p2.order_id = order_payments_raw.order_id)
--             )
--         ) * 100.0 / COUNT(*),
--         2
--     )                                                                   AS pct_with_mismatch
-- FROM staging.order_payments_raw;


-- -- 6.6 Order items with canceled orders
-- SELECT
--     COUNT(*)                                                            AS total_order_items,
--     COUNT(*) FILTER (
--         WHERE order_id IN (
--             SELECT order_id
--             FROM staging.orders_raw
--             WHERE order_status = 'canceled'
--         )
--     )                                                                   AS items_in_canceled_orders,
--     ROUND(
--         COUNT(*) FILTER (
--             WHERE order_id IN (
--                 SELECT order_id
--                 FROM staging.orders_raw
--                 WHERE order_status = 'canceled'
--             )
--         ) * 100.0 / COUNT(*),
--         2
--     )                                                                   AS pct_items_in_canceled_orders
-- FROM staging.order_items_raw;


-- -- 6.7 Products without category translation
-- SELECT
--     COUNT(*)                                                            AS total_products,
--     COUNT(*) FILTER (
--         WHERE product_category_name IS NULL
--         OR NOT EXISTS (
--             SELECT 1
--             FROM staging.product_category_translation_raw t
--             WHERE t.product_category_name = products_raw.product_category_name
--         )
--     )                                                                   AS products_without_translation,
--     ROUND(
--         COUNT(*) FILTER (
--             WHERE product_category_name IS NULL
--             OR NOT EXISTS (
--                 SELECT 1
--                 FROM staging.product_category_translation_raw t
--                 WHERE t.product_category_name = products_raw.product_category_name
--             )
--         ) * 100.0 / COUNT(*),
--         2
--     )                                                                   AS pct_products_without_translation
-- FROM staging.products_raw;


-- -- 6.8 Weight outliers
-- SELECT
--     COUNT(*)                                                            AS total_products,
--     COUNT(*) FILTER (
--         WHERE product_weight_g > 30000
--     )                                                                   AS products_over_30kg,
--     ROUND(
--         COUNT(*) FILTER (
--             WHERE product_weight_g > 30000
--         ) * 100.0 / COUNT(*),
--         2
--     )                                                                   AS pct_over_30kg
-- FROM staging.products_raw;


-- -- 6.9 Volume outliers (approximated by dimensions)
-- SELECT
--     COUNT(*)                                                            AS total_products,
--     COUNT(*) FILTER (
--         WHERE product_length_cm * product_height_cm * product_width_cm > 500000
--     )                                                                   AS products_over_500k_cm3,
--     ROUND(
--         COUNT(*) FILTER (
--             WHERE product_length_cm * product_height_cm * product_width_cm > 500000
--         ) * 100.0 / COUNT(*),
--         2
--     )                                                                   AS pct_over_500k_cm3
-- FROM staging.products_raw;


-- -- 6.10 Orders with missing geolocation data
-- SELECT
--     COUNT(*)                                                            AS total_orders,
--     COUNT(*) FILTER (
--         WHERE customer_zip_code_prefix IS NULL
--         OR customer_city IS NULL
--         OR customer_state IS NULL
--     )                                                                   AS orders_missing_geolocation,
--     ROUND(
--         COUNT(*) FILTER (
--             WHERE customer_zip_code_prefix IS NULL
--             OR customer_city IS NULL
--             OR customer_state IS NULL
--         ) * 100.0 / COUNT(*),
--         2
--     )                                                                   AS pct_missing_geolocation
-- FROM staging.customers_raw;


-- -- 6.11 Orders with no payments
-- SELECT
--     COUNT(*)                                                            AS total_orders,
--     COUNT(*) FILTER (
--         NOT EXISTS (
--             SELECT 1
--             FROM staging.order_payments_raw p
--             WHERE p.order_id = orders_raw.order_id
--         )
--     )                                                                   AS orders_without_payment,
--     ROUND(
--         COUNT(*) FILTER (
--             NOT EXISTS (
--                 SELECT 1
--                 FROM staging.order_payments_raw p
--                 WHERE p.order_id = orders_raw.order_id
--             )
--         ) * 100.0 / COUNT(*),
--         2
--     )                                                                   AS pct_orders_without_payment
-- FROM staging.orders_raw;


-- -- 6.12 Orders with more than 100 installments
-- SELECT
--     COUNT(*)                                                            AS total_payments,
--     COUNT(*) FILTER (
--         WHERE payment_installments > 100
--     )                                                                   AS payments_over_100_installments,
--     ROUND(
--         COUNT(*) FILTER (
--             WHERE payment_installments > 100
--         ) * 100.0 / COUNT(*),
--         2
--     )                                                                   AS pct_payments_over_100_installments
-- FROM staging.order_payments_raw;


-- -- 6.13 Orders with multiple payment types per order
-- SELECT
--     COUNT(*)                                                            AS total_orders,
--     COUNT(*) FILTER (
--         SELECT COUNT(*) FROM staging.order_payments_raw p
--         WHERE p.order_id = orders_raw.order_id
--     )                                                                   AS orders_with_payment,
--     ROUND(
--         COUNT(*) FILTER (
--             SELECT COUNT(*) FROM staging.order_payments_raw p
--             WHERE p.order_id = orders_raw.order_id
--         ) * 100.0 / COUNT(*),
--         2
--     )                                                                   AS pct_orders_with_payment
-- FROM staging.orders_raw;

-- ============================================
-- BRANCH 1: Delivery Delay
-- Finding: Delay-related causes (late + never delivered) = 42.72% of all bad reviews.
-- On-time orders = 57.29% of all bad reviews.
-- Conclusion: Delay is a strong per-order predictor (79% of 8+ day-late orders get 
-- a bad review, vs 9.28% baseline for on-time), but does NOT explain the majority 
-- of the overall problem. Other branches still needed.
-- ============================================


-- to check how many undelivered orders are present and review <= 2
SELECT COUNT(*) 
FROM public.order_reviews r
WHERE r.review_score <= 2
AND r.order_id NOT IN (SELECT order_id FROM public.orders WHERE order_delivered_customer_date IS NOT NULL);


WITH delay_calc AS (
    SELECT 
        order_id,
        EXTRACT(DAY FROM (order_delivered_customer_date - order_estimated_delivery_date)) AS delay_days
    FROM public.orders
),
bucketed AS (
    SELECT 
        order_id,
        CASE 
			WHEN delay_days is null then 'never_delivered'
            WHEN delay_days <= 0 THEN 'on_time_or_early'
            WHEN delay_days BETWEEN 1 AND 3 THEN '1-3_days_late'
            WHEN delay_days BETWEEN 4 AND 7 THEN '4-7_days_late'
            ELSE '8+_days_late'
        END AS delay_bucket
    FROM delay_calc
)
SELECT 
    b.delay_bucket,
    COUNT(*) AS total_orders,
    ROUND(AVG(r.review_score), 2) AS avg_score,
    ROUND(COUNT(*) FILTER (WHERE r.review_score <= 2) * 100.0 / COUNT(*), 2) AS pct_1_2_star
FROM bucketed b
JOIN public.order_reviews r ON b.order_id = r.order_id
GROUP BY b.delay_bucket
ORDER BY b.delay_bucket;


WITH delay_calc AS (
    SELECT 
        order_id,
        CASE 
            WHEN order_delivered_customer_date IS NULL THEN NULL
            ELSE EXTRACT(DAY FROM (order_delivered_customer_date - order_estimated_delivery_date))
        END AS delay_days
    FROM public.orders
),
bucketed AS (
    SELECT 
        order_id,
        CASE 
            WHEN delay_days IS NULL THEN 'never_delivered'
            WHEN delay_days <= 0 THEN 'on_time_or_early'
            WHEN delay_days BETWEEN 1 AND 3 THEN '1-3_days_late'
            WHEN delay_days BETWEEN 4 AND 7 THEN '4-7_days_late'
            ELSE '8+_days_late'
        END AS delay_bucket
    FROM delay_calc
)
SELECT
    b.delay_bucket,
    COUNT(*) FILTER (WHERE r.review_score <= 2) AS bad_review_count,
    ROUND(
        COUNT(*) FILTER (WHERE r.review_score <= 2) * 100.0 
        / (SELECT COUNT(*) FROM public.order_reviews WHERE review_score <= 2), 
    2) AS pct_of_all_bad_reviews
FROM bucketed b
JOIN public.order_reviews r ON b.order_id = r.order_id
GROUP BY b.delay_bucket
ORDER BY b.delay_bucket;

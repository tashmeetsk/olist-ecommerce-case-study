-- ============================================
-- PHASE 5: Opportunity Sizing & Impact Modeling
-- Purpose: Sizing bad-review reduction in worst-performing Northeast states 
-- (AL, MA, SE) by benchmarking against platform on-time performance (9.28% bad rate).
-- Finding: Eliminating delay on 255 late-delivered orders across AL, MA, and SE 
-- avoids an estimated ~145 bad reviews (~43% of all 1-2★ reviews in these states), 
-- dropping their combined bad-review rate from 22.3% to 12.7%.
-- ============================================

WITH delay_calc AS (
    SELECT 
        o.order_id,
        c.customer_state,
        r.review_score,
        CASE 
            WHEN o.order_delivered_customer_date IS NULL THEN NULL
            ELSE EXTRACT(DAY FROM (o.order_delivered_customer_date - o.order_estimated_delivery_date))
        END AS delay_days
    FROM public.orders o
    JOIN public.customers c ON o.customer_id = c.customer_id
    JOIN public.order_reviews r ON o.order_id = r.order_id
),
bucketed AS (
    SELECT 
        order_id,
        customer_state,
        review_score,
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
    customer_state,
    delay_bucket,
    COUNT(*) AS total_orders,
    COUNT(*) FILTER (WHERE review_score <= 2) AS actual_bad_reviews,
    ROUND(COUNT(*) FILTER (WHERE review_score <= 2) * 100.0 / COUNT(*), 2) AS pct_bad_reviews
FROM bucketed
WHERE customer_state IN ('AL', 'MA', 'SE', 'SP')
GROUP BY customer_state, delay_bucket
ORDER BY customer_state, delay_bucket;

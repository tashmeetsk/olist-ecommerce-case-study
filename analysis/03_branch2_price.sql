-- ============================================
-- BRANCH 2: Price
-- Finding: Relative price (vs. category avg) — avg score 4.03-4.04, bad-review 
-- rate 15.92-16.61% across all buckets (much_above_avg, above_avg, at_or_below_avg).
-- Absolute price (quartile buckets: <₹40, ₹40-75, ₹75-135, ₹135-230, >₹230) — 
-- avg score 4.03-4.04, bad-review rate 15.92-16.83% across all buckets.
-- Cross-checked category-price confound for the 7 flagged categories (Branch 3) — 
-- no consistent pattern (worst-review category was priciest, but 2nd-worst was 
-- cheaper than a good-review category).
-- Conclusion: Price, in both relative and absolute framing, is RULED OUT as a 
-- driver of review score. Less than 1 percentage point of variation across every 
-- bucket tested, in two independent tests.
-- ============================================


-- to find percentile distribution for absolute price distribution
SELECT
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY price) AS p25,
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY price) AS median,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY price) AS p75,
    PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY price) AS p90,
    MIN(price) AS min_price,
    MAX(price) AS max_price
FROM public.order_items;


WITH item_prices AS (
    SELECT 
        o.order_id, 
        o.price, 
        p.product_category_name,
        AVG(o.price) OVER (PARTITION BY p.product_category_name) AS category_avg_price
    FROM public.order_items o
    JOIN public.products p ON o.product_id = p.product_id
),
bucketed AS (
    SELECT 
        order_id,
        -- Relative Buckets (From original Query 3)
        CASE 
            WHEN price > category_avg_price * 1.5 THEN 'relative: much_above_avg'
            WHEN price > category_avg_price THEN 'relative: above_avg'
            ELSE 'relative: at_or_below_avg'
        END AS relative_price_bucket,
        
        -- Absolute Buckets (From original Query 5)
        CASE 
            WHEN price < 40 THEN 'absolute: under_40'
            WHEN price < 75 THEN 'absolute: 40_to_75'
            WHEN price < 135 THEN 'absolute: 75_to_135'
            WHEN price < 230 THEN 'absolute: 135_to_230'
            ELSE 'absolute: over_230'
        END AS abs_price_bucket
    FROM item_prices
)
SELECT 
    COALESCE(b.relative_price_bucket, b.abs_price_bucket) AS price_bucket,
    COUNT(*) AS total_orders,
    ROUND(AVG(r.review_score), 2) AS avg_score,
    ROUND(COUNT(*) FILTER (WHERE r.review_score <= 2) * 100.0 / COUNT(*), 2) AS pct_1_2_star
FROM bucketed b
JOIN public.order_reviews r ON b.order_id = r.order_id
GROUP BY GROUPING SETS (
    (b.relative_price_bucket), 
    (b.abs_price_bucket)
)
ORDER BY price_bucket;


-- to find if high cost categories have bad reviews or not
SELECT 
    p.product_category_name,
    COUNT(*) AS total_orders,
    ROUND(AVG(o.price), 2) AS avg_price
FROM public.order_items o
JOIN public.products p ON o.product_id = p.product_id
WHERE p.product_category_name IN 
    ('moveis_escritorio', 'moveis_decoracao', 'cama_mesa_banho', 'informatica_acessorios',
     'alimentos_bebidas', 'livros_interesse_geral', 'malas_acessorios')
GROUP BY p.product_category_name
ORDER BY avg_price DESC;

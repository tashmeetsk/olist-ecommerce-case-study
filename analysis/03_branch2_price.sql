select p.product_category_name, avg(o.price)
from public.order_items o join public.products p on o.product_id = p.product_id
group by p.product_category_name;

select o.order_id, p.product_id, o.price, p.product_category_name, avg(o.price) over (partition by product_category_name) as category_avg_price
from public.order_items o join public.products p on o.product_id = p.product_id;

WITH price_calc AS (
    SELECT o.order_id, o.price, p.product_category_name,
           AVG(o.price) OVER (PARTITION BY p.product_category_name) AS category_avg_price
    FROM public.order_items o
    JOIN public.products p ON o.product_id = p.product_id
),
price_bucketed AS (
    SELECT order_id,
           CASE 
               WHEN price > category_avg_price * 1.5 THEN 'much_above_avg'
               WHEN price > category_avg_price THEN 'above_avg'
               ELSE 'at_or_below_avg'
           END AS price_bucket
    FROM price_calc
)
select 
	b.price_bucket,
	count(*) as total_orders,
	round(avg(r.review_score), 2) as avg_score,
	round(COUNT(*) FILTER (WHERE r.review_score <= 2) * 100.0 / COUNT(*), 2) as pct_1_2_star
from price_bucketed b
join public.order_reviews r on b.order_id = r.order_id
group by price_bucket
order by price_bucket;

-- to find percentile distribution
SELECT
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY price) AS p25,
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY price) AS median,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY price) AS p75,
    PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY price) AS p90,
    MIN(price) AS min_price,
    MAX(price) AS max_price
FROM public.order_items;

WITH abs_price_bucketed AS (
    SELECT order_id,
           CASE 
               WHEN price < 40 THEN 'under_40'
               WHEN price < 75 THEN '40_to_75'
               WHEN price < 135 THEN '75_to_135'
               WHEN price < 230 THEN '135_to_230'
               ELSE 'over_230'
           END AS abs_price_bucket
    FROM public.order_items
)
select 
	b.abs_price_bucket,
	count(*) as total_orders,
	round(avg(r.review_score), 2) as avg_score,
	round(COUNT(*) FILTER (WHERE r.review_score <= 2) * 100.0 / COUNT(*), 2) as pct_1_2_star
from abs_price_bucketed b
join public.order_reviews r on b.order_id = r.order_id
group by abs_price_bucket;

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

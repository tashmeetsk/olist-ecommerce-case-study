-- ============================================
-- BRANCH 5: Geography
-- Finding: Clear regional pattern — worst late/review states: AL (21% late, 
-- 23.91% bad), MA (17% late, 21.72% bad), SE (15% late, 21.78% bad), CE (13% 
-- late, 19.86% bad), concentrated in the North/Northeast. Best: SP (4% late, 
-- 12.63% bad, 41,746 orders), PR (4% late, 12.49% bad), MG (4% late, 13.30% bad).
-- Distance cross-check (Haversine, customer-to-seller): distance does NOT cleanly 
-- predict this. Remote Amazon states (AM 2646km, AC 2642km, RR 3249km) show LOW 
-- late rates (3-11%); AL, much closer (1842km), is the WORST performer. RJ, at 
-- only 487km (near SP's 247km), still shows 12% late / 20.74% bad.
-- Conclusion: Delay/dissatisfaction is a genuine REGIONAL LOGISTICS-QUALITY 
-- issue, not explained by physical distance. Northeast cluster underperforms 
-- despite not being most remote; RJ underperforms despite proximity — points to 
-- fixable infrastructure/last-mile gaps rather than an unavoidable distance penalty.
-- ============================================


WITH delay_calc AS (
    SELECT 
        order_id,
		customer_id,
        CASE 
            WHEN order_delivered_customer_date IS NULL THEN NULL
            ELSE EXTRACT(DAY FROM (order_delivered_customer_date - order_estimated_delivery_date))
        END AS delay_days
    FROM public.orders
)
select
	c.customer_state,
	count(*) as total_orders,
	round(avg(d.delay_days), 2) as avg_delay_days,
	round(count(*) filter(where d.delay_days > 0) * 100.0 / count(*)) as pct_late_orders
from delay_calc d
join public.customers c on d.customer_id = c.customer_id
group by c.customer_state
order by pct_late_orders desc;

select
	c.customer_state,
	count(*) as total_orders,
	ROUND(AVG(r.review_score), 2) AS avg_review_score,
    ROUND(COUNT(*) FILTER (WHERE r.review_score <= 2) * 100.0 / COUNT(*), 2) AS pct_1_2_star
from public.orders o
join public.customers c on o.customer_id = c.customer_id
join public.order_reviews r on o.order_id = r.order_id
group by c.customer_state
order by pct_1_2_star desc;


-- accounting the pure distance bwtween sellers and customers
CREATE TABLE zip_location AS
SELECT 
    geolocation_zip_code_prefix AS zip_code_prefix,
    AVG(geolocation_lat) AS lat,
    AVG(geolocation_lng) AS lng
FROM public.geolocation
GROUP BY geolocation_zip_code_prefix;

with order_locations as (
	SELECT
	    o.order_id,
	    c.customer_state,
	    cust_loc.lat AS customer_lat,
	    cust_loc.lng AS customer_lng,
	    sell_loc.lat AS seller_lat,
	    sell_loc.lng AS seller_lng
	FROM public.orders o
	JOIN public.customers c ON o.customer_id = c.customer_id
	JOIN public.zip_location cust_loc ON c.customer_zip_code_prefix = cust_loc.zip_code_prefix
	JOIN public.order_items oi ON o.order_id = oi.order_id
	JOIN public.sellers s ON oi.seller_id = s.seller_id
	JOIN public.zip_location sell_loc ON s.seller_zip_code_prefix = sell_loc.zip_code_prefix
),
orders_distance as (
	select
	    order_id,
	    customer_state,
	    6371 * acos(
	        cos(radians(customer_lat)) * cos(radians(seller_lat)) *
	        cos(radians(seller_lng) - radians(customer_lng)) +
	        sin(radians(customer_lat)) * sin(radians(seller_lat))
	    ) AS distance_km
	FROM order_locations
)
select
	customer_state,
	avg(distance_km) as avg_distance_km
from orders_distance
group by customer_state
order by avg_distance_km desc;

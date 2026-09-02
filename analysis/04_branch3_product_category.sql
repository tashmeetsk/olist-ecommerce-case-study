select 
	p.product_category_name,
	count(*) as total_orders,
	round(avg(r.review_score), 2) as avg_score,
	round(count(*) filter (where r.review_score <= 2) * 100.0 / count(*), 2) as pct_1_2_star
from public.order_items o
join public.products p on o.product_id = p.product_id 
join public.order_reviews r on o.order_id = r.order_id
group by p.product_category_name
having count(*) > 100
order by pct_1_2_star desc;

WITH delay_calc AS (
    SELECT 
        order_id,
        CASE 
            WHEN order_delivered_customer_date IS NULL THEN NULL
            ELSE EXTRACT(DAY FROM (order_delivered_customer_date - order_estimated_delivery_date))
        END AS delay_days
    FROM public.orders
)
select 
	p.product_category_name,
	count(*) as total_orders,
	round(avg(d.delay_days), 2) as avg_delay_days,
	round(count(*) filter(where d.delay_days > 0) * 100.0 / count(*)) as pct_late_orders
from delay_calc d
join public.order_items o on d.order_id = o.order_id
join public.products p on o.product_id = p.product_id
group by p.product_category_name
having count(*) > 100
order by pct_late_orders desc;

-- to find column name of products
SELECT column_name FROM information_schema.columns 
WHERE table_name = 'products'
ORDER BY ordinal_position;

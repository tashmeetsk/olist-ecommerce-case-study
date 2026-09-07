-- ============================================
-- BRANCH 3: Product Category
-- Finding: Bad-review rate ranges from ~7.89% (alimentos_bebidas) to 26.08% 
-- (moveis_escritorio) among categories with ≥100 orders — an 18-point spread.
-- Worst performers cluster in furniture/home goods: moveis_escritorio (26.08%), 
-- moveis_decoracao (19.46%), cama_mesa_banho (18.96%), informatica_acessorios (18.61%).
-- Best performers: alimentos_bebidas (7.89%), livros_interesse_geral (8.56%), 
-- malas_acessorios (9.65%).
-- Cross-checked against delay by category — late rate ranges only 4-8% across 
-- best/worst categories (vs. 18-point spread in reviews), ruling out delay as 
-- the hidden cause.
-- Conclusion: Category is a genuine, largely INDEPENDENT driver of dissatisfaction, 
-- distinct from delay and price. Likely causes (transit damage, fit/quality 
-- mismatch on bulky items) not directly observable in this dataset.
-- ============================================


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

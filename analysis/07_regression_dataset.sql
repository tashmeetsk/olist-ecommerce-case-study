SELECT 
    o.order_id,
    r.review_score,
	CASE 
    	WHEN order_delivered_customer_date IS NULL THEN NULL
        ELSE EXTRACT(DAY FROM (order_delivered_customer_date - order_estimated_delivery_date))
    END AS delay_days,
	oi.price,
	p.product_category_name,
    oi.seller_id,
    c.customer_state
FROM public.orders o
JOIN public.order_reviews r ON o.order_id = r.order_id
JOIN public.order_items oi ON o.order_id = oi.order_id
JOIN public.products p ON oi.product_id = p.product_id
JOIN public.customers c ON o.customer_id = c.customer_id
WHERE o.order_id IN (
    SELECT order_id FROM public.order_items GROUP BY order_id HAVING COUNT(*) = 1
);
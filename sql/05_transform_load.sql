-- to check the columns in a table
SELECT column_name FROM information_schema.columns 
WHERE table_name = 'sellers'
ORDER BY ordinal_position;

-- to check the data in a table
select * from staging.products_raw limit 2;

-- changed column type in a table
ALTER TABLE public.order_reviews 
ALTER COLUMN review_creation_date TYPE DATE;

-- ==============
-- tranform load
-- ==============

INSERT INTO public.customers (customer_id, customer_unique_id, customer_zip_code_prefix, customer_city, customer_state)
SELECT customer_id, customer_unique_id, customer_zip_code_prefix::INTEGER, customer_city, customer_state
FROM staging.customers_raw;

INSERT INTO public.sellers (seller_id, seller_zip_code_prefix, seller_city, seller_state)
SELECT seller_id, seller_zip_code_prefix::INTEGER, seller_city, seller_state
FROM staging.sellers_raw;

INSERT INTO public.product_category_translation (product_category_name, product_category_name_english)
SELECT product_category_name, product_category_name_english
FROM staging.product_category_translation_raw;

SELECT product_category_name, COUNT(*) 
FROM staging.product_category_translation_raw 
GROUP BY product_category_name 
HAVING COUNT(*) > 1;

-- to check the time of insert of duplicate entries
SELECT ctid, * FROM staging.product_category_translation_raw
WHERE product_category_name = 'pc_gamer';

-- deleting the entries
DELETE FROM staging.product_category_translation_raw 
WHERE product_category_name 
IN ('portateis_cozinha_e_preparadores_de_alimentos', 'pc_gamer');

INSERT INTO public.product_category_translation (product_category_name, product_category_name_english) VALUES
('portateis_cozinha_e_preparadores_de_alimentos', 'kitchen_appliances_and_food_prep'),
('pc_gamer', 'gaming_pc'),
('uncategorized', 'uncategorized');

insert into public.products (
	product_id, 
	product_category_name, 
	product_name_length, 
	product_description_length, 
	product_photos_qty, 
	product_weight_g, 
	product_length_cm, 
	product_height_cm, 
	product_width_cm
) select 
	product_id, 
	COALESCE(product_category_name, 'uncategorized'), 
	product_name_lenght::INTEGER, 
	product_description_lenght::INTEGER, 
	product_photos_qty::INTEGER, 
	product_weight_g::NUMERIC, 
	product_length_cm::NUMERIC, 
	product_height_cm::NUMERIC, 
	product_width_cm::INTEGER
from staging.products_raw;

insert into public.orders (
	order_id,
	customer_id,
	order_status,
	order_purchase_timestamp,
	order_approved_at,
	order_delivered_carrier_date,
	order_delivered_customer_date,
	order_estimated_delivery_date,
	date_anomaly_flag
) select
	order_id,
	customer_id,
	order_status,
	order_purchase_timestamp::TIMESTAMP,
	order_approved_at::TIMESTAMP,
	order_delivered_carrier_date::TIMESTAMP,
	order_delivered_customer_date::TIMESTAMP,
	order_estimated_delivery_date::DATE,
	(CASE 
		WHEN order_delivered_carrier_date::TIMESTAMP < order_purchase_timestamp::TIMESTAMP 
     	OR order_delivered_customer_date::TIMESTAMP < order_delivered_carrier_date::TIMESTAMP 
     	THEN TRUE ELSE FALSE 
	END) AS date_anomaly_flag
from staging.orders_raw;

insert into public.order_items (order_id, order_item_id, product_id, seller_id, shipping_limit_date, price, freight_value)
select order_id, order_item_id::integer, product_id, seller_id, shipping_limit_date::timestamp, price::numeric, freight_value::numeric
from staging.order_items_raw;

insert into public.order_payments (order_id, payment_sequential, payment_type, payment_installments, payment_value)
select order_id, payment_sequential::INTEGER, payment_type, payment_installments::INTEGER, payment_value::NUMERIC
from staging.order_payments_raw
where payment_installments::int > 0;

insert into public.order_reviews (review_id, order_id, review_score, review_comment_title, review_comment_message, review_creation_date, review_answer_timestamp)
select review_id, order_id, review_score::integer, review_comment_title, review_comment_message, review_creation_date::date, review_answer_timestamp::timestamp
from staging.order_reviews_raw;

insert into public.geolocation (geolocation_zip_code_prefix, geolocation_lat, geolocation_lng, geolocation_city, geolocation_state)
select geolocation_zip_code_prefix::integer, geolocation_lat::numeric, geolocation_lng::numeric, geolocation_city, geolocation_state
from staging.geolocation_raw;

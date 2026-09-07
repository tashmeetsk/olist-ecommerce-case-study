-- ============================================
-- BRANCH 4: Seller
-- Finding: Bad reviews are heavily CONCENTRATED — worst 10% of sellers (309/3,090) 
-- account for ~73% of all bad reviews.
-- Ranking by raw count conflates scale with quality: top sellers by volume sit 
-- near/below the 14.69% baseline rate (13.85-14.99%), while a rate-based screen 
-- (min. 20 orders) isolates a distinct set of structurally broken sellers — 
-- 34-65% bad-review rate, avg score 2.10-3.19 — invisible in a volume-only view.
-- Cross-checked delay for the worst-rate sellers: mixed result — roughly half 
-- show elevated late rates (up to 49% vs ~8% baseline), the other half ship 
-- on-time/early (0% late) yet still score 2.10-3.00, pointing to non-delivery causes.
-- Conclusion: Seller quality is a primary driver with TWO distinct profiles — 
-- large sellers adding volume at normal rates (scale issue), and low/mid-volume 
-- sellers with broken quality independent of delivery (rate issue).
-- ============================================

-- ============================================
-- 4a. CONCENTRATION — are bad reviews concentrated in a few sellers?
-- ============================================
WITH seller_metrics AS (
    SELECT
        o.seller_id,
        COUNT(*) AS total_orders,
        ROUND(AVG(r.review_score), 2) AS avg_review_score,
        COUNT(*) FILTER (WHERE r.review_score <= 2) AS bad_reviews,
        ROUND(COUNT(*) FILTER (WHERE r.review_score <= 2) * 100.0 / COUNT(*), 2) AS pct_1_2_star
    FROM public.order_items o
    JOIN public.order_reviews r ON o.order_id = r.order_id
    GROUP BY o.seller_id
),
ranked AS (
    SELECT
        *,
        SUM(bad_reviews) OVER (ORDER BY bad_reviews DESC) AS running_total_bad_reviews,
        SUM(bad_reviews) OVER () AS grand_total_bad_reviews,
        ROW_NUMBER() OVER (ORDER BY bad_reviews DESC) AS seller_rank
    FROM seller_metrics
)
SELECT
    seller_rank,
    seller_id,
    total_orders,
    avg_review_score,
    bad_reviews,
    pct_1_2_star,
    ROUND(running_total_bad_reviews * 100.0 / grand_total_bad_reviews, 2) AS pct_of_all_bad_reviews_cumulative
FROM ranked
ORDER BY seller_rank;

-- ============================================
-- 4b. QUALITY — worst sellers by RATE (not raw count), min 20 orders
-- ============================================
WITH seller_metrics AS (
    SELECT
        o.seller_id,
        COUNT(*) AS total_orders,
        ROUND(AVG(r.review_score), 2) AS avg_review_score,
        COUNT(*) FILTER (WHERE r.review_score <= 2) AS bad_reviews,
        ROUND(COUNT(*) FILTER (WHERE r.review_score <= 2) * 100.0 / COUNT(*), 2) AS pct_1_2_star
    FROM public.order_items o
    JOIN public.order_reviews r ON o.order_id = r.order_id
    GROUP BY o.seller_id
)
SELECT *
FROM seller_metrics
WHERE total_orders >= 20
ORDER BY avg_review_score ASC
LIMIT 30;

-- ============
-- 4c.
-- ============
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
	o.seller_id,
	count(*) as total_orders,
	round(avg(d.delay_days), 2) as avg_delay_days,
	round(count(*) filter(where d.delay_days > 0) * 100.0 / count(*)) as pct_late_orders
from delay_calc d
join public.order_items o on d.order_id = o.order_id
WHERE o.seller_id IN (
    'ffff564a4f9085cd26170f4732393726', '1ca7077d890b907f89be8c954a02686a',
    '5bc55dbe2f12b6af6d83ed46023e0dc8', '973f21788dfab357250f69a8dcb7ddee',
    '2709af9587499e95e803a6498a5a56e9', 'bb135baca94c82fcb731335ad5b04a03',
    'ec4608a1f76453166bb312b2968aeaf4', '2eb70248d66e0e3ef83659f71b244378',
    'b19f3ca2ea475913750f25a5c37c8d8f', 'e250d617a0ad591ba9bd663e584a895d',
    '66fd84ee7528c0c0de85d0f44a73d5ab', '602044f2c16190c2c6e45eb35c2e21cb',
	'54965bbe3e4f07ae045b90b0b8541f52', '099095b050cfe8eb1ddff5317587e96e',
	'a49928bcdf77c55c6d6e05e09a9b4ca5', '972d0f9cf61b499a4812cf0bfa3ad3c4',
	'2a1348e9addc1af5aaa619b1a3679d6b', 'c6381d2d013342748761e906d45aff76',
	'8e6d7754bc7e0f22c96d255ebda59eba', 'bbad7e518d7af88a0897397ffdca1979',
	'ad781527c93d00d89a11eecd9dcad7c1', '8444e55c1f13cd5c179851e5ca5ebd00',
	'5058e8c1e82653974541e83690655b4a', 'f08c008c8a8d31417763738a1788a2a8',
	'e7d5b006eb624f13074497221eb37807', '4c8b8048e33af2bf94f2eb547746a916',
	'dc8798cbf453b7e0f98745e396cc5616', 'adcf50477d6a1f5d91bb9d54c4903cb5',
	'95f83f51203c626648c875dd41874c7f', '1dfe5347016252a7884b694d4f10f5c4'
)
group by o.seller_id
having count(*) >= 20;

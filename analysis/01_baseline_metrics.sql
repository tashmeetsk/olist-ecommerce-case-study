-- ============================================
-- PHASE 2: Baseline Metrics
-- Results: avg score = 4.09 | 1-2★ = 14.69% of all reviews
-- Distribution: 1★ = 11424, 2★ = 3151, 3★ = 8179, 4★ = 19142, 5★ = 57328
-- ============================================

SELECT AVG(review_score) FROM public.order_reviews;

SELECT review_score, COUNT(*) 
FROM public.order_reviews
GROUP BY review_score
ORDER BY review_score;

SELECT COUNT(*) FILTER (WHERE review_score < 3) * 100 / (SELECT COUNT(*) FROM public.order_reviews)::decimal AS percentage 
FROM public.order_reviews;
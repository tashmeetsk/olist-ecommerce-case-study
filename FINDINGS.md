# Findings Log

## Phase 3: Root Cause Analysis

### Branch 1: Delivery Delay
- Delay strongly predicts bad reviews at the order level: 9.28% bad-review rate 
  when on-time, rising to 79.16% when 8+ days late.
- However, delay-related causes (late delivery + never delivered) account for 
  only 42.72% of ALL bad reviews — the majority (57.29%) come from orders that 
  arrived on time. Delay is a real, high-confidence factor but not the dominant 
  driver overall.

### Branch 2: Price
- Relative price (vs. category avg): no meaningful effect — avg score 4.03-4.04, 
  bad-review rate 15.92-16.61% across all buckets.
- Absolute price: no meaningful effect either — avg score 4.03-4.04, bad-review 
  rate 15.92-16.83% across all buckets (quartile-based cutoffs: <₹40, ₹40-75, 
  ₹75-135, ₹135-230, >₹230).
- Checked average price by category for the 7 flagged categories to rule out 
  price as a hidden confound behind the category effect: no consistent pattern — 
  moveis_escritorio (worst reviews) is also the most expensive (₹162), but 
  moveis_decoracao (also poor reviews, ₹87.56) is cheaper than malas_acessorios 
  (good reviews, ₹128.60). Price and review performance don't move together 
  consistently across these categories, reinforcing Branch 2's conclusion that 
  price is not a meaningful driver.
- Conclusion: Price, in both framings, is ruled out as a driver of review score.

### Branch 3: Product Category
- Category shows a real, meaningful effect on review score among high-volume 
  categories (≥100 orders): bad-review rate ranges from ~7.89% (alimentos_bebidas) 
  to 28.24% (fashion_roupa_masculina) — a ~20-point spread, roughly 4x between best 
  and worst.
- Worst performers cluster around furniture/home goods: moveis_escritorio (26.08%), 
  moveis_decoracao (19.46%), cama_mesa_banho (18.96%), informatica_acessorios (18.61%).
- Best performers: alimentos_bebidas (7.89%), livros_interesse_geral (8.56%), 
  malas_acessorios (9.65%).
- Cross-checked against delivery delay by category to rule out delay as the hidden 
  cause: late-order rate ranges from ~4% (best categories) to ~8% (worst categories) 
  — a real but modest 4-point spread, far smaller than the 18-point spread in 
  review outcomes. Delay differs somewhat by category but does not come close to 
  explaining the size of the category effect.
- Conclusion: Product category is a genuine, largely independent driver of 
  dissatisfaction, distinct from delay and price (both ruled out separately). 
  Likely explanations specific to furniture/home-goods: transit damage on bulky 
  items, harder-to-judge fit/quality from listing photos, assembly/quality 
  mismatches — not covered by this dataset, worth noting as a limitation.

### Branch 4: Seller
- Concentration: Bad reviews are heavily concentrated — the worst 10% of sellers 
  (309 of 3,090) account for ~73% of all bad reviews (1-2★) on the platform.
- Volume vs. Rate: Ranking by raw count conflates scale with quality; top sellers 
  by volume sit near or below the 14.69% platform baseline (13.85%-14.99%), while 
  a rate-based screen (min. 20 orders) isolates structurally broken sellers averaging 
  2.10-3.19 stars with 34%-65% bad-review rates who fly under the radar on volume alone.
- Delivery delay cross-check: Late delivery only partially explains seller underperformance; 
  roughly half of high-bad-rate sellers have elevated late rates (up to 49% vs. ~8% 
  baseline), while the other half ship reliably on time (0% late) yet still average 
  2.10-3.00 stars, pointing to non-logistics drivers (product quality, packaging, conduct).
- Conclusion: Seller quality is a primary driver with two distinct profiles — large 
  sellers contributing high complaint volume at normal rates (scale issue), and low/mid-volume 
  sellers with broken quality operating independently of delivery delays (rate issue).

### Branch 5: Geography
- Regional pattern: Late delivery and review score correlate strongly across all 
  27 states — worst performers cluster in the North/Northeast (AL: 21% late, 23.91% 
  bad reviews; MA: 17% late, 21.72% bad; SE: 15% late, 21.78% bad; CE: 13% late, 
  19.86% bad), while best performers cluster in the Southeast/South (SP: 4% late, 
  12.63% bad across 41,746 orders; PR: 4% late, 12.49% bad; MG: 4% late, 13.30% bad).
- Distance cross-check (Haversine): Physical customer-to-seller distance does NOT 
  explain regional underperformance. Remote Amazon-region states (AM: 2,646km, AC: 
  2,642km, RR: 3,249km) maintain low delay rates (3-11%) and decent reviews despite 
  extreme distance, whereas AL (1,842km) is the platform's worst performer (21% late, 
  23.91% bad), and RJ underperforms substantially (12% late, 20.74% bad) despite 
  its proximity (487km vs. SP's 247km).
- Conclusion: Regional variation in delay and satisfaction is driven by genuine 
  differences in logistics infrastructure and last-mile carrier performance, not 
  geographic distance. The Northeast cluster suffers from an operational carrier gap, 
  while RJ's underperformance reflects urban last-mile congestion rather than 
  long-haul transit friction.


## Phase 4: Regression Synthesis (Joint Hypothesis Testing)
- Method & Fit: OLS regression (`review_score ~ delay_days + price + seller_avg_score + product_category + customer_state`) 
  on 86,756 single-item orders (R² = 0.152). Tests all branches jointly to isolate true independent root causes.
- Confirmed Drivers (Branches 1, 4, 5):
  - Delay (Branch 1): Confirmed independent driver (coef -0.0349, p < 0.001) — each extra day costs ~0.035 stars 
    (~1 full star per 30 days late), surviving all controls.
  - Seller Quality (Branch 4): Strongest predictor in the model (coef +0.896, p < 0.001) — confirms seller 
    quality dominates platform satisfaction (note: coefficient is somewhat circular/inflated by construction).
  - Geography (Branch 5): Confirmed regional effect — multiple states remain statistically significant (SP p < 0.001, 
    MG p = 0.001, PR p < 0.001, DF p = 0.002) even after controlling for delay, price, and seller.
- Ruled Out / Revised (Branches 2, 3):
  - Price (Branch 2): Practically negligible (coef -0.0000668, p = 0.001) — statistically non-zero due to large N, 
    but a ₹1,000 difference shifts score by only 0.067 stars. Confirms price is ruled out.
  - Category (Branch 3): Revised/explained away — nearly all category dummies lose significance (p > 0.05, 
    e.g., moveis_escritorio p = 0.878) once seller quality and region are controlled for. Category underperformance 
    was primarily confounded by worse sellers and regional logistics skew.
- Methodological Caveat: High condition number (5.1e+04) indicates multicollinearity across seller, category, 
  and state; category coefficients should be interpreted with caution, though delay, seller, and regional effects remain robust.
- Conclusion (MECE Synthesis): Delivery delay, seller quality, and regional logistics are the genuine independent 
  drivers of bad reviews. Price has no practical effect, and product category is largely an artifact of seller and 
  geographic confounding rather than an independent root cause.


## Phase 5: Opportunity Sizing & Impact Modeling
- Problem & Target: Sizing customer satisfaction recovery by eliminating the 
  delivery delay gap in the worst-performing Northeast states (AL, MA, SE) vs. 
  benchmark state SP (-10.14 days avg delay).
- Marginal Score Lift (Regression Model):
  - AL: 2.19 day improvement × 0.0349 pts/day ≈ +0.076 points lift
  - MA: 1.37 day improvement × 0.0349 pts/day ≈ +0.048 points lift
  - SE: 0.97 day improvement × 0.0349 pts/day ≈ +0.034 points lift
  - Takeaway: Predicts a modest +0.034 to +0.076 point linear average score lift per order.
- Counterfactual Bad-Review Elimination (Bucket-Based Model):
  - Across AL, MA, and SE, 255 delivered orders were late (`1-3d`, `4-7d`, `8+d`), 
    generating 169 actual 1-2★ reviews (a 66.3% bad rate).
  - Counterfactual benchmark: if those 255 late orders achieved the platform on-time 
    bad-review rate (9.28%), they would produce only 23.7 bad reviews.
  - State breakdown of avoided bad reviews:
    - AL: 56 actual late bad reviews - 7.7 expected = ~48.3 bad reviews avoided 
      (bad-review rate drops from 23.91% → 12.25%).
    - MA: 79 actual late bad reviews - 11.3 expected = ~67.7 bad reviews avoided 
      (bad-review rate drops from 21.72% → 12.64%).
    - SE: 34 actual late bad reviews - 4.6 expected = ~29.4 bad reviews avoided 
      (bad-review rate drops from 21.78% → 13.35%).
  - Combined impact: Eliminates an estimated ~145 bad reviews (~43.0% of all 337 bad 
    reviews in these states), slashing the combined bad-review rate from 22.3% 
    down to 12.7% (well below the 14.69% platform baseline).
- Methodological Assumptions & Caveats:
  - 1. Scope: Covers late-but-delivered orders only (255 orders). Complete non-delivery 
    failures (`never_delivered`: 61 orders / 47 bad reviews across AL, MA, SE) represent 
    lost packages/cancellations requiring separate operational interventions and are 
    excluded from this delay-reduction sizing.
  - 2. Benchmark baseline: Uses platform-wide on-time bad-review rate (9.28%). Using 
    each state's own empirical on-time rate (AL 9.21%, MA 10.61%, SE 10.21%) yields 
    ~143 avoided bad reviews, confirming the estimate is robust to regional baseline assumptions.
- Conclusion (Headline Recommendation): Closing the carrier delivery-delay gap in 
  Alagoas, Maranhão, and Sergipe to match platform on-time efficiency eliminates an 
  estimated 145 bad reviews (~43% of all 1-2★ reviews in these states), independent of 
  complete non-delivery failures or catalog-level changes.

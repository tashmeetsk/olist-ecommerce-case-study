# Findings Log

## Branch 1: Delivery Delay
- Delay strongly predicts bad reviews at the order level: 9.28% bad-review rate 
  when on-time, rising to 79.16% when 8+ days late.
- However, delay-related causes (late delivery + never delivered) account for 
  only 42.72% of ALL bad reviews — the majority (57.29%) come from orders that 
  arrived on time. Delay is a real, high-confidence factor but not the dominant 
  driver overall.

## Branch 2: Price
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

## Branch 3: Product Category
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

## Branch 4: Seller
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


## Branch 5: Geography
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

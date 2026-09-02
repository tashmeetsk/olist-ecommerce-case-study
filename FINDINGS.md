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
- Conclusion: Price, in both framings, is ruled out as a driver of review score.
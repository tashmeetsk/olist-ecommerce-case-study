import csv

with open("olist_order_reviews_dataset.csv", encoding="utf-8") as f:
    reader = csv.reader(f)
    next(reader)  # skip header
    count = sum(1 for row in reader)

print(count)
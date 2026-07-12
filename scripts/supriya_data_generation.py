"""
======================================================================
NutriFlow - RoyalProteinBowl.in
Data Generation Script
======================================================================
This script generates all 11 realistic datasets (6 Dimension tables +
5 Fact tables) for the RoyalProteinBowl Data Analytics project.

Run this script ONCE, in order. It will create a `data/raw/` folder
with all CSV files ready to be loaded into MySQL or used directly in
Python/Power BI.

Author: Generated for IntelUniVen Student Project
======================================================================
"""

import pandas as pd
import numpy as np
from faker import Faker
import random
from datetime import datetime, timedelta
import os

# ----------------------------------------------------------------
# SETUP
# ----------------------------------------------------------------
fake = Faker('en_IN')          # Indian locale - gives Indian names, addresses
Faker.seed(42)                  # Reproducible results every run
random.seed(42)
np.random.seed(42)

OUTPUT_DIR = "../data/raw"
os.makedirs(OUTPUT_DIR, exist_ok=True)

def save(df, filename):
    """Helper to save a dataframe and print confirmation."""
    path = os.path.join(OUTPUT_DIR, filename)
    df.to_csv(path, index=False)
    print(f"✅ {filename:<25} → {len(df):>6} rows saved")

# ======================================================================
# TABLE 7 & 8: ORDERS + ORDER_ITEMS (Fact) - generated together
# ======================================================================
def generate_orders_and_items(customers_df, staff_df, coupons_df, locations_df, item_master_df, n_orders=3000):

    active_staff = staff_df[staff_df["status"] == "A"]
    active_coupons = coupons_df["coupon_code"].tolist()
    serviceable_locs = locations_df[locations_df["is_serviceable"] == "Y"]

    # Weighted item popularity - some items are "bestsellers"
    item_ids = item_master_df["item_id"].tolist()
    item_weights = np.random.dirichlet(np.ones(len(item_ids)) * 0.3) * 100  # creates skew
    item_weight_map = dict(zip(item_ids, item_weights))

    order_rows = []
    order_item_rows = []
    order_item_id = 1

    today = datetime(2026, 6, 30)
    order_start = today - timedelta(days=180)  # last 6 months

    for order_id in range(1, n_orders + 1):
        customer = customers_df.sample(1).iloc[0]

        # Order date weighted toward recent (business growth), but never before customer signup
        cust_signup = pd.to_datetime(customer["signup_date"])
        earliest = max(cust_signup, pd.Timestamp(order_start))
        days_available = max((pd.Timestamp(today) - earliest).days, 1)
        skew = np.random.beta(2, 1)
        order_date = earliest + timedelta(days=int(skew * days_available))

        order_time_bucket = random.choices(
            ["Morning", "Afternoon", "Evening", "Other"], weights=[25, 15, 45, 15]
        )[0]

        staff = active_staff.sample(1).iloc[0]
        loc = serviceable_locs.sample(1).iloc[0]

        # Coupon: only 30% of orders
        coupon_code = random.choice(active_coupons) if random.random() < 0.30 else None

        payment_method = np.random.choice(["UPI", "COD"], p=[0.6, 0.4])

        # Delivery status logic: recent orders can still be in-progress
        days_old = (today - order_date).days
        if days_old <= 1:
            delivery_status = random.choices(
                ["Delivered", "Out for Delivery", "Preparing", "Cancelled"],
                weights=[60, 20, 15, 5]
            )[0]
        else:
            delivery_status = np.random.choice(["Delivered", "Cancelled"], p=[0.95, 0.05])

        promised_time = 45
        actual_time = max(15, int(np.random.normal(38, 12)))

        order_rows.append({
            "order_id": order_id,
            "customer_id": customer["customer_id"],
            "staff_id": staff["staff_id"],
            "coupon_code": coupon_code,
            "delivery_pincode": loc["pincode"],
            "order_date": order_date.date(),
            "order_time": order_time_bucket,
            "payment_method": payment_method,
            "delivery_status": delivery_status,
            "promised_delivery_time": promised_time,
            "actual_delivery_time": actual_time,
            "total_amount": 0.0  # placeholder, updated after order_items generated
        })

        # ---- Order Items: 1 to 4 items per order, weighted average ~1.8 ----
        n_items_in_order = random.choices([1, 2, 3, 4], weights=[40, 35, 18, 7])[0]
        chosen_items = random.choices(item_ids, weights=item_weights, k=n_items_in_order)

        for item_id in chosen_items:
            qty = random.choices([1, 2], weights=[80, 20])[0]
            price = item_master_df.loc[item_master_df["item_id"] == item_id, "selling_price"].values[0]

            order_item_rows.append({
                "order_item_id": order_item_id,
                "order_id": order_id,
                "item_id": item_id,
                "item_quantity": qty,
                "item_price": price
            })
            order_item_id += 1

    orders_df = pd.DataFrame(order_rows)
    order_items_df = pd.DataFrame(order_item_rows)

    # ---- Calculate total_amount per order from order_items, apply coupon discount ----
    item_totals = order_items_df.groupby("order_id").apply(
        lambda x: (x["item_price"] * x["item_quantity"]).sum()
    ).reset_index(name="item_total")

    orders_df = orders_df.merge(item_totals, on="order_id", how="left")
    orders_df["item_total"] = orders_df["item_total"].fillna(0)

    def apply_discount(row):
        if pd.isna(row["coupon_code"]) or row["coupon_code"] is None:
            return round(row["item_total"], 2)
        coupon = coupons_df[coupons_df["coupon_code"] == row["coupon_code"]].iloc[0]
        if row["item_total"] < coupon["min_order_amount"]:
            return round(row["item_total"], 2)  # min order not met, no discount applied
        if coupon["discount_type"] == "Percentage":
            discount = row["item_total"] * (coupon["discount_value"] / 100)
        else:
            discount = coupon["discount_value"]
        return round(max(row["item_total"] - discount, 0), 2)

    orders_df["total_amount"] = orders_df.apply(apply_discount, axis=1)
    orders_df.drop(columns=["item_total"], inplace=True)

    save(orders_df, "orders.csv")
    save(order_items_df, "order_items.csv")
    return orders_df, order_items_df


# ======================================================================
# TABLE 9: REVIEWS (Fact)
# ======================================================================
def generate_reviews(orders_df, n_target_ratio=0.40):
    delivered_orders = orders_df[orders_df["delivery_status"] == "Delivered"]
    n_reviews = int(len(delivered_orders) * n_target_ratio)
    reviewed_orders = delivered_orders.sample(n_reviews, random_state=42)

    feedback_bank = {
        5: ["Loved the bowl, will definitely order again!", "Best protein meal in Saharanpur, super fresh.",
            "Exactly what I needed post workout. Highly recommend.", "Great taste and perfectly packed.",
            "Macros were spot on, very happy with the quality."],
        4: ["Good food but delivery took a bit longer than expected.", "Tasty meal, portion could be slightly bigger.",
            "Nice quality, will order again.", "Pretty good, just wish there were more spice options."],
        3: ["Average experience, food was okay.", "Decent but nothing special.",
            "Portion was a bit small for the price.", "Taste was fine, packaging could be better."],
        2: ["Delivery was late and food was lukewarm.", "Not as fresh as expected.",
            "Below average taste this time.", "Portion size has reduced compared to before."],
        1: ["Very disappointed, food arrived cold and late.", "Quality has gone down badly.",
            "Won't be ordering again, bad experience.", "Order was wrong and support was slow to respond."]
    }

    rows = []
    review_id = 1
    for _, order in reviewed_orders.iterrows():
        overall = random.choices([5, 4, 3, 2, 1], weights=[55, 25, 10, 6, 4])[0]

        # Sub-ratings correlate with overall but have small variation
        def jitter(base):
            return int(np.clip(base + random.choice([-1, 0, 0, 0, 1]), 1, 5))

        review_date = pd.to_datetime(order["order_date"]) + timedelta(days=random.randint(0, 5))

        rows.append({
            "review_id": review_id,
            "customer_id": order["customer_id"],
            "order_id": order["order_id"],
            "review_date": review_date.date(),
            "overall_rating": overall,
            "delivery_rating": jitter(overall),
            "taste_rating": jitter(overall),
            "portion_rating": jitter(overall),
            "feedback": random.choice(feedback_bank[overall]),
            "status": np.random.choice(["Approved", "Pending"], p=[0.9, 0.1])
        })
        review_id += 1

    df = pd.DataFrame(rows)
    save(df, "reviews.csv")
    return df

# ======================================================================
# MAIN EXECUTION - Run all generators IN ORDER (respects FK dependencies)
# ======================================================================
if __name__ == "__main__":
    print("=" * 60)
    print("Generating RoyalProteinBowl Synthetic Dataset")
    print("=" * 60)
    orders_df, order_items_df = generate_orders_and_items(
        customers_df, staff_df, coupons_df, locations_df, item_master_df, n_orders=3000
    )

    reviews_df = generate_reviews(orders_df)
    print("=" * 60)
    print("✅ ALL 11 TABLES GENERATED SUCCESSFULLY")
    print(f"📁 Files saved to: {os.path.abspath(OUTPUT_DIR)}")
    print("=" * 60)
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
# TABLE 1: CALENDAR (Dimension)
# ======================================================================
def generate_calendar():
    start_date = datetime(2025, 1, 1)
    end_date = datetime(2026, 12, 31)
    dates = pd.date_range(start_date, end_date, freq='D')

    # A small bank of major Indian holidays (approximate, for realism only)
    holidays = {
        "2025-01-26", "2025-03-14", "2025-08-15", "2025-10-02", "2025-10-21",
        "2025-12-25", "2026-01-26", "2026-03-04", "2026-08-15", "2026-10-02",
        "2026-11-08", "2026-12-25"
    }

    df = pd.DataFrame({"date": dates})
    df["day_number"] = df["date"].dt.day
    df["day_name"] = df["date"].dt.day_name()
    df["week_number"] = df["date"].dt.isocalendar().week
    df["month_number"] = df["date"].dt.month
    df["month_name"] = df["date"].dt.month_name()
    df["quarter"] = "Q" + df["date"].dt.quarter.astype(str)
    df["year"] = df["date"].dt.year
    df["is_weekend"] = df["day_name"].isin(["Saturday", "Sunday"]).map({True: "Y", False: "N"})
    df["is_holiday"] = df["date"].dt.strftime("%Y-%m-%d").isin(holidays).map({True: "Y", False: "N"})

    save(df, "calendar.csv")
    return df


# ======================================================================
# TABLE 2: LOCATIONS (Dimension)
# ======================================================================
def generate_locations():
    cities_data = [
        ("Saharanpur", "Uttar Pradesh", ["247001", "247002", "247003", "247004", "247232"]),
        ("Meerut", "Uttar Pradesh", ["250001", "250002", "250004"]),
        ("Muzaffarnagar", "Uttar Pradesh", ["251001", "251002", "251003"]),
        ("Dehradun", "Uttarakhand", ["248001", "248002", "248003"]),
        ("Haridwar", "Uttarakhand", ["249401", "249402"]),
        ("Roorkee", "Uttarakhand", ["247667", "247661"]),
    ]

    rows = []
    location_id = 1
    for city, state, pincodes in cities_data:
        for pin in pincodes:
            zone = random.choices(["Zone A", "Zone B", "Zone C"], weights=[40, 35, 25])[0]
            serviceable = np.random.choice(["Y", "N"], p=[0.8, 0.2])
            rows.append({
                "location_id": location_id,
                "pincode": pin,
                "country": "India",
                "region": "North",
                "state": state,
                "city": city,
                "delivery_zone": zone,
                "is_serviceable": serviceable
            })
            location_id += 1

    df = pd.DataFrame(rows)
    save(df, "locations.csv")
    return df


# ======================================================================
# TABLE 3: ITEM_MASTER (Dimension)
# ======================================================================
def generate_item_master():
    items = [
        # (name, category, food_category, protein_range)
        ("Grilled Chicken Power Bowl", "Bowl", "Non-Veg", (35, 45)),
        ("Paneer Tikka Protein Bowl", "Bowl", "Veg", (28, 38)),
        ("Egg White Veggie Bowl", "Bowl", "Veg", (25, 32)),
        ("Tandoori Chicken Quinoa Bowl", "Bowl", "Non-Veg", (38, 45)),
        ("Soya Chunk Power Bowl", "Bowl", "Veg", (26, 34)),
        ("Fish Tikka Protein Bowl", "Bowl", "Non-Veg", (32, 40)),
        ("Chickpea Sprout Bowl", "Bowl", "Veg", (20, 28)),
        ("Mutton Keema Bowl", "Bowl", "Non-Veg", (35, 42)),
        ("Tofu Stir Fry Bowl", "Bowl", "Veg", (24, 30)),
        ("Chicken Seekh Protein Bowl", "Bowl", "Non-Veg", (33, 40)),

        ("Grilled Chicken Caesar Salad", "Salad", "Non-Veg", (28, 35)),
        ("Paneer Spinach Salad", "Salad", "Veg", (20, 26)),
        ("Boiled Egg Garden Salad", "Salad", "Veg", (18, 24)),
        ("Tuna Protein Salad", "Salad", "Non-Veg", (25, 32)),
        ("Sprouts & Chickpea Salad", "Salad", "Veg", (15, 20)),
        ("Chicken Quinoa Salad", "Salad", "Non-Veg", (26, 33)),

        ("Whey Protein Banana Smoothie", "Smoothie", "Veg", (22, 28)),
        ("Peanut Butter Protein Shake", "Smoothie", "Veg", (20, 26)),
        ("Mixed Berry Protein Smoothie", "Smoothie", "Veg", (18, 24)),
        ("Chocolate Whey Shake", "Smoothie", "Veg", (24, 30)),
        ("Mango Protein Lassi", "Smoothie", "Veg", (15, 20)),
        ("Coffee Protein Smoothie", "Smoothie", "Veg", (20, 25)),

        ("Grilled Chicken Wrap", "Wrap", "Non-Veg", (28, 35)),
        ("Paneer Tikka Wrap", "Wrap", "Veg", (22, 28)),
        ("Egg Bhurji Wrap", "Wrap", "Veg", (20, 26)),
        ("Tandoori Soya Wrap", "Wrap", "Veg", (18, 24)),
        ("Chicken Seekh Wrap", "Wrap", "Non-Veg", (26, 33)),
        ("Mutton Kathi Wrap", "Wrap", "Non-Veg", (30, 36)),
        ("Falafel Protein Wrap", "Wrap", "Veg", (16, 22)),

        ("Roasted Chana Snack Box", "Snack", "Veg", (12, 18)),
        ("Boiled Egg Protein Box", "Snack", "Non-Veg", (15, 20)),
        ("Peanut Protein Bar", "Snack", "Veg", (10, 15)),
        ("Greek Yogurt Protein Cup", "Snack", "Veg", (14, 18)),
        ("Grilled Chicken Bites", "Snack", "Non-Veg", (18, 24)),
        ("Sprouts Protein Chaat", "Snack", "Veg", (10, 14)),
    ]

    contents_bank = {
        "Bowl": "Grilled protein, brown rice/quinoa, mixed vegetables, herb dressing, seeds",
        "Salad": "Fresh greens, grilled protein, cherry tomatoes, cucumber, lemon dressing",
        "Smoothie": "Whey protein, milk/yogurt, fruits, nuts, no added sugar",
        "Wrap": "Multigrain roti, grilled filling, fresh veggies, mint chutney",
        "Snack": "High protein ingredients, minimal oil, portion controlled"
    }

    rows = []
    for i, (name, category, food_cat, protein_range) in enumerate(items, start=1):
        protein = round(random.uniform(*protein_range), 1)
        calories = round(protein * random.uniform(8, 11), 1)
        carbs = round(random.uniform(15, 45), 1)
        fats = round(random.uniform(5, 18), 1)
        fiber = round(random.uniform(2, 8), 1)
        selling_price = round(random.uniform(150, 380), 2)
        cost_price = round(selling_price * random.uniform(0.40, 0.55), 2)
        has_discount = random.random() < 0.25
        discount_price = round(selling_price * 0.85, 2) if has_discount else None
        is_featured = "Y" if i <= 7 or random.random() < 0.1 else "N"  # ~6-8 featured items
        weight = round(random.uniform(220, 400), 2)

        rows.append({
            "item_id": i,
            "item_name": name,
            "item_category": category,
            "food_category": food_cat,
            "contents": contents_bank[category],
            "weight_grams": weight,
            "calories": calories,
            "proteins_g": protein,
            "carbs_g": carbs,
            "fats_g": fats,
            "fiber_g": fiber,
            "cost_price": cost_price,
            "selling_price": selling_price,
            "discount_price": discount_price,
            "stock_availability": np.random.choice(["Y", "N"], p=[0.95, 0.05]),
            "is_featured": is_featured
        })

    df = pd.DataFrame(rows)
    save(df, "item_master.csv")
    return df


# ======================================================================
# TABLE 4: COUPONS (Dimension)
# ======================================================================
def generate_coupons():
    coupons = [
        ("WELCOME10", "Welcome Offer", "Percentage", 10, 200, 500),
        ("GYM20", "Gym Partner Discount", "Percentage", 20, 300, 300),
        ("FIRST50", "First Order Flat Off", "Flat Amount", 50, 250, 400),
        ("WEEKEND15", "Weekend Special", "Percentage", 15, 200, 600),
        ("NEWYEAR100", "New Year Offer", "Flat Amount", 100, 500, 200),
        ("PROTEIN25", "Protein Week Special", "Percentage", 25, 400, 150),
        ("FLAT75", "Flat 75 Off", "Flat Amount", 75, 350, 250),
        ("SUMMER10", "Summer Fitness Offer", "Percentage", 10, 200, 500),
        ("BULK150", "Bulk Order Discount", "Flat Amount", 150, 800, 100),
        ("REFER20", "Referral Reward", "Percentage", 20, 250, 300),
        ("MONTHLY200", "Monthly Plan Offer", "Flat Amount", 200, 1000, 100),
        ("FLASH30", "Flash Sale", "Percentage", 30, 300, 150),
        ("LOYALTY50", "Loyalty Reward", "Flat Amount", 50, 200, 400),
        ("FESTIVE15", "Festive Special", "Percentage", 15, 250, 350),
        ("EXPIRED5", "Old Test Coupon", "Percentage", 5, 100, 50),
    ]

    rows = []
    for code, name, dtype, value, min_order, max_uses in coupons:
        is_expired = code == "EXPIRED5" or random.random() < 0.15
        total_used = random.randint(0, max_uses)
        expiry = fake.date_between(start_date="-60d", end_date="-1d") if is_expired \
            else fake.date_between(start_date="+10d", end_date="+180d")

        rows.append({
            "coupon_code": code,
            "coupon_name": name,
            "discount_type": dtype,
            "discount_value": value,
            "min_order_amount": min_order,
            "max_uses": max_uses,
            "total_used": min(total_used, max_uses),
            "expiry_date": expiry,
            "active": "N" if is_expired else "Y"
        })

    df = pd.DataFrame(rows)
    save(df, "coupons.csv")
    return df


# ======================================================================
# TABLE 5: STAFF (Dimension)
# ======================================================================
def generate_staff():
    rows = []
    staff_id = 1

    departments = (
        [("Kitchen", "Head Chef")] * 1 +
        [("Kitchen", "Cook")] * 5 +
        [("Kitchen", "Kitchen Helper")] * 2 +
        [("Delivery", "Delivery Executive")] * 10 +
        [("Management", "Operations Manager")] * 1 +
        [("Management", "Founder/Owner")] * 1
    )

    for dept, role in departments:
        shift = random.choices(["Morning", "Evening", "Night"], weights=[40, 40, 20])[0]
        hire_date = fake.date_between(start_date="-2y", end_date="-1m")
        dob = fake.date_of_birth(minimum_age=20, maximum_age=45)

        if dept == "Kitchen":
            salary = round(random.uniform(12000, 22000), 2)
        elif dept == "Delivery":
            salary = round(random.uniform(10000, 18000), 2)
        else:
            salary = round(random.uniform(35000, 60000), 2)

        rows.append({
            "staff_id": staff_id,
            "staff_firstname": fake.first_name(),
            "staff_lastname": fake.last_name(),
            "phone_number": "9" + str(random.randint(100000000, 999999999)),
            "staff_address": fake.address().replace("\n", ", "),
            "staff_dob": dob,
            "staff_hiredate": hire_date,
            "department": dept,
            "role": role,
            "shift": shift,
            "salary": salary,
            "status": np.random.choice(["A", "I"], p=[0.9, 0.1])
        })
        staff_id += 1

    df = pd.DataFrame(rows)
    save(df, "staff.csv")
    return df


# ======================================================================
# TABLE 6: CUSTOMERS (Dimension)
# ======================================================================
def generate_customers(locations_df, n=500):
    rows = []
    channels = ["Instagram", "WhatsApp", "Gym Referral", "Organic Search"]
    channel_weights = [45, 25, 20, 10]

    # Weight signups toward more recent months (growth curve)
    signup_start = datetime(2026, 1, 1)
    signup_end = datetime(2026, 6, 30)
    days_range = (signup_end - signup_start).days

    # Saharanpur should get >50% of customers
    saharanpur_locs = locations_df[locations_df["city"] == "Saharanpur"]
    other_locs = locations_df[locations_df["city"] != "Saharanpur"]

    for i in range(1, n + 1):
        gender = np.random.choice(["Male", "Female"], p=[0.55, 0.45])
        first = fake.first_name_male() if gender == "Male" else fake.first_name_female()

        # Growth-weighted signup date: skew toward recent days
        skew = np.random.beta(2, 1)  # skews toward 1 (recent)
        signup_date = signup_start + timedelta(days=int(skew * days_range))

        # 55% Saharanpur, 45% other cities
        loc = saharanpur_locs.sample(1).iloc[0] if random.random() < 0.55 else other_locs.sample(1).iloc[0]

        rows.append({
            "customer_id": i,
            "customer_firstname": first,
            "customer_lastname": fake.last_name(),
            "phone_number": "9" + str(random.randint(100000000, 999999999)),
            "email_address": f"{first.lower()}{i}@gmail.com",
            "gender": gender,
            "dob": fake.date_of_birth(minimum_age=18, maximum_age=45),
            "city": loc["city"],
            "pincode": loc["pincode"],
            "main_address": fake.address().replace("\n", ", "),
            "delivery_address": fake.address().replace("\n", ", "),
            "meal_preference": np.random.choice(["Veg", "Non-Veg"], p=[0.55, 0.45]),
            "signup_date": signup_date.date(),
            "acquisition_channel": random.choices(channels, weights=channel_weights)[0]
        })

    df = pd.DataFrame(rows)
    save(df, "customers.csv")
    return df


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
# TABLE 10: BMI_LOGS (Fact)
# ======================================================================
def generate_bmi_logs(customers_df, n=800):
    rows = []
    today = datetime(2026, 6, 30)
    start = today - timedelta(days=180)

    for log_id in range(1, n + 1):
        is_registered = random.random() < 0.6
        customer_id = customers_df.sample(1).iloc[0]["customer_id"] if is_registered else None

        gender = np.random.choice(["Male", "Female"], p=[0.55, 0.45])
        age = random.randint(18, 50)
        height_cm = round(np.random.normal(170 if gender == "Male" else 158, 7), 2)
        height_cm = float(np.clip(height_cm, 145, 200))
        weight_kg = round(np.random.normal(72 if gender == "Male" else 60, 12), 2)
        weight_kg = float(np.clip(weight_kg, 40, 130))

        bmi_value = round(weight_kg / ((height_cm / 100) ** 2), 2)

        if bmi_value < 18.5:
            bmi_category = "Underweight"
        elif bmi_value < 25:
            bmi_category = "Normal"
        elif bmi_value < 30:
            bmi_category = "Overweight"
        else:
            bmi_category = "Obese"

        meal_viewed = np.random.choice(["Y", "N"], p=[0.7, 0.3])
        # Conversion only possible if they viewed suggestions.
        # Target: ~35% overall conversion rate -> since only 70% view suggestions,
        # conversion probability among viewers needs to be ~0.35/0.70 = 0.5
        converted = np.random.choice(["Y", "N"], p=[0.5, 0.5]) if meal_viewed == "Y" else "N"

        log_date = start + timedelta(days=random.randint(0, 180))

        rows.append({
            "log_id": log_id,
            "customer_id": customer_id,
            "record_date": log_date.date(),
            "age": age,
            "gender": gender,
            "height_cm": height_cm,
            "weight_kg": weight_kg,
            "activity_level": random.choices(
                ["Sedentary", "Lightly Active", "Moderately Active", "Very Active", "Extra Active"],
                weights=[15, 25, 35, 18, 7]
            )[0],
            "bmi_value": bmi_value,
            "bmi_category": bmi_category,
            "meal_suggestion_viewed": meal_viewed,
            "converted_to_order": converted
        })

    df = pd.DataFrame(rows)
    save(df, "bmi_logs.csv")
    return df


# ======================================================================
# TABLE 11: SUBSCRIPTIONS (Fact)
# ======================================================================
def generate_subscriptions(customers_df, orders_df, coupons_df, n=150):
    # Only customers with 3+ orders qualify as subscription candidates
    order_counts = orders_df.groupby("customer_id").size()
    eligible_customers = order_counts[order_counts >= 3].index.tolist()

    if len(eligible_customers) < n:
        n = len(eligible_customers)  # safety check

    chosen_customers = random.sample(eligible_customers, n)
    active_coupons = coupons_df["coupon_code"].tolist()

    cancellation_reasons = [
        "Too expensive", "Didn't like meal variety", "Achieved fitness goal",
        "Switching to competitor", "Delivery issues"
    ]

    rows = []
    today = datetime(2026, 6, 30)

    for i, cust_id in enumerate(chosen_customers, start=1):
        plan_type = random.choices(["Weekly", "Monthly"], weights=[60, 40])[0]
        meals_per_day = random.choices([1, 2], weights=[70, 30])[0]
        meal_pref = customers_df.loc[customers_df["customer_id"] == cust_id, "meal_preference"].values[0]

        purchase_date = today - timedelta(days=random.randint(5, 150))
        start_date = purchase_date + timedelta(days=random.randint(0, 2))

        if plan_type == "Weekly":
            duration = timedelta(weeks=random.randint(1, 8))
            amount = round(random.uniform(999, 1499), 2)
        else:
            duration = timedelta(days=30 * random.randint(1, 4))
            amount = round(random.uniform(3499, 5499), 2)

        end_date = start_date + duration

        status = random.choices(["Active", "Paused", "Cancelled"], weights=[55, 20, 25])[0]
        cancel_reason = random.choice(cancellation_reasons) if status == "Cancelled" else None

        use_coupon = random.random() < 0.25
        coupon_code = random.choice(active_coupons) if use_coupon else None

        rows.append({
            "subscription_id": i,
            "customer_id": cust_id,
            "coupon_code": coupon_code,
            "plan_type": plan_type,
            "meal_preference": meal_pref,
            "meals_per_day": meals_per_day,
            "purchase_date": purchase_date.date(),
            "start_date": start_date.date(),
            "end_date": end_date.date(),
            "amount": amount,
            "status": status,
            "cancellation_reason": cancel_reason,
            "auto_renewal": np.random.choice(["Y", "N"], p=[0.6, 0.4])
        })

    df = pd.DataFrame(rows)
    save(df, "subscriptions.csv")
    return df


# ======================================================================
# MAIN EXECUTION - Run all generators IN ORDER (respects FK dependencies)
# ======================================================================
if __name__ == "__main__":
    print("=" * 60)
    print("Generating RoyalProteinBowl Synthetic Dataset")
    print("=" * 60)

    calendar_df = generate_calendar()
    locations_df = generate_locations()
    item_master_df = generate_item_master()
    coupons_df = generate_coupons()
    staff_df = generate_staff()
    customers_df = generate_customers(locations_df, n=500)

    orders_df, order_items_df = generate_orders_and_items(
        customers_df, staff_df, coupons_df, locations_df, item_master_df, n_orders=3000
    )

    reviews_df = generate_reviews(orders_df)
    bmi_logs_df = generate_bmi_logs(customers_df, n=800)
    subscriptions_df = generate_subscriptions(customers_df, orders_df, coupons_df, n=150)

    print("=" * 60)
    print("✅ ALL 11 TABLES GENERATED SUCCESSFULLY")
    print(f"📁 Files saved to: {os.path.abspath(OUTPUT_DIR)}")
    print("=" * 60)

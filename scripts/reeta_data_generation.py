

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

     #TABLE 1: CALENDAR (Dimension)
# ======================================================================
def generate_calendar():
    start_date = datetime(2025, 1, 1)
    end_date = datetime(2026,  12, 31)
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

#TABLE 2: LOCATIONS (Dimension)
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
 #TABLE 5: STAFF (Dimension)
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
 #TABLE 10: BMI_LOGS (Fact)
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

#TABLE 11: SUBSCRIPTIONS (Fact)
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

if __name__ == "__main__":
    print("Generating Reeta's datasets...")

    generate_calendar()
    generate_locations()
    generate_staff()
    generate_coupons()
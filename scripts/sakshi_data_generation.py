# ======================================
# Import libraries
# ======================================
import pandas as pd
import numpy as np
from faker import Faker
import random
from datetime import datetime, timedelta
import os
# ----------------------------------------------------------------
# SETUP
# ----------------------------------------------------------------
fake = Faker('en_IN')
Faker.seed(42)
random.seed(42)
np.random.seed(42)

OUTPUT_DIR = "../data/raw"
os.makedirs(OUTPUT_DIR, exist_ok=True)

# ======================================================================
# TABLE 1: ITEM_MASTER (Dimension)
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

    if __name__ == "__main__":
        
    # Sakshi runs:
    generate_item_master()
    generate_customers()
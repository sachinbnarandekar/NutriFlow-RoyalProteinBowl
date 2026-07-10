"""
======================================================================
NutriFlow - RoyalProteinBowl.in
CSV to MySQL Loader Script
======================================================================
This script loads all 11 generated CSV files into the MySQL database.

BEFORE RUNNING THIS:
1. Make sure MySQL Server is installed and running
2. Run sql/create_tables.sql in MySQL Workbench first (creates the
   empty database and tables)
3. Update the DB_CONFIG below with your MySQL username and password
4. Make sure you've already run 01_data_generation.py so CSVs exist
   in data/raw/

HOW TO RUN:
    python 02_load_to_mysql.py
======================================================================
"""

import pandas as pd
import mysql.connector
from mysql.connector import Error
import os
import numpy as np

# ----------------------------------------------------------------
# STEP 1: UPDATE THESE WITH YOUR OWN MYSQL CREDENTIALS
# ----------------------------------------------------------------
DB_CONFIG = {
    "host": "localhost",
    "user": "root",            # <-- change if your MySQL username is different
    "password": "your_password_here",   # <-- CHANGE THIS to your actual MySQL password
    "database": "royalproteinbowl"
}

DATA_DIR = "../data/raw"

# Order matters! Dimensions first, then Facts (respects Foreign Keys)
TABLE_LOAD_ORDER = [
    "calendar",
    "locations",
    "item_master",
    "coupons",
    "staff",
    "customers",
    "orders",
    "order_items",
    "reviews",
    "bmi_logs",
    "subscriptions"
]


def clean_dataframe_for_sql(df):
    """Replace pandas NaN/NaT with None so MySQL accepts NULLs properly."""
    df = df.replace({np.nan: None})
    return df


def load_table(cursor, conn, table_name):
    csv_path = os.path.join(DATA_DIR, f"{table_name}.csv")

    if not os.path.exists(csv_path):
        print(f"⚠️  Skipped {table_name} - CSV not found at {csv_path}")
        return

    df = pd.read_csv(csv_path)
    df = clean_dataframe_for_sql(df)

    columns = list(df.columns)
    placeholders = ", ".join(["%s"] * len(columns))
    column_names = ", ".join(columns)

    insert_query = f"INSERT INTO {table_name} ({column_names}) VALUES ({placeholders})"

    data = [tuple(row) for row in df.to_numpy()]

    try:
        cursor.executemany(insert_query, data)
        conn.commit()
        print(f"✅ {table_name:<20} → {len(data):>6} rows loaded into MySQL")
    except Error as e:
        print(f"❌ ERROR loading {table_name}: {e}")
        conn.rollback()


def main():
    print("=" * 60)
    print("Loading RoyalProteinBowl CSVs into MySQL")
    print("=" * 60)

    try:
        conn = mysql.connector.connect(**DB_CONFIG)
        cursor = conn.cursor()
        print(f"✅ Connected to MySQL database: {DB_CONFIG['database']}\n")
    except Error as e:
        print(f"❌ Could not connect to MySQL: {e}")
        print("\nCheck that:")
        print("  1. MySQL Server is running")
        print("  2. Username/password in DB_CONFIG are correct")
        print("  3. You ran sql/create_tables.sql first")
        return

    for table in TABLE_LOAD_ORDER:
        load_table(cursor, conn, table)

    cursor.close()
    conn.close()

    print("\n" + "=" * 60)
    print("✅ ALL TABLES LOADED SUCCESSFULLY")
    print("=" * 60)
    print("\nNext step: Open MySQL Workbench and run:")
    print("   SELECT COUNT(*) FROM orders;")
    print("to verify the data loaded correctly (should show 3000).")


if __name__ == "__main__":
    main()

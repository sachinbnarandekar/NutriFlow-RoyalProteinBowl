-- ======================================================================
-- NutriFlow - RoyalProteinBowl.in
-- Verification Queries
-- ======================================================================
-- Run these AFTER loading data with 02_load_to_mysql.py to confirm
-- everything loaded correctly. Expected row counts are in comments.
-- ======================================================================

USE royalproteinbowl;

-- Expected: 730
SELECT COUNT(*) AS calendar_rows FROM calendar;

-- Expected: ~18-25 (depends on serviceable pincodes generated)
SELECT COUNT(*) AS location_rows FROM locations;

-- Expected: 35
SELECT COUNT(*) AS item_rows FROM item_master;

-- Expected: 15
SELECT COUNT(*) AS coupon_rows FROM coupons;

-- Expected: 20
SELECT COUNT(*) AS staff_rows FROM staff;

-- Expected: 500
SELECT COUNT(*) AS customer_rows FROM customers;

-- Expected: 3000
SELECT COUNT(*) AS order_rows FROM orders;

-- Expected: ~5500-5800
SELECT COUNT(*) AS order_item_rows FROM order_items;

-- Expected: ~1100-1300 (40% of delivered orders)
SELECT COUNT(*) AS review_rows FROM reviews;

-- Expected: 800
SELECT COUNT(*) AS bmi_log_rows FROM bmi_logs;

-- Expected: 150
SELECT COUNT(*) AS subscription_rows FROM subscriptions;


-- ----------------------------------------------------------------
-- A few quick business sanity checks
-- ----------------------------------------------------------------

-- Revenue should be a believable number for a 6-month-old food startup
SELECT ROUND(SUM(total_amount), 2) AS total_revenue FROM orders;

-- Top 5 bestselling items - should make business sense
SELECT 
    im.item_name,
    SUM(oi.item_quantity) AS total_quantity_sold,
    ROUND(SUM(oi.item_quantity * oi.item_price), 2) AS revenue
FROM order_items oi
JOIN item_master im ON oi.item_id = im.item_id
GROUP BY im.item_name
ORDER BY total_quantity_sold DESC
LIMIT 5;

-- City-wise customer distribution - Saharanpur should dominate
SELECT city, COUNT(*) AS customer_count
FROM customers
GROUP BY city
ORDER BY customer_count DESC;

-- Subscription status split - should roughly match 55/20/25
SELECT status, COUNT(*) AS count
FROM subscriptions
GROUP BY status;

-- BMI conversion rate - should be close to 35%
SELECT 
    ROUND(SUM(CASE WHEN converted_to_order = 'Y' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS conversion_rate_pct
FROM bmi_logs;

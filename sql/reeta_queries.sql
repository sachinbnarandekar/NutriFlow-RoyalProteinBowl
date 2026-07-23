-- ======================================================================
-- NutriFlow - RoyalProteinBowl.in
-- SQL Business Queries - Reeta
-- Modules: BMI Tool Conversion | Subscription Readiness & Retention
-- Database: royalproteinbowl (Aiven Cloud MySQL)
-- ======================================================================

USE royalproteinbowl;

-- ======================================================================
-- MODULE 4: BMI TOOL CONVERSION ANALYSIS
-- ======================================================================

-- -----------------------------------------------------------------------
-- SECTION 1: OVERALL BMI TOOL USAGE
-- -----------------------------------------------------------------------

-- Q1. How many people used the BMI tool?
-- Split between registered customers and guest users
SELECT
    CASE
        WHEN customer_id IS NOT NULL THEN 'Registered Customer'
        ELSE 'Guest User'
    END AS user_type,
    COUNT(*) AS total_sessions,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1) AS percentage
FROM bmi_logs
GROUP BY user_type;

-- -----------------------------------------------------------------------

-- Q2. What is the overall BMI-to-order conversion rate?
SELECT
    COUNT(*) AS total_bmi_sessions,
    SUM(CASE WHEN converted_to_order = 'Y' THEN 1 ELSE 0 END) AS converted,
    SUM(CASE WHEN converted_to_order = 'N' THEN 1 ELSE 0 END) AS not_converted,
    ROUND(SUM(CASE WHEN converted_to_order = 'Y' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS conversion_rate_pct
FROM bmi_logs;

-- -----------------------------------------------------------------------

-- Q3. Conversion rate — registered customers vs guest users
-- (Do registered customers convert better than guests?)
SELECT
    CASE
        WHEN customer_id IS NOT NULL THEN 'Registered Customer'
        ELSE 'Guest User'
    END AS user_type,
    COUNT(*) AS total_sessions,
    SUM(CASE WHEN converted_to_order = 'Y' THEN 1 ELSE 0 END) AS converted,
    ROUND(SUM(CASE WHEN converted_to_order = 'Y' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS conversion_rate_pct
FROM bmi_logs
GROUP BY user_type
ORDER BY conversion_rate_pct DESC;

-- -----------------------------------------------------------------------

-- SECTION 2: BMI CATEGORY ANALYSIS
-- -----------------------------------------------------------------------

-- Q4. What is the BMI category distribution among users?
SELECT
    bmi_category,
    COUNT(*) AS user_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1) AS percentage,
    ROUND(AVG(bmi_value), 2) AS avg_bmi_value
FROM bmi_logs
GROUP BY bmi_category
ORDER BY user_count DESC;

-- -----------------------------------------------------------------------

-- Q5. Which BMI category converts the most?
-- (Are overweight people more likely to order healthy meals?)
SELECT
    bmi_category,
    COUNT(*) AS total_sessions,
    SUM(CASE WHEN converted_to_order = 'Y' THEN 1 ELSE 0 END) AS converted,
    ROUND(SUM(CASE WHEN converted_to_order = 'Y' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS conversion_rate_pct
FROM bmi_logs
GROUP BY bmi_category
ORDER BY conversion_rate_pct DESC;

-- -----------------------------------------------------------------------

-- Q6. Average BMI value by age group
SELECT
    CASE
        WHEN age BETWEEN 18 AND 25 THEN '18-25'
        WHEN age BETWEEN 26 AND 35 THEN '26-35'
        WHEN age BETWEEN 36 AND 45 THEN '36-45'
        ELSE '45+'
    END AS age_group,
    COUNT(*) AS user_count,
    ROUND(AVG(bmi_value), 2) AS avg_bmi,
    ROUND(AVG(weight_kg), 2) AS avg_weight,
    ROUND(AVG(height_cm), 2) AS avg_height
FROM bmi_logs
GROUP BY age_group
ORDER BY age_group;

-- -----------------------------------------------------------------------

-- SECTION 3: MEAL SUGGESTION ENGAGEMENT
-- -----------------------------------------------------------------------

-- Q7. Do users who viewed meal suggestions convert more than those who did not?
SELECT
    meal_suggestion_viewed,
    CASE
        WHEN meal_suggestion_viewed = 'Y' THEN 'Viewed Suggestions'
        ELSE 'Did Not View'
    END AS view_status,
    COUNT(*) AS total_sessions,
    SUM(CASE WHEN converted_to_order = 'Y' THEN 1 ELSE 0 END) AS converted,
    ROUND(SUM(CASE WHEN converted_to_order = 'Y' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS conversion_rate_pct
FROM bmi_logs
GROUP BY meal_suggestion_viewed
ORDER BY conversion_rate_pct DESC;

-- -----------------------------------------------------------------------

-- Q8. Conversion funnel — BMI session → viewed suggestions → placed order
SELECT
    'Step 1: Used BMI Tool' AS funnel_stage,
    COUNT(*) AS user_count,
    100.0 AS percentage
FROM bmi_logs

UNION ALL

SELECT
    'Step 2: Viewed Meal Suggestions',
    COUNT(*),
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM bmi_logs), 1)
FROM bmi_logs
WHERE meal_suggestion_viewed = 'Y'

UNION ALL

SELECT
    'Step 3: Placed an Order',
    COUNT(*),
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM bmi_logs), 1)
FROM bmi_logs
WHERE converted_to_order = 'Y';

-- -----------------------------------------------------------------------

-- SECTION 4: DEMOGRAPHICS OF BMI USERS
-- -----------------------------------------------------------------------

-- Q9. Which gender uses the BMI tool more?
SELECT
    gender,
    COUNT(*) AS total_sessions,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1) AS percentage,
    ROUND(AVG(bmi_value), 2) AS avg_bmi,
    SUM(CASE WHEN converted_to_order = 'Y' THEN 1 ELSE 0 END) AS converted,
    ROUND(SUM(CASE WHEN converted_to_order = 'Y' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS conversion_rate_pct
FROM bmi_logs
GROUP BY gender
ORDER BY total_sessions DESC;

-- -----------------------------------------------------------------------

-- Q10. What is the most common activity level among BMI users?
SELECT
    activity_level,
    COUNT(*) AS user_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1) AS percentage,
    ROUND(AVG(bmi_value), 2) AS avg_bmi,
    SUM(CASE WHEN converted_to_order = 'Y' THEN 1 ELSE 0 END) AS converted,
    ROUND(SUM(CASE WHEN converted_to_order = 'Y' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS conversion_rate_pct
FROM bmi_logs
GROUP BY activity_level
ORDER BY user_count DESC;

-- -----------------------------------------------------------------------

-- Q11. BMI tool usage trend over time — is it growing?
SELECT
    cal.month_name,
    cal.month_number,
    cal.year,
    COUNT(b.log_id) AS total_sessions,
    SUM(CASE WHEN b.converted_to_order = 'Y' THEN 1 ELSE 0 END) AS conversions,
    ROUND(SUM(CASE WHEN b.converted_to_order = 'Y' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS conversion_rate_pct
FROM bmi_logs b
JOIN calendar cal ON b.record_date = cal.date
GROUP BY cal.month_name, cal.month_number, cal.year
ORDER BY cal.year, cal.month_number;

-- -----------------------------------------------------------------------

-- Q12. Are BMI users who converted actually ordering high-protein items?
-- (Validates if the BMI tool is driving the RIGHT kind of orders)
SELECT
    CASE
        WHEN b.converted_to_order = 'Y' THEN 'BMI Converted Customer'
        ELSE 'Regular Customer'
    END AS customer_type,
    ROUND(AVG(im.proteins_g), 2) AS avg_protein_per_item,
    ROUND(AVG(im.calories), 2) AS avg_calories_per_item,
    ROUND(AVG(oi.item_price), 2) AS avg_item_price
FROM bmi_logs b
JOIN customers c ON b.customer_id = c.customer_id
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
JOIN item_master im ON oi.item_id = im.item_id
WHERE b.customer_id IS NOT NULL
GROUP BY customer_type;


-- ======================================================================
-- MODULE 7: SUBSCRIPTION READINESS & RETENTION ANALYSIS
-- ======================================================================

-- -----------------------------------------------------------------------
-- SECTION 1: CURRENT SUBSCRIPTION OVERVIEW
-- -----------------------------------------------------------------------

-- Q13. What is the subscription status split?
SELECT
    status,
    COUNT(*) AS subscription_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1) AS percentage
FROM subscriptions
GROUP BY status
ORDER BY subscription_count DESC;

-- -----------------------------------------------------------------------

-- Q14. Which plan type is more popular — Weekly or Monthly?
SELECT
    plan_type,
    COUNT(*) AS subscription_count,
    ROUND(AVG(amount), 2) AS avg_subscription_amount,
    ROUND(SUM(amount), 2) AS total_revenue,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1) AS percentage
FROM subscriptions
GROUP BY plan_type
ORDER BY subscription_count DESC;

-- -----------------------------------------------------------------------

-- Q15. Revenue comparison — Weekly vs Monthly plans
SELECT
    plan_type,
    COUNT(*) AS total_subscriptions,
    ROUND(SUM(amount), 2) AS total_revenue,
    ROUND(AVG(amount), 2) AS avg_amount,
    ROUND(MIN(amount), 2) AS min_amount,
    ROUND(MAX(amount), 2) AS max_amount
FROM subscriptions
GROUP BY plan_type
ORDER BY total_revenue DESC;

-- -----------------------------------------------------------------------

-- Q16. Meal preference split in subscriptions — Veg vs Non-Veg
SELECT
    meal_preference,
    COUNT(*) AS subscription_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1) AS percentage,
    ROUND(AVG(amount), 2) AS avg_amount
FROM subscriptions
GROUP BY meal_preference
ORDER BY subscription_count DESC;

-- -----------------------------------------------------------------------

-- Q17. How many subscribers chose 1 meal per day vs 2 meals per day?
SELECT
    meals_per_day,
    COUNT(*) AS subscription_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1) AS percentage,
    ROUND(AVG(amount), 2) AS avg_amount
FROM subscriptions
GROUP BY meals_per_day
ORDER BY meals_per_day;

-- -----------------------------------------------------------------------

-- SECTION 2: CHURN ANALYSIS
-- -----------------------------------------------------------------------

-- Q18. What is the most common cancellation reason?
SELECT
    cancellation_reason,
    COUNT(*) AS cancellation_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1) AS percentage
FROM subscriptions
WHERE status = 'Cancelled'
AND cancellation_reason IS NOT NULL
GROUP BY cancellation_reason
ORDER BY cancellation_count DESC;

-- -----------------------------------------------------------------------

-- Q19. Churn rate by plan type
-- (Are weekly subscribers cancelling more than monthly?)
SELECT
    plan_type,
    COUNT(*) AS total_subscriptions,
    SUM(CASE WHEN status = 'Cancelled' THEN 1 ELSE 0 END) AS cancelled,
    SUM(CASE WHEN status = 'Paused' THEN 1 ELSE 0 END) AS paused,
    SUM(CASE WHEN status = 'Active' THEN 1 ELSE 0 END) AS active,
    ROUND(SUM(CASE WHEN status = 'Cancelled' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS churn_rate_pct,
    ROUND(SUM(CASE WHEN status = 'Paused' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS pause_rate_pct
FROM subscriptions
GROUP BY plan_type;

-- -----------------------------------------------------------------------

-- Q20. Paused-to-Cancelled pattern — early warning signal
-- (How many paused subscriptions eventually got cancelled?)
SELECT
    status,
    COUNT(*) AS count,
    ROUND(AVG(DATEDIFF(end_date, start_date)), 0) AS avg_subscription_duration_days,
    ROUND(AVG(amount), 2) AS avg_amount
FROM subscriptions
WHERE status IN ('Paused', 'Cancelled')
GROUP BY status;

-- -----------------------------------------------------------------------

-- Q21. Is auto-renewal linked to lower churn?
SELECT
    auto_renewal,
    CASE WHEN auto_renewal = 'Y' THEN 'Auto-Renewal ON' ELSE 'Auto-Renewal OFF' END AS renewal_status,
    COUNT(*) AS total_subscriptions,
    SUM(CASE WHEN status = 'Active' THEN 1 ELSE 0 END) AS active,
    SUM(CASE WHEN status = 'Cancelled' THEN 1 ELSE 0 END) AS cancelled,
    ROUND(SUM(CASE WHEN status = 'Cancelled' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS churn_rate_pct
FROM subscriptions
GROUP BY auto_renewal
ORDER BY churn_rate_pct ASC;

-- -----------------------------------------------------------------------

-- SECTION 3: SUBSCRIPTION CANDIDATES FROM EXISTING CUSTOMERS
-- -----------------------------------------------------------------------

-- Q22. Which existing one-time customers have ordering patterns
-- that match a subscription profile? (3+ orders in the data period)
SELECT
    c.customer_id,
    c.customer_firstname,
    c.customer_lastname,
    c.city,
    c.meal_preference,
    COUNT(o.order_id) AS total_orders,
    ROUND(SUM(o.total_amount), 2) AS total_spent,
    ROUND(AVG(o.total_amount), 2) AS avg_order_value,
    MIN(o.order_date) AS first_order,
    MAX(o.order_date) AS last_order,
    DATEDIFF(MAX(o.order_date), MIN(o.order_date)) AS days_as_customer
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
LEFT JOIN subscriptions s ON c.customer_id = s.customer_id
WHERE s.subscription_id IS NULL  -- only customers NOT already subscribed
GROUP BY c.customer_id, c.customer_firstname, c.customer_lastname,
         c.city, c.meal_preference
HAVING COUNT(o.order_id) >= 3
ORDER BY total_orders DESC;

-- -----------------------------------------------------------------------

-- Q23. How many subscription candidates exist vs how many already subscribed?
SELECT
    'Already Subscribed' AS category,
    COUNT(DISTINCT customer_id) AS customer_count
FROM subscriptions

UNION ALL

SELECT
    'Potential Candidates (3+ orders, not subscribed)',
    COUNT(*)
FROM (
    SELECT o.customer_id
    FROM orders o
    LEFT JOIN subscriptions s ON o.customer_id = s.customer_id
    WHERE s.subscription_id IS NULL
    GROUP BY o.customer_id
    HAVING COUNT(o.order_id) >= 3
) candidates;

-- -----------------------------------------------------------------------

-- SECTION 4: SEGMENT RECOMMENDATIONS
-- -----------------------------------------------------------------------

-- Q24. Which customer segment should the founder target first for
-- subscription launch? (By city, meal preference, acquisition channel)
SELECT
    c.city,
    c.meal_preference,
    c.acquisition_channel,
    COUNT(DISTINCT c.customer_id) AS candidate_count,
    ROUND(AVG(order_data.total_orders), 1) AS avg_orders,
    ROUND(AVG(order_data.total_spent), 2) AS avg_total_spent
FROM customers c
JOIN (
    SELECT
        customer_id,
        COUNT(order_id) AS total_orders,
        SUM(total_amount) AS total_spent
    FROM orders
    GROUP BY customer_id
    HAVING COUNT(order_id) >= 3
) order_data ON c.customer_id = order_data.customer_id
LEFT JOIN subscriptions s ON c.customer_id = s.customer_id
WHERE s.subscription_id IS NULL
GROUP BY c.city, c.meal_preference, c.acquisition_channel
HAVING candidate_count >= 3
ORDER BY candidate_count DESC, avg_total_spent DESC;

-- -----------------------------------------------------------------------

-- Q25. Revenue comparison — predicted subscription revenue vs
-- current one-time order revenue from the same customer base
SELECT
    'Current One-Time Revenue' AS revenue_type,
    COUNT(DISTINCT o.customer_id) AS customer_count,
    ROUND(SUM(o.total_amount), 2) AS total_revenue,
    ROUND(AVG(o.total_amount), 2) AS avg_per_order
FROM orders o
WHERE o.customer_id IN (SELECT customer_id FROM subscriptions)

UNION ALL

SELECT
    'Subscription Revenue' AS revenue_type,
    COUNT(DISTINCT customer_id),
    ROUND(SUM(amount), 2),
    ROUND(AVG(amount), 2)
FROM subscriptions;

-- -----------------------------------------------------------------------

-- Q26. Subscription performance by coupon usage
-- (Do subscribers who used a coupon churn more or less?)
SELECT
    CASE
        WHEN s.coupon_code IS NOT NULL THEN 'Used Coupon'
        ELSE 'No Coupon'
    END AS coupon_usage,
    COUNT(*) AS total_subscriptions,
    SUM(CASE WHEN s.status = 'Active' THEN 1 ELSE 0 END) AS active,
    SUM(CASE WHEN s.status = 'Cancelled' THEN 1 ELSE 0 END) AS cancelled,
    ROUND(SUM(CASE WHEN s.status = 'Cancelled' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS churn_rate_pct,
    ROUND(AVG(s.amount), 2) AS avg_subscription_amount
FROM subscriptions s
GROUP BY coupon_usage
ORDER BY churn_rate_pct ASC;

-- -----------------------------------------------------------------------

-- Q27. Average subscription duration by status
-- (How long do active subscribers stay vs how quickly do cancelled ones leave?)
SELECT
    status,
    COUNT(*) AS count,
    ROUND(AVG(DATEDIFF(end_date, start_date)), 0) AS avg_duration_days,
    ROUND(MIN(DATEDIFF(end_date, start_date)), 0) AS min_duration_days,
    ROUND(MAX(DATEDIFF(end_date, start_date)), 0) AS max_duration_days
FROM subscriptions
GROUP BY status
ORDER BY avg_duration_days DESC;

-- ======================================================================
-- END OF REETA'S QUERIES
-- ======================================================================

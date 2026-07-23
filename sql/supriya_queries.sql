-- ======================================================================
-- NutriFlow - RoyalProteinBowl.in
-- SQL Business Queries - Supriya
-- Modules: Coupon Analysis | Delivery Performance | Review Sentiment
-- Database: royalproteinbowl (Aiven Cloud MySQL)
-- ======================================================================

USE royalproteinbowl;

-- ======================================================================
-- MODULE 3: COUPON & DISCOUNT ANALYSIS
-- ======================================================================

-- -----------------------------------------------------------------------
-- SECTION 1: COUPON USAGE ANALYSIS
-- -----------------------------------------------------------------------

-- Q1. How many coupons were never used at all?
SELECT
    coupon_code,
    coupon_name,
    discount_type,
    discount_value,
    max_uses,
    total_used,
    active
FROM coupons
WHERE total_used = 0
ORDER BY coupon_name;

-- -----------------------------------------------------------------------

-- Q2. Which are the most used coupons ranked by usage count?
SELECT
    coupon_code,
    coupon_name,
    discount_type,
    discount_value,
    total_used,
    max_uses,
    ROUND((total_used * 100.0 / max_uses), 1) AS usage_pct
FROM coupons
WHERE total_used > 0
ORDER BY total_used DESC;

-- -----------------------------------------------------------------------

-- Q3. What is the total_used ratio to max_uses compared across all coupons?
-- (Coupon velocity — how efficiently each coupon was consumed)
SELECT
    coupon_code,
    coupon_name,
    discount_type,
    total_used,
    max_uses,
    ROUND((total_used * 100.0 / max_uses), 1) AS consumption_rate_pct,
    DATEDIFF(expiry_date, CURDATE()) AS days_until_expiry,
    CASE
        WHEN (total_used * 100.0 / max_uses) >= 80 THEN 'High Performer'
        WHEN (total_used * 100.0 / max_uses) >= 40 THEN 'Moderate Performer'
        ELSE 'Low Performer'
    END AS performance_category
FROM coupons
ORDER BY consumption_rate_pct DESC;

-- -----------------------------------------------------------------------

-- Q4. Do customers prefer flat amount or percentage discounts?
SELECT
    c.discount_type,
    COUNT(o.order_id) AS total_orders_with_coupon,
    ROUND(AVG(o.total_amount), 2) AS avg_order_value,
    ROUND(SUM(o.total_amount), 2) AS total_revenue
FROM orders o
JOIN coupons c ON o.coupon_code = c.coupon_code
GROUP BY c.discount_type
ORDER BY total_orders_with_coupon DESC;

-- -----------------------------------------------------------------------

-- Q5. Which are active vs inactive coupons
-- and which inactive ones were high performers worth reactivating?
SELECT
    coupon_code,
    coupon_name,
    discount_type,
    discount_value,
    total_used,
    max_uses,
    active,
    expiry_date,
    ROUND((total_used * 100.0 / max_uses), 1) AS usage_rate_pct,
    CASE
        WHEN active = 'Y' THEN 'Currently Active'
        WHEN active = 'N' AND (total_used * 100.0 / max_uses) >= 70
            THEN 'Inactive - Consider Reactivating'
        WHEN active = 'N' AND (total_used * 100.0 / max_uses) < 70
            THEN 'Inactive - Low Performance'
        ELSE 'Review Required'
    END AS reactivation_recommendation
FROM coupons
ORDER BY active DESC, usage_rate_pct DESC;

-- -----------------------------------------------------------------------

-- SECTION 2: CUSTOMER ANALYSIS
-- -----------------------------------------------------------------------

-- Q6. How many repeat customers used coupons vs fresh (first-time) customers?
SELECT
    customer_type,
    COUNT(*) AS customer_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1) AS percentage
FROM (
    SELECT
        o.customer_id,
        CASE
            WHEN COUNT(o.order_id) = 1 THEN 'Fresh Customer'
            ELSE 'Repeat Customer'
        END AS customer_type
    FROM orders o
    WHERE o.coupon_code IS NOT NULL
    GROUP BY o.customer_id
) customer_types
GROUP BY customer_type;

-- -----------------------------------------------------------------------

-- Q7. Did promotions bring in more customers?
-- Compare order volume in coupon-active months vs non-coupon months
SELECT
    cal.month_name,
    cal.month_number,
    COUNT(o.order_id) AS total_orders,
    SUM(CASE WHEN o.coupon_code IS NOT NULL THEN 1 ELSE 0 END) AS coupon_orders,
    SUM(CASE WHEN o.coupon_code IS NULL THEN 1 ELSE 0 END) AS non_coupon_orders,
    ROUND(SUM(CASE WHEN o.coupon_code IS NOT NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS coupon_usage_rate_pct
FROM orders o
JOIN calendar cal ON o.order_date = cal.date
GROUP BY cal.month_name, cal.month_number
ORDER BY cal.month_number;

-- -----------------------------------------------------------------------

-- Q8. Was coupon usage higher during festive seasons or holidays?
SELECT
    cal.is_holiday,
    cal.is_weekend,
    COUNT(o.order_id) AS total_orders,
    SUM(CASE WHEN o.coupon_code IS NOT NULL THEN 1 ELSE 0 END) AS coupon_orders,
    ROUND(SUM(CASE WHEN o.coupon_code IS NOT NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS coupon_rate_pct,
    ROUND(AVG(o.total_amount), 2) AS avg_order_value
FROM orders o
JOIN calendar cal ON o.order_date = cal.date
GROUP BY cal.is_holiday, cal.is_weekend
ORDER BY coupon_rate_pct DESC;

-- -----------------------------------------------------------------------

-- Q9. What age group and gender uses coupons the most?
SELECT
    c.gender,
    CASE
        WHEN TIMESTAMPDIFF(YEAR, c.dob, CURDATE()) BETWEEN 18 AND 25 THEN '18-25'
        WHEN TIMESTAMPDIFF(YEAR, c.dob, CURDATE()) BETWEEN 26 AND 35 THEN '26-35'
        WHEN TIMESTAMPDIFF(YEAR, c.dob, CURDATE()) BETWEEN 36 AND 45 THEN '36-45'
        ELSE '45+'
    END AS age_group,
    COUNT(o.order_id) AS coupon_orders,
    ROUND(AVG(o.total_amount), 2) AS avg_order_value,
    ROUND(SUM(o.total_amount), 2) AS total_revenue
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.coupon_code IS NOT NULL
GROUP BY c.gender, age_group
ORDER BY coupon_orders DESC;

-- -----------------------------------------------------------------------

-- SECTION 3: BUSINESS DECISIONS
-- -----------------------------------------------------------------------

-- Q10. What is the sale amount and effective profit/loss per coupon?
-- (Revenue generated vs discount given)
SELECT
    cp.coupon_code,
    cp.coupon_name,
    cp.discount_type,
    cp.discount_value,
    COUNT(o.order_id) AS times_used,
    ROUND(SUM(o.total_amount), 2) AS revenue_after_discount,
    ROUND(
        SUM(
            CASE
                WHEN cp.discount_type = 'Percentage'
                    THEN (o.total_amount / (1 - cp.discount_value / 100)) * (cp.discount_value / 100)
                ELSE cp.discount_value
            END
        ), 2
    ) AS total_discount_given,
    ROUND(
        SUM(o.total_amount) +
        SUM(
            CASE
                WHEN cp.discount_type = 'Percentage'
                    THEN (o.total_amount / (1 - cp.discount_value / 100)) * (cp.discount_value / 100)
                ELSE cp.discount_value
            END
        ), 2
    ) AS gross_revenue_before_discount
FROM orders o
JOIN coupons cp ON o.coupon_code = cp.coupon_code
GROUP BY cp.coupon_code, cp.coupon_name, cp.discount_type, cp.discount_value
ORDER BY total_discount_given DESC;

-- -----------------------------------------------------------------------

-- Q11. Overall coupon redemption rate
-- (What percentage of all orders used a coupon?)
SELECT
    COUNT(*) AS total_orders,
    SUM(CASE WHEN coupon_code IS NOT NULL THEN 1 ELSE 0 END) AS orders_with_coupon,
    SUM(CASE WHEN coupon_code IS NULL THEN 1 ELSE 0 END) AS orders_without_coupon,
    ROUND(SUM(CASE WHEN coupon_code IS NOT NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS redemption_rate_pct
FROM orders;

-- -----------------------------------------------------------------------

-- Q12. Average order value with coupon vs without coupon
SELECT
    CASE
        WHEN coupon_code IS NOT NULL THEN 'With Coupon'
        ELSE 'Without Coupon'
    END AS order_type,
    COUNT(*) AS total_orders,
    ROUND(AVG(total_amount), 2) AS avg_order_value,
    ROUND(SUM(total_amount), 2) AS total_revenue
FROM orders
GROUP BY order_type
ORDER BY avg_order_value DESC;

-- -----------------------------------------------------------------------

-- Q13. Do weekend orders use more coupons than weekday orders?
SELECT
    cal.is_weekend,
    CASE WHEN cal.is_weekend = 'Y' THEN 'Weekend' ELSE 'Weekday' END AS day_type,
    COUNT(o.order_id) AS total_orders,
    SUM(CASE WHEN o.coupon_code IS NOT NULL THEN 1 ELSE 0 END) AS coupon_orders,
    ROUND(SUM(CASE WHEN o.coupon_code IS NOT NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS coupon_rate_pct,
    ROUND(AVG(o.total_amount), 2) AS avg_order_value
FROM orders o
JOIN calendar cal ON o.order_date = cal.date
GROUP BY cal.is_weekend
ORDER BY coupon_rate_pct DESC;


-- ======================================================================
-- MODULE 5: DELIVERY PERFORMANCE ANALYSIS
-- ======================================================================

-- -----------------------------------------------------------------------
-- LAYER 1: SCALE OF THE PROBLEM
-- -----------------------------------------------------------------------

-- Q14. How many deliveries were on time vs late?
-- For late ones, what is the average percentage overtime?
SELECT
    COUNT(*) AS total_deliveries,
    SUM(CASE WHEN actual_delivery_time <= 45 THEN 1 ELSE 0 END) AS on_time,
    SUM(CASE WHEN actual_delivery_time > 45 THEN 1 ELSE 0 END) AS late,
    ROUND(SUM(CASE WHEN actual_delivery_time <= 45 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS on_time_pct,
    ROUND(SUM(CASE WHEN actual_delivery_time > 45 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS late_pct,
    ROUND(AVG(CASE WHEN actual_delivery_time > 45
        THEN ((actual_delivery_time - 45) * 100.0 / 45)
        ELSE NULL END), 1) AS avg_percentage_overtime
FROM orders
WHERE delivery_status = 'Delivered';

-- -----------------------------------------------------------------------

-- Q15. What is the overall average delivery time?
SELECT
    ROUND(AVG(actual_delivery_time), 2) AS avg_delivery_time_mins,
    MIN(actual_delivery_time) AS fastest_delivery_mins,
    MAX(actual_delivery_time) AS slowest_delivery_mins,
    45 AS promised_delivery_time_mins
FROM orders
WHERE delivery_status = 'Delivered';

-- -----------------------------------------------------------------------

-- LAYER 2: WHEN DOES IT HAPPEN
-- -----------------------------------------------------------------------

-- Q16. Delivery performance by time of day
-- (Morning, Afternoon, Evening, Other)
SELECT
    order_time,
    COUNT(*) AS total_orders,
    SUM(CASE WHEN actual_delivery_time <= 45 THEN 1 ELSE 0 END) AS on_time,
    SUM(CASE WHEN actual_delivery_time > 45 THEN 1 ELSE 0 END) AS late,
    ROUND(SUM(CASE WHEN actual_delivery_time <= 45 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS on_time_pct,
    ROUND(SUM(CASE WHEN actual_delivery_time > 45 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS late_pct,
    ROUND(AVG(actual_delivery_time), 1) AS avg_delivery_time
FROM orders
WHERE delivery_status = 'Delivered'
GROUP BY order_time
ORDER BY late_pct DESC;

-- -----------------------------------------------------------------------

-- Q17. Is delivery worse on weekdays, weekends, holidays or festive seasons?
SELECT
    cal.is_weekend,
    cal.is_holiday,
    cal.month_name,
    COUNT(o.order_id) AS total_orders,
    SUM(CASE WHEN o.actual_delivery_time > 45 THEN 1 ELSE 0 END) AS late_orders,
    ROUND(SUM(CASE WHEN o.actual_delivery_time > 45 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS late_pct,
    ROUND(AVG(o.actual_delivery_time), 1) AS avg_delivery_time
FROM orders o
JOIN calendar cal ON o.order_date = cal.date
WHERE o.delivery_status = 'Delivered'
GROUP BY cal.is_weekend, cal.is_holiday, cal.month_name
ORDER BY late_pct DESC;

-- -----------------------------------------------------------------------

-- LAYER 3: WHERE DOES IT HAPPEN
-- -----------------------------------------------------------------------

-- Q18. Which pincode has the most delivery delays?
SELECT
    o.delivery_pincode,
    l.city,
    l.delivery_zone,
    COUNT(o.order_id) AS total_orders,
    SUM(CASE WHEN o.actual_delivery_time > 45 THEN 1 ELSE 0 END) AS late_orders,
    ROUND(SUM(CASE WHEN o.actual_delivery_time > 45 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS late_pct,
    ROUND(AVG(o.actual_delivery_time), 1) AS avg_delivery_time
FROM orders o
JOIN locations l ON o.delivery_pincode = l.pincode
WHERE o.delivery_status = 'Delivered'
GROUP BY o.delivery_pincode, l.city, l.delivery_zone
ORDER BY late_pct DESC
LIMIT 10;

-- -----------------------------------------------------------------------

-- LAYER 4: WHO IS INVOLVED
-- -----------------------------------------------------------------------

-- Q19. Which staff member has the most late deliveries?
-- And is it because of the pincode they deliver to or their own performance?
SELECT
    s.staff_id,
    s.staff_firstname,
    s.staff_lastname,
    s.shift,
    o.delivery_pincode,
    l.city,
    l.delivery_zone,
    COUNT(o.order_id) AS total_deliveries,
    SUM(CASE WHEN o.actual_delivery_time > 45 THEN 1 ELSE 0 END) AS late_deliveries,
    ROUND(SUM(CASE WHEN o.actual_delivery_time > 45 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS late_pct,
    ROUND(AVG(o.actual_delivery_time), 1) AS avg_delivery_time
FROM orders o
JOIN staff s ON o.staff_id = s.staff_id
JOIN locations l ON o.delivery_pincode = l.pincode
WHERE o.delivery_status = 'Delivered'
AND s.department = 'Delivery'
GROUP BY s.staff_id, s.staff_firstname, s.staff_lastname, s.shift, o.delivery_pincode, l.city, l.delivery_zone
ORDER BY late_pct DESC;

-- -----------------------------------------------------------------------

-- Q20. Is any specific customer always receiving late deliveries?
-- (May indicate difficult location or access issues)
SELECT
    c.customer_id,
    c.customer_firstname,
    c.customer_lastname,
    c.delivery_address,
    c.city,
    COUNT(o.order_id) AS total_orders,
    SUM(CASE WHEN o.actual_delivery_time > 45 THEN 1 ELSE 0 END) AS late_deliveries,
    ROUND(SUM(CASE WHEN o.actual_delivery_time > 45 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS late_pct,
    ROUND(AVG(o.actual_delivery_time), 1) AS avg_delivery_time
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.delivery_status = 'Delivered'
GROUP BY c.customer_id, c.customer_firstname, c.customer_lastname,
         c.delivery_address, c.city
HAVING late_deliveries > 2
ORDER BY late_pct DESC;

-- -----------------------------------------------------------------------

-- LAYER 5: WHY DOES IT HAPPEN
-- -----------------------------------------------------------------------

-- Q21. Is the payment method (COD vs UPI) causing delivery delays?
-- COD requires cash collection which may take longer
SELECT
    payment_method,
    COUNT(*) AS total_orders,
    SUM(CASE WHEN actual_delivery_time > 45 THEN 1 ELSE 0 END) AS late_orders,
    ROUND(SUM(CASE WHEN actual_delivery_time > 45 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS late_pct,
    ROUND(AVG(actual_delivery_time), 2) AS avg_delivery_time,
    SUM(CASE WHEN delivery_status = 'Cancelled' THEN 1 ELSE 0 END) AS cancellations
FROM orders
GROUP BY payment_method
ORDER BY avg_delivery_time DESC;

-- -----------------------------------------------------------------------

-- Q22. Is a delivery person handling multiple orders in the same time slot
-- causing delays? (Approximation — same staff, same date, same time bucket)
SELECT
    o.staff_id,
    s.staff_firstname,
    s.staff_lastname,
    o.order_date,
    o.order_time,
    COUNT(o.order_id) AS orders_in_same_slot,
    ROUND(AVG(o.actual_delivery_time), 1) AS avg_delivery_time,
    SUM(CASE WHEN o.actual_delivery_time > 45 THEN 1 ELSE 0 END) AS late_in_slot
FROM orders o
JOIN staff s ON o.staff_id = s.staff_id
WHERE o.delivery_status = 'Delivered'
GROUP BY o.staff_id, s.staff_firstname, s.staff_lastname, o.order_date, o.order_time
HAVING COUNT(o.order_id) > 1
ORDER BY avg_delivery_time DESC;

-- Note: This is an approximation. Our dataset does not track exact
-- concurrent delivery times. High avg_delivery_time with multiple
-- orders in the same slot suggests workload may be a contributing factor.


-- ======================================================================
-- MODULE 6: REVIEW & SENTIMENT ANALYSIS
-- ======================================================================

-- Q23. What is the overall average rating?
SELECT
    ROUND(AVG(overall_rating), 2) AS avg_overall_rating,
    ROUND(AVG(delivery_rating), 2) AS avg_delivery_rating,
    ROUND(AVG(taste_rating), 2) AS avg_taste_rating,
    ROUND(AVG(portion_rating), 2) AS avg_portion_rating,
    COUNT(*) AS total_reviews
FROM reviews
WHERE status = 'Approved';

-- -----------------------------------------------------------------------

-- Q24. How are ratings distributed across 1 to 5 stars?
SELECT
    overall_rating AS star_rating,
    COUNT(*) AS review_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1) AS percentage
FROM reviews
WHERE status = 'Approved'
GROUP BY overall_rating
ORDER BY overall_rating DESC;

-- -----------------------------------------------------------------------

-- Q25. Which menu item gets the lowest average taste rating?
SELECT
    im.item_name,
    im.item_category,
    im.food_category,
    COUNT(r.review_id) AS total_reviews,
    ROUND(AVG(r.taste_rating), 2) AS avg_taste_rating,
    ROUND(AVG(r.overall_rating), 2) AS avg_overall_rating
FROM reviews r
JOIN orders o ON r.order_id = o.order_id
JOIN order_items oi ON o.order_id = oi.order_id
JOIN item_master im ON oi.item_id = im.item_id
WHERE r.status = 'Approved'
GROUP BY im.item_id, im.item_name, im.item_category, im.food_category
HAVING COUNT(r.review_id) >= 3
ORDER BY avg_taste_rating ASC
LIMIT 10;

-- -----------------------------------------------------------------------

-- Q26. Do late deliveries result in lower overall ratings?
SELECT
    CASE
        WHEN o.actual_delivery_time <= 45 THEN 'On Time'
        ELSE 'Late'
    END AS delivery_status_type,
    COUNT(r.review_id) AS total_reviews,
    ROUND(AVG(r.overall_rating), 2) AS avg_overall_rating,
    ROUND(AVG(r.delivery_rating), 2) AS avg_delivery_rating,
    ROUND(AVG(r.taste_rating), 2) AS avg_taste_rating
FROM reviews r
JOIN orders o ON r.order_id = o.order_id
WHERE r.status = 'Approved'
AND o.delivery_status = 'Delivered'
GROUP BY delivery_status_type
ORDER BY avg_overall_rating DESC;

-- -----------------------------------------------------------------------

-- Q27. What is the review approval rate — Approved vs Pending?
SELECT
    status,
    COUNT(*) AS review_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1) AS percentage
FROM reviews
GROUP BY status;

-- -----------------------------------------------------------------------

-- Q28. Has the average rating improved or declined over time?
-- (Month wise rating trend)
SELECT
    cal.month_name,
    cal.month_number,
    cal.year,
    COUNT(r.review_id) AS total_reviews,
    ROUND(AVG(r.overall_rating), 2) AS avg_rating,
    ROUND(AVG(r.delivery_rating), 2) AS avg_delivery_rating,
    ROUND(AVG(r.taste_rating), 2) AS avg_taste_rating
FROM reviews r
JOIN calendar cal ON r.review_date = cal.date
WHERE r.status = 'Approved'
GROUP BY cal.month_name, cal.month_number, cal.year
ORDER BY cal.year, cal.month_number;

-- -----------------------------------------------------------------------

-- Q29. What is the root cause of low ratings?
-- Compare delivery, taste, and portion ratings for 1 and 2 star reviews
SELECT
    overall_rating,
    COUNT(*) AS review_count,
    ROUND(AVG(delivery_rating), 2) AS avg_delivery_rating,
    ROUND(AVG(taste_rating), 2) AS avg_taste_rating,
    ROUND(AVG(portion_rating), 2) AS avg_portion_rating,
    CASE
        WHEN AVG(delivery_rating) < AVG(taste_rating)
         AND AVG(delivery_rating) < AVG(portion_rating)
            THEN 'Delivery is main issue'
        WHEN AVG(taste_rating) < AVG(delivery_rating)
         AND AVG(taste_rating) < AVG(portion_rating)
            THEN 'Taste is main issue'
        ELSE 'Portion size is main issue'
    END AS root_cause
FROM reviews
WHERE overall_rating <= 2
AND status = 'Approved'
GROUP BY overall_rating
ORDER BY overall_rating;

-- ======================================================================
-- END OF SUPRIYA'S QUERIES
-- ======================================================================

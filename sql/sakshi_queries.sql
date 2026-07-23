-- ======================================================================
-- NutriFlow - RoyalProteinBowl.in
-- SQL Business Queries - Sakshi
-- Modules: Customer Behavior | Menu Performance
-- Database: royalproteinbowl (Aiven Cloud MySQL)
-- ======================================================================

USE royalproteinbowl;

-- ======================================================================
-- MODULE 1: CUSTOMER BEHAVIOR ANALYSIS
-- ======================================================================

-- -----------------------------------------------------------------------
-- SECTION 1: REPEAT VS ONE-TIME BUYERS
-- -----------------------------------------------------------------------

-- Q1. How many customers are repeat buyers vs one-time buyers?
SELECT
    customer_type,
    COUNT(*) AS customer_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1) AS percentage
FROM (
    SELECT
        c.customer_id,
        CASE
            WHEN COUNT(o.order_id) = 1 THEN 'One-Time Buyer'
            WHEN COUNT(o.order_id) BETWEEN 2 AND 5 THEN 'Repeat Buyer'
            WHEN COUNT(o.order_id) > 5 THEN 'Loyal Customer'
            ELSE 'No Orders'
        END AS customer_type
    FROM customers c
    LEFT JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id
) customer_segments
GROUP BY customer_type
ORDER BY customer_count DESC;

-- -----------------------------------------------------------------------

-- Q2. What is the order frequency distribution?
-- (How many customers ordered 1 time, 2 times, 3 times, etc.)
SELECT
    order_count,
    COUNT(*) AS number_of_customers,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1) AS percentage
FROM (
    SELECT
        customer_id,
        COUNT(order_id) AS order_count
    FROM orders
    GROUP BY customer_id
) order_freq
GROUP BY order_count
ORDER BY order_count;

-- -----------------------------------------------------------------------

-- Q3. Who are the top 10 most valuable customers by total spending?
SELECT
    c.customer_id,
    c.customer_firstname,
    c.customer_lastname,
    c.city,
    c.meal_preference,
    c.acquisition_channel,
    COUNT(o.order_id) AS total_orders,
    ROUND(SUM(o.total_amount), 2) AS total_spent,
    ROUND(AVG(o.total_amount), 2) AS avg_order_value,
    MIN(o.order_date) AS first_order,
    MAX(o.order_date) AS last_order
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_firstname, c.customer_lastname,
         c.city, c.meal_preference, c.acquisition_channel
ORDER BY total_spent DESC
LIMIT 10;

-- -----------------------------------------------------------------------

-- SECTION 2: ACQUISITION CHANNEL ANALYSIS
-- -----------------------------------------------------------------------

-- Q4. Which acquisition channel brings the most customers?
SELECT
    acquisition_channel,
    COUNT(*) AS customer_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1) AS percentage
FROM customers
GROUP BY acquisition_channel
ORDER BY customer_count DESC;

-- -----------------------------------------------------------------------

-- Q5. Which acquisition channel brings the highest value customers?
-- (Not just count, but actual revenue per channel)
SELECT
    c.acquisition_channel,
    COUNT(DISTINCT c.customer_id) AS customer_count,
    COUNT(o.order_id) AS total_orders,
    ROUND(SUM(o.total_amount), 2) AS total_revenue,
    ROUND(SUM(o.total_amount) / COUNT(DISTINCT c.customer_id), 2) AS revenue_per_customer,
    ROUND(AVG(o.total_amount), 2) AS avg_order_value
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.acquisition_channel
ORDER BY revenue_per_customer DESC;

-- -----------------------------------------------------------------------

-- Q6. What is the repeat rate per acquisition channel?
-- (Which channel brings customers who come back?)
SELECT
    c.acquisition_channel,
    COUNT(DISTINCT c.customer_id) AS total_customers,
    SUM(CASE WHEN order_counts.order_count > 1 THEN 1 ELSE 0 END) AS repeat_customers,
    ROUND(SUM(CASE WHEN order_counts.order_count > 1 THEN 1 ELSE 0 END) * 100.0 /
          COUNT(DISTINCT c.customer_id), 1) AS repeat_rate_pct
FROM customers c
JOIN (
    SELECT customer_id, COUNT(*) AS order_count
    FROM orders
    GROUP BY customer_id
) order_counts ON c.customer_id = order_counts.customer_id
GROUP BY c.acquisition_channel
ORDER BY repeat_rate_pct DESC;

-- -----------------------------------------------------------------------

-- SECTION 3: GEOGRAPHIC ANALYSIS
-- -----------------------------------------------------------------------

-- Q7. Which city has the most orders and revenue?
SELECT
    c.city,
    COUNT(DISTINCT c.customer_id) AS customer_count,
    COUNT(o.order_id) AS total_orders,
    ROUND(SUM(o.total_amount), 2) AS total_revenue,
    ROUND(AVG(o.total_amount), 2) AS avg_order_value
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.city
ORDER BY total_revenue DESC;

-- -----------------------------------------------------------------------

-- Q8. Which pincode has the highest order density?
SELECT
    o.delivery_pincode,
    l.city,
    l.delivery_zone,
    COUNT(o.order_id) AS total_orders,
    ROUND(SUM(o.total_amount), 2) AS total_revenue,
    ROUND(AVG(o.total_amount), 2) AS avg_order_value
FROM orders o
JOIN locations l ON o.delivery_pincode = l.pincode
GROUP BY o.delivery_pincode, l.city, l.delivery_zone
ORDER BY total_orders DESC;

-- -----------------------------------------------------------------------

-- SECTION 4: TIME-BASED ORDERING PATTERNS
-- -----------------------------------------------------------------------

-- Q9. What time of day gets the most orders?
SELECT
    order_time,
    COUNT(*) AS total_orders,
    ROUND(SUM(total_amount), 2) AS total_revenue,
    ROUND(AVG(total_amount), 2) AS avg_order_value,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1) AS percentage
FROM orders
GROUP BY order_time
ORDER BY total_orders DESC;

-- -----------------------------------------------------------------------

-- Q10. Which day of the week gets the most orders?
SELECT
    cal.day_name,
    COUNT(o.order_id) AS total_orders,
    ROUND(SUM(o.total_amount), 2) AS total_revenue,
    ROUND(AVG(o.total_amount), 2) AS avg_order_value
FROM orders o
JOIN calendar cal ON o.order_date = cal.date
GROUP BY cal.day_name
ORDER BY total_orders DESC;

-- -----------------------------------------------------------------------

-- Q11. Are weekends busier than weekdays?
SELECT
    CASE WHEN cal.is_weekend = 'Y' THEN 'Weekend' ELSE 'Weekday' END AS day_type,
    COUNT(o.order_id) AS total_orders,
    ROUND(SUM(o.total_amount), 2) AS total_revenue,
    ROUND(AVG(o.total_amount), 2) AS avg_order_value,
    ROUND(COUNT(o.order_id) * 100.0 / SUM(COUNT(o.order_id)) OVER(), 1) AS order_pct
FROM orders o
JOIN calendar cal ON o.order_date = cal.date
GROUP BY day_type
ORDER BY total_orders DESC;

-- -----------------------------------------------------------------------

-- Q12. Monthly order trend — is the business growing?
SELECT
    cal.year,
    cal.month_number,
    cal.month_name,
    COUNT(o.order_id) AS total_orders,
    COUNT(DISTINCT o.customer_id) AS unique_customers,
    ROUND(SUM(o.total_amount), 2) AS monthly_revenue,
    ROUND(AVG(o.total_amount), 2) AS avg_order_value
FROM orders o
JOIN calendar cal ON o.order_date = cal.date
GROUP BY cal.year, cal.month_number, cal.month_name
ORDER BY cal.year, cal.month_number;

-- -----------------------------------------------------------------------

-- SECTION 5: CUSTOMER DEMOGRAPHICS
-- -----------------------------------------------------------------------

-- Q13. What is the gender split of customers and their ordering patterns?
SELECT
    c.gender,
    COUNT(DISTINCT c.customer_id) AS customer_count,
    COUNT(o.order_id) AS total_orders,
    ROUND(SUM(o.total_amount), 2) AS total_revenue,
    ROUND(AVG(o.total_amount), 2) AS avg_order_value
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.gender
ORDER BY total_revenue DESC;

-- -----------------------------------------------------------------------

-- Q14. What age group orders the most?
SELECT
    CASE
        WHEN TIMESTAMPDIFF(YEAR, c.dob, CURDATE()) BETWEEN 18 AND 25 THEN '18-25'
        WHEN TIMESTAMPDIFF(YEAR, c.dob, CURDATE()) BETWEEN 26 AND 35 THEN '26-35'
        WHEN TIMESTAMPDIFF(YEAR, c.dob, CURDATE()) BETWEEN 36 AND 45 THEN '36-45'
        ELSE '45+'
    END AS age_group,
    COUNT(DISTINCT c.customer_id) AS customer_count,
    COUNT(o.order_id) AS total_orders,
    ROUND(SUM(o.total_amount), 2) AS total_revenue,
    ROUND(AVG(o.total_amount), 2) AS avg_order_value
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY age_group
ORDER BY total_orders DESC;

-- -----------------------------------------------------------------------

-- Q15. What is the meal preference split — Veg vs Non-Veg?
-- And which preference spends more?
SELECT
    c.meal_preference,
    COUNT(DISTINCT c.customer_id) AS customer_count,
    COUNT(o.order_id) AS total_orders,
    ROUND(SUM(o.total_amount), 2) AS total_revenue,
    ROUND(AVG(o.total_amount), 2) AS avg_order_value
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.meal_preference
ORDER BY total_revenue DESC;

-- -----------------------------------------------------------------------

-- Q16. Payment method preference — UPI vs COD split
SELECT
    payment_method,
    COUNT(*) AS total_orders,
    ROUND(SUM(total_amount), 2) AS total_revenue,
    ROUND(AVG(total_amount), 2) AS avg_order_value,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1) AS percentage
FROM orders
GROUP BY payment_method
ORDER BY total_orders DESC;


-- ======================================================================
-- MODULE 2: MENU PERFORMANCE ANALYSIS
-- ======================================================================

-- -----------------------------------------------------------------------
-- SECTION 1: BESTSELLERS AND WORST PERFORMERS
-- -----------------------------------------------------------------------

-- Q17. What are the top 10 items by quantity sold?
SELECT
    im.item_id,
    im.item_name,
    im.item_category,
    im.food_category,
    SUM(oi.item_quantity) AS total_quantity_sold,
    COUNT(DISTINCT oi.order_id) AS number_of_orders,
    ROUND(SUM(oi.item_quantity * oi.item_price), 2) AS total_revenue
FROM order_items oi
JOIN item_master im ON oi.item_id = im.item_id
GROUP BY im.item_id, im.item_name, im.item_category, im.food_category
ORDER BY total_quantity_sold DESC
LIMIT 10;

-- -----------------------------------------------------------------------

-- Q18. What are the bottom 5 items by quantity sold?
-- (Dead weight on the menu — consider removing or repositioning)
SELECT
    im.item_id,
    im.item_name,
    im.item_category,
    im.food_category,
    SUM(oi.item_quantity) AS total_quantity_sold,
    COUNT(DISTINCT oi.order_id) AS number_of_orders,
    ROUND(SUM(oi.item_quantity * oi.item_price), 2) AS total_revenue
FROM order_items oi
JOIN item_master im ON oi.item_id = im.item_id
GROUP BY im.item_id, im.item_name, im.item_category, im.food_category
ORDER BY total_quantity_sold ASC
LIMIT 5;

-- -----------------------------------------------------------------------

-- SECTION 2: CATEGORY ANALYSIS
-- -----------------------------------------------------------------------

-- Q19. What is the revenue split by category?
-- (Bowl vs Salad vs Smoothie vs Wrap vs Snack)
SELECT
    im.item_category,
    COUNT(DISTINCT im.item_id) AS items_in_category,
    SUM(oi.item_quantity) AS total_quantity_sold,
    ROUND(SUM(oi.item_quantity * oi.item_price), 2) AS total_revenue,
    ROUND(SUM(oi.item_quantity * oi.item_price) * 100.0 /
          SUM(SUM(oi.item_quantity * oi.item_price)) OVER(), 1) AS revenue_share_pct,
    ROUND(AVG(oi.item_price), 2) AS avg_item_price
FROM order_items oi
JOIN item_master im ON oi.item_id = im.item_id
GROUP BY im.item_category
ORDER BY total_revenue DESC;

-- -----------------------------------------------------------------------

-- Q20. Veg vs Non-Veg — which food type generates more revenue?
SELECT
    im.food_category,
    SUM(oi.item_quantity) AS total_quantity_sold,
    ROUND(SUM(oi.item_quantity * oi.item_price), 2) AS total_revenue,
    ROUND(SUM(oi.item_quantity * oi.item_price) * 100.0 /
          SUM(SUM(oi.item_quantity * oi.item_price)) OVER(), 1) AS revenue_share_pct,
    COUNT(DISTINCT oi.order_id) AS number_of_orders,
    ROUND(AVG(oi.item_price), 2) AS avg_item_price
FROM order_items oi
JOIN item_master im ON oi.item_id = im.item_id
GROUP BY im.food_category
ORDER BY total_revenue DESC;

-- -----------------------------------------------------------------------

-- Q21. Veg vs Non-Veg performance by time of day
-- (Does non-veg sell more in evenings? Veg in mornings?)
SELECT
    o.order_time,
    im.food_category,
    SUM(oi.item_quantity) AS total_quantity_sold,
    ROUND(SUM(oi.item_quantity * oi.item_price), 2) AS revenue
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
JOIN item_master im ON oi.item_id = im.item_id
GROUP BY o.order_time, im.food_category
ORDER BY o.order_time, im.food_category;

-- -----------------------------------------------------------------------

-- SECTION 3: PROFITABILITY ANALYSIS
-- -----------------------------------------------------------------------

-- Q22. Which item gives the best protein per rupee value?
-- (Helps the founder decide which items to promote to health-conscious customers)
SELECT
    im.item_id,
    im.item_name,
    im.item_category,
    im.food_category,
    im.proteins_g,
    im.selling_price,
    ROUND(im.proteins_g / im.selling_price, 4) AS protein_per_rupee,
    ROUND(im.proteins_g / im.calories * 100, 1) AS protein_calorie_ratio_pct
FROM item_master im
WHERE im.selling_price > 0
ORDER BY protein_per_rupee DESC;

-- -----------------------------------------------------------------------

-- Q23. What is the profit margin per item?
-- (Uses cost_price vs selling_price from item_master)
SELECT
    im.item_id,
    im.item_name,
    im.item_category,
    im.cost_price,
    im.selling_price,
    ROUND(im.selling_price - im.cost_price, 2) AS profit_per_unit,
    ROUND((im.selling_price - im.cost_price) * 100.0 / im.selling_price, 1) AS margin_pct,
    SUM(oi.item_quantity) AS total_quantity_sold,
    ROUND(SUM(oi.item_quantity) * (im.selling_price - im.cost_price), 2) AS total_profit
FROM item_master im
JOIN order_items oi ON im.item_id = oi.item_id
GROUP BY im.item_id, im.item_name, im.item_category,
         im.cost_price, im.selling_price
ORDER BY total_profit DESC;

-- -----------------------------------------------------------------------

-- Q24. Which category is most profitable overall?
SELECT
    im.item_category,
    ROUND(AVG(im.selling_price - im.cost_price), 2) AS avg_profit_per_unit,
    ROUND(AVG((im.selling_price - im.cost_price) * 100.0 / im.selling_price), 1) AS avg_margin_pct,
    SUM(oi.item_quantity) AS total_quantity_sold,
    ROUND(SUM(oi.item_quantity * (im.selling_price - im.cost_price)), 2) AS total_category_profit
FROM item_master im
JOIN order_items oi ON im.item_id = oi.item_id
GROUP BY im.item_category
ORDER BY total_category_profit DESC;

-- -----------------------------------------------------------------------

-- SECTION 4: FEATURED ITEMS PERFORMANCE
-- -----------------------------------------------------------------------

-- Q25. Do featured items actually sell more than non-featured items?
SELECT
    im.is_featured,
    CASE WHEN im.is_featured = 'Y' THEN 'Featured' ELSE 'Not Featured' END AS feature_status,
    COUNT(DISTINCT im.item_id) AS item_count,
    SUM(oi.item_quantity) AS total_quantity_sold,
    ROUND(SUM(oi.item_quantity * oi.item_price), 2) AS total_revenue,
    ROUND(SUM(oi.item_quantity) * 1.0 / COUNT(DISTINCT im.item_id), 1) AS avg_qty_per_item,
    ROUND(SUM(oi.item_quantity * oi.item_price) / COUNT(DISTINCT im.item_id), 2) AS avg_revenue_per_item
FROM order_items oi
JOIN item_master im ON oi.item_id = im.item_id
GROUP BY im.is_featured
ORDER BY avg_revenue_per_item DESC;

-- -----------------------------------------------------------------------

-- Q26. Which featured items are underperforming?
-- (Featured but selling less than average — wasted homepage space)
SELECT
    im.item_id,
    im.item_name,
    im.item_category,
    SUM(oi.item_quantity) AS total_quantity_sold,
    ROUND(SUM(oi.item_quantity * oi.item_price), 2) AS total_revenue
FROM order_items oi
JOIN item_master im ON oi.item_id = oi.item_id
WHERE im.is_featured = 'Y'
GROUP BY im.item_id, im.item_name, im.item_category
HAVING total_quantity_sold < (
    SELECT AVG(qty) FROM (
        SELECT SUM(item_quantity) AS qty
        FROM order_items
        GROUP BY item_id
    ) avg_table
)
ORDER BY total_quantity_sold ASC;

-- -----------------------------------------------------------------------

-- SECTION 5: DISCOUNT ITEMS PERFORMANCE
-- -----------------------------------------------------------------------

-- Q27. Are discounted items selling more than non-discounted items?
SELECT
    CASE
        WHEN im.discount_price IS NOT NULL THEN 'Discounted'
        ELSE 'Full Price'
    END AS price_status,
    COUNT(DISTINCT im.item_id) AS item_count,
    SUM(oi.item_quantity) AS total_quantity_sold,
    ROUND(SUM(oi.item_quantity * oi.item_price), 2) AS total_revenue,
    ROUND(SUM(oi.item_quantity) * 1.0 / COUNT(DISTINCT im.item_id), 1) AS avg_qty_per_item
FROM order_items oi
JOIN item_master im ON oi.item_id = im.item_id
GROUP BY price_status
ORDER BY avg_qty_per_item DESC;

-- -----------------------------------------------------------------------

-- SECTION 6: ITEMS FREQUENTLY ORDERED TOGETHER
-- -----------------------------------------------------------------------

-- Q28. Which items are most frequently ordered together in the same order?
-- (Market basket analysis — useful for combo meal recommendations)
SELECT
    im1.item_name AS item_1,
    im2.item_name AS item_2,
    COUNT(*) AS times_ordered_together
FROM order_items oi1
JOIN order_items oi2 ON oi1.order_id = oi2.order_id
    AND oi1.item_id < oi2.item_id
JOIN item_master im1 ON oi1.item_id = im1.item_id
JOIN item_master im2 ON oi2.item_id = im2.item_id
GROUP BY im1.item_name, im2.item_name
ORDER BY times_ordered_together DESC
LIMIT 10;

-- -----------------------------------------------------------------------

-- SECTION 7: STOCK AND AVAILABILITY
-- -----------------------------------------------------------------------

-- Q29. Are out-of-stock items high-demand items?
-- (If a popular item is frequently unavailable, the business is losing revenue)
SELECT
    im.item_id,
    im.item_name,
    im.item_category,
    im.stock_availability,
    SUM(oi.item_quantity) AS total_quantity_sold,
    ROUND(SUM(oi.item_quantity * oi.item_price), 2) AS total_revenue,
    CASE
        WHEN im.stock_availability = 'N' AND SUM(oi.item_quantity) > (
            SELECT AVG(qty) FROM (
                SELECT SUM(item_quantity) AS qty
                FROM order_items GROUP BY item_id
            ) t
        ) THEN 'HIGH PRIORITY — Restock Immediately'
        WHEN im.stock_availability = 'N' THEN 'Low Priority — Can Wait'
        ELSE 'In Stock'
    END AS restock_recommendation
FROM item_master im
LEFT JOIN order_items oi ON im.item_id = oi.item_id
GROUP BY im.item_id, im.item_name, im.item_category, im.stock_availability
ORDER BY im.stock_availability ASC, total_quantity_sold DESC;

-- ======================================================================
-- END OF SAKSHI'S QUERIES
-- ======================================================================

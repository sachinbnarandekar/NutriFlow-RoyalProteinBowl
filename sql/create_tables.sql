-- ======================================================================
-- NutriFlow - RoyalProteinBowl.in
-- Database Schema Creation Script (MySQL)
-- ======================================================================
-- Run this ENTIRE script in MySQL Workbench (or via command line) BEFORE
-- running the Python loader script. This creates the database and all
-- 11 tables with correct Primary Keys and Foreign Keys.
-- ======================================================================

DROP DATABASE IF EXISTS royalproteinbowl;
CREATE DATABASE royalproteinbowl;
USE royalproteinbowl;

-- ----------------------------------------------------------------
-- DIMENSION TABLES (create first - no dependencies, or simple ones)
-- ----------------------------------------------------------------

CREATE TABLE calendar (
    date            DATE PRIMARY KEY,
    day_number      INT,
    day_name        VARCHAR(10),
    week_number     INT,
    month_number    INT,
    month_name      VARCHAR(10),
    quarter         VARCHAR(5),
    year            INT,
    is_weekend      CHAR(1),
    is_holiday      CHAR(1)
);

CREATE TABLE locations (
    location_id     INT PRIMARY KEY,
    pincode         VARCHAR(7) UNIQUE,
    country         VARCHAR(20),
    region          VARCHAR(25),
    state           VARCHAR(30),
    city            VARCHAR(50),
    delivery_zone   VARCHAR(20),
    is_serviceable  CHAR(1)
);

CREATE TABLE item_master (
    item_id             INT PRIMARY KEY,
    item_name           VARCHAR(100),
    item_category       VARCHAR(20),
    food_category       CHAR(10),
    contents            VARCHAR(200),
    weight_grams        DECIMAL(5,2),
    calories            DECIMAL(5,2),
    proteins_g          DECIMAL(5,2),
    carbs_g             DECIMAL(5,2),
    fats_g              DECIMAL(5,2),
    fiber_g             DECIMAL(5,2),
    cost_price          DECIMAL(6,2),
    selling_price       DECIMAL(6,2),
    discount_price      DECIMAL(6,2),
    stock_availability  CHAR(1),
    is_featured         CHAR(1)
);

CREATE TABLE coupons (
    coupon_code       VARCHAR(8) PRIMARY KEY,
    coupon_name       VARCHAR(25),
    discount_type     VARCHAR(20),
    discount_value    DECIMAL(6,2),
    min_order_amount  DECIMAL(6,2),
    max_uses          INT,
    total_used        INT,
    expiry_date       DATE,
    active            CHAR(1)
);

CREATE TABLE staff (
    staff_id          INT PRIMARY KEY,
    staff_firstname   VARCHAR(30),
    staff_lastname    VARCHAR(30),
    phone_number      VARCHAR(15),
    staff_address     VARCHAR(100),
    staff_dob         DATE,
    staff_hiredate    DATE,
    department        VARCHAR(20),
    role              VARCHAR(30),
    shift             VARCHAR(10),
    salary            DECIMAL(8,2),
    status            CHAR(1)
);

CREATE TABLE customers (
    customer_id          INT PRIMARY KEY,
    customer_firstname   VARCHAR(30),
    customer_lastname    VARCHAR(30),
    phone_number         VARCHAR(15),
    email_address        VARCHAR(50),
    gender                VARCHAR(10),
    dob                   DATE,
    city                  VARCHAR(50),
    pincode               VARCHAR(7),
    main_address          VARCHAR(100),
    delivery_address      VARCHAR(100),
    meal_preference       VARCHAR(10),
    signup_date           DATE,
    acquisition_channel   VARCHAR(20)
);

-- ----------------------------------------------------------------
-- FACT TABLES (created after dimensions - they reference them via FK)
-- ----------------------------------------------------------------

CREATE TABLE orders (
    order_id                INT PRIMARY KEY,
    customer_id             INT,
    staff_id                INT,
    coupon_code             VARCHAR(8),
    delivery_pincode        VARCHAR(7),
    order_date               DATE,
    order_time                VARCHAR(10),
    payment_method            VARCHAR(10),
    delivery_status           VARCHAR(20),
    promised_delivery_time    INT,
    actual_delivery_time      INT,
    total_amount               DECIMAL(8,2),

    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (staff_id) REFERENCES staff(staff_id),
    FOREIGN KEY (coupon_code) REFERENCES coupons(coupon_code),
    FOREIGN KEY (delivery_pincode) REFERENCES locations(pincode),
    FOREIGN KEY (order_date) REFERENCES calendar(date)
);

CREATE TABLE order_items (
    order_item_id   INT PRIMARY KEY,
    order_id        INT,
    item_id         INT,
    item_quantity   INT,
    item_price      DECIMAL(6,2),

    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (item_id) REFERENCES item_master(item_id)
);

CREATE TABLE reviews (
    review_id         INT PRIMARY KEY,
    customer_id       INT,
    order_id          INT,
    review_date       DATE,
    overall_rating    INT,
    delivery_rating   INT,
    taste_rating      INT,
    portion_rating    INT,
    feedback          VARCHAR(300),
    status            VARCHAR(10),

    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (review_date) REFERENCES calendar(date)
);

CREATE TABLE bmi_logs (
    log_id                    INT PRIMARY KEY,
    customer_id               INT NULL,           -- NULL allowed for guest sessions
    record_date                DATE,
    age                         INT,
    gender                      VARCHAR(10),
    height_cm                   DECIMAL(5,2),
    weight_kg                   DECIMAL(5,2),
    activity_level               VARCHAR(25),
    bmi_value                    DECIMAL(5,2),
    bmi_category                  VARCHAR(20),
    meal_suggestion_viewed         CHAR(1),
    converted_to_order              CHAR(1),

    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (record_date) REFERENCES calendar(date)
);

CREATE TABLE subscriptions (
    subscription_id        INT PRIMARY KEY,
    customer_id             INT,
    coupon_code              VARCHAR(8),
    plan_type                 VARCHAR(10),
    meal_preference             VARCHAR(10),
    meals_per_day                INT,
    purchase_date                 DATE,
    start_date                     DATE,
    end_date                        DATE,
    amount                            DECIMAL(7,2),
    status                             VARCHAR(10),
    cancellation_reason                 VARCHAR(100),
    auto_renewal                          CHAR(1),

    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (coupon_code) REFERENCES coupons(coupon_code),
    FOREIGN KEY (purchase_date) REFERENCES calendar(date)
);

-- ======================================================================
-- DONE. After running this, use the Python loader script
-- (02_load_to_mysql.py) to populate these tables from the CSV files.
-- ======================================================================

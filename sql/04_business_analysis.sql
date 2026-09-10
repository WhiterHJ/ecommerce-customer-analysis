-- 综合业务分析
-- 包括月度趋势、国家、商品、取消交易、客户贡献与复购分析

USE ecommerce_customer_analysis;


-- =========================================================
-- 查询5：月度销售趋势
-- 2011-12只有9天数据，单独标记
-- =========================================================

SELECT
    invoice_month,
    COUNT(DISTINCT invoice_no) AS sales_order_count,
    COUNT(DISTINCT customer_id) AS identified_customer_count,
    ROUND(SUM(line_amount), 2) AS sales_amount,
    ROUND(
        SUM(line_amount) / COUNT(DISTINCT invoice_no),
        2
    ) AS average_order_value,
    CASE
        WHEN invoice_month = '2011-12' THEN 'Incomplete month'
        ELSE 'Complete month'
    END AS month_status
FROM transactions
WHERE transaction_type = 'Sale'
GROUP BY invoice_month
ORDER BY invoice_month;


-- =========================================================
-- 查询6：完整月份的环比销售额变化
-- 排除不完整的2011-12
-- =========================================================

WITH monthly_sales AS (
    SELECT
        invoice_month,
        SUM(line_amount) AS sales_amount
    FROM transactions
    WHERE transaction_type = 'Sale'
      AND invoice_month <> '2011-12'
    GROUP BY invoice_month
),
monthly_comparison AS (
    SELECT
        invoice_month,
        sales_amount,
        LAG(sales_amount) OVER (
            ORDER BY invoice_month
        ) AS previous_month_sales
    FROM monthly_sales
)
SELECT
    invoice_month,
    ROUND(sales_amount, 2) AS sales_amount,
    ROUND(previous_month_sales, 2) AS previous_month_sales,
    ROUND(
        100.0 * (sales_amount - previous_month_sales)
        / NULLIF(previous_month_sales, 0),
        2
    ) AS month_over_month_percent
FROM monthly_comparison
ORDER BY invoice_month;


-- =========================================================
-- 查询7：销售额最高的10个国家或地区
-- 包含英国
-- =========================================================

WITH country_sales AS (
    SELECT
        country,
        COUNT(DISTINCT invoice_no) AS sales_order_count,
        COUNT(DISTINCT customer_id) AS identified_customer_count,
        SUM(line_amount) AS sales_amount
    FROM transactions
    WHERE transaction_type = 'Sale'
    GROUP BY country
)
SELECT
    country,
    sales_order_count,
    identified_customer_count,
    ROUND(sales_amount, 2) AS sales_amount,
    ROUND(
        sales_amount / sales_order_count,
        2
    ) AS average_order_value,
    ROUND(
        100.0 * sales_amount
        / SUM(sales_amount) OVER (),
        2
    ) AS sales_amount_percent
FROM country_sales
ORDER BY sales_amount DESC
LIMIT 10;


-- =========================================================
-- 查询8：销售额最高的10个海外国家或地区
-- 排除英国
-- =========================================================

WITH overseas_country_sales AS (
    SELECT
        country,
        COUNT(DISTINCT invoice_no) AS sales_order_count,
        COUNT(DISTINCT customer_id) AS identified_customer_count,
        SUM(line_amount) AS sales_amount
    FROM transactions
    WHERE transaction_type = 'Sale'
      AND country <> 'United Kingdom'
    GROUP BY country
)
SELECT
    country,
    sales_order_count,
    identified_customer_count,
    ROUND(sales_amount, 2) AS sales_amount,
    ROUND(
        sales_amount / sales_order_count,
        2
    ) AS average_order_value,
    ROUND(
        100.0 * sales_amount
        / SUM(sales_amount) OVER (),
        2
    ) AS overseas_sales_percent
FROM overseas_country_sales
ORDER BY sales_amount DESC
LIMIT 10;


-- =========================================================
-- 查询9：销量最高的10种普通商品
-- stock_code作为主要商品标识
-- description只作为辅助展示
-- =========================================================

SELECT
    stock_code,
    MAX(description) AS product_description,
    SUM(quantity) AS quantity_sold,
    COUNT(DISTINCT invoice_no) AS sales_order_count,
    ROUND(SUM(line_amount), 2) AS merchandise_sales_amount
FROM transactions
WHERE transaction_type = 'Sale'
  AND item_type = 'Merchandise'
GROUP BY stock_code
ORDER BY quantity_sold DESC,
         merchandise_sales_amount DESC
LIMIT 10;


-- =========================================================
-- 查询10：销售额最高的10种普通商品
-- =========================================================

SELECT
    stock_code,
    MAX(description) AS product_description,
    SUM(quantity) AS quantity_sold,
    COUNT(DISTINCT invoice_no) AS sales_order_count,
    ROUND(SUM(line_amount), 2) AS merchandise_sales_amount
FROM transactions
WHERE transaction_type = 'Sale'
  AND item_type = 'Merchandise'
GROUP BY stock_code
ORDER BY merchandise_sales_amount DESC,
         quantity_sold DESC
LIMIT 10;


-- =========================================================
-- 查询11：取消交易总体情况
-- =========================================================

SELECT
    COUNT(*) AS cancellation_line_count,
    COUNT(DISTINCT invoice_no) AS cancellation_order_count,
    ROUND(ABS(SUM(line_amount)), 2) AS cancellation_amount,
    ROUND(
        100.0 * ABS(SUM(line_amount))
        / NULLIF(
            (
                SELECT SUM(line_amount)
                FROM transactions
                WHERE transaction_type = 'Sale'
            ),
            0
        ),
        2
    ) AS cancellation_amount_percent
FROM transactions
WHERE transaction_type = 'Cancellation';


-- =========================================================
-- 查询12：月度销售额与取消金额
-- =========================================================

SELECT
    invoice_month,

    ROUND(
        SUM(
            CASE
                WHEN transaction_type = 'Sale'
                THEN line_amount
                ELSE 0
            END
        ),
        2
    ) AS sales_amount,

    ROUND(
        ABS(
            SUM(
                CASE
                    WHEN transaction_type = 'Cancellation'
                    THEN line_amount
                    ELSE 0
                END
            )
        ),
        2
    ) AS cancellation_amount,

    ROUND(
        100.0 * ABS(
            SUM(
                CASE
                    WHEN transaction_type = 'Cancellation'
                    THEN line_amount
                    ELSE 0
                END
            )
        )
        / NULLIF(
            SUM(
                CASE
                    WHEN transaction_type = 'Sale'
                    THEN line_amount
                    ELSE 0
                END
            ),
            0
        ),
        2
    ) AS cancellation_amount_percent,

    CASE
        WHEN invoice_month = '2011-12' THEN 'Incomplete month'
        ELSE 'Complete month'
    END AS month_status

FROM transactions
WHERE transaction_type IN ('Sale', 'Cancellation')
GROUP BY invoice_month
ORDER BY invoice_month;


-- =========================================================
-- 查询13：销售额贡献最高的10名可识别客户
-- =========================================================

SELECT
    customer_id,
    COUNT(DISTINCT invoice_no) AS sales_order_count,
    ROUND(SUM(line_amount), 2) AS customer_sales_amount,
    MIN(invoice_date) AS first_purchase_datetime,
    MAX(invoice_date) AS last_purchase_datetime
FROM transactions
WHERE transaction_type = 'Sale'
  AND customer_id IS NOT NULL
GROUP BY customer_id
ORDER BY customer_sales_amount DESC
LIMIT 10;


-- =========================================================
-- 查询14：客户复购情况
-- =========================================================

WITH customer_orders AS (
    SELECT
        customer_id,
        COUNT(DISTINCT invoice_no) AS sales_order_count
    FROM transactions
    WHERE transaction_type = 'Sale'
      AND customer_id IS NOT NULL
    GROUP BY customer_id
)
SELECT
    COUNT(*) AS identified_customer_count,

    SUM(
        CASE
            WHEN sales_order_count = 1 THEN 1
            ELSE 0
        END
    ) AS one_time_customer_count,

    SUM(
        CASE
            WHEN sales_order_count >= 2 THEN 1
            ELSE 0
        END
    ) AS repeat_customer_count,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN sales_order_count >= 2 THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS repeat_customer_percent,

    ROUND(AVG(sales_order_count), 2) AS average_orders_per_customer

FROM customer_orders;


-- =========================================================
-- 查询15：销售额最高的10名客户贡献占比
-- =========================================================

WITH customer_sales AS (
    SELECT
        customer_id,
        SUM(line_amount) AS customer_sales_amount
    FROM transactions
    WHERE transaction_type = 'Sale'
      AND customer_id IS NOT NULL
    GROUP BY customer_id
),
ranked_customers AS (
    SELECT
        customer_id,
        customer_sales_amount,
        ROW_NUMBER() OVER (
            ORDER BY customer_sales_amount DESC,
                     customer_id
        ) AS revenue_rank
    FROM customer_sales
)
SELECT
    ROUND(
        SUM(
            CASE
                WHEN revenue_rank <= 10
                THEN customer_sales_amount
                ELSE 0
            END
        ),
        2
    ) AS top_10_customer_sales_amount,

    ROUND(
        SUM(customer_sales_amount),
        2
    ) AS all_identified_customer_sales_amount,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN revenue_rank <= 10
                THEN customer_sales_amount
                ELSE 0
            END
        ) / SUM(customer_sales_amount),
        2
    ) AS top_10_customer_sales_percent

FROM ranked_customers;
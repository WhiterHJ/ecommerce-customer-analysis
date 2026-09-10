-- 总体经营指标分析
-- 统计数据范围、销售额、订单量、客户数和客户编号覆盖情况

USE ecommerce_customer_analysis;


-- =========================================================
-- 查询1：确认数据覆盖范围
-- =========================================================

SELECT
    COUNT(*) AS total_rows,
    MIN(invoice_date) AS start_datetime,
    MAX(invoice_date) AS end_datetime,
    COUNT(DISTINCT invoice_month) AS covered_month_count
FROM transactions;


-- =========================================================
-- 查询2：计算正常销售核心指标
-- =========================================================

SELECT
    COUNT(*) AS sale_line_count,
    COUNT(DISTINCT invoice_no) AS sales_order_count,
    COUNT(DISTINCT customer_id) AS identified_customer_count,
    ROUND(SUM(line_amount), 2) AS sales_amount,
    ROUND(
        SUM(line_amount) / COUNT(DISTINCT invoice_no),
        2
    ) AS average_order_value
FROM transactions
WHERE transaction_type = 'Sale';


-- =========================================================
-- 查询3：分析正常销售中的客户编号覆盖情况
-- =========================================================

SELECT
    COUNT(*) AS total_sale_lines,

    SUM(
        CASE
            WHEN has_customer_id = 1 THEN 1
            ELSE 0
        END
    ) AS identified_sale_lines,

    SUM(
        CASE
            WHEN has_customer_id = 0 THEN 1
            ELSE 0
        END
    ) AS unidentified_sale_lines,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN has_customer_id = 1 THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS identified_line_percent,

    ROUND(
        SUM(
            CASE
                WHEN has_customer_id = 1 THEN line_amount
                ELSE 0
            END
        ),
        2
    ) AS identified_sales_amount,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN has_customer_id = 1 THEN line_amount
                ELSE 0
            END
        ) / SUM(line_amount),
        2
    ) AS identified_amount_percent

FROM transactions
WHERE transaction_type = 'Sale';


-- =========================================================
-- 查询4：查看不同交易类型的规模和金额
-- =========================================================

SELECT
    transaction_type,
    COUNT(*) AS line_count,
    COUNT(DISTINCT invoice_no) AS document_count,
    ROUND(SUM(line_amount), 2) AS signed_amount
FROM transactions
GROUP BY transaction_type
ORDER BY line_count DESC;
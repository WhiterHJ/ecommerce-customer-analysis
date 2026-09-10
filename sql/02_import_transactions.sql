-- 导入清洗后的完整交易数据
-- 如果你在复现本项目，需要把下面的路径替换为实际CSV绝对路径！！

USE ecommerce_customer_analysis;

LOAD DATA LOCAL INFILE
'C:/Users/a/Documents/DataAnalysisProjects/ecommerce-customer-analysis/data/processed/transactions_clean.csv'
INTO TABLE transactions
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(
    @source_row,
    @invoice_no,
    @stock_code,
    @description,
    @quantity,
    @invoice_date,
    @unit_price,
    @customer_id,
    @country,
    @line_amount,
    @invoice_year,
    @invoice_month,
    @has_customer_id,
    @transaction_type,
    @item_type
)
SET
    source_row = CAST(@source_row AS UNSIGNED),
    invoice_no = @invoice_no,
    stock_code = @stock_code,
    description = NULLIF(@description, ''),
    quantity = CAST(@quantity AS SIGNED),
    invoice_date = STR_TO_DATE(
        @invoice_date,
        '%Y-%m-%d %H:%i:%s'
    ),
    unit_price = CAST(@unit_price AS DECIMAL(12, 3)),
    customer_id = NULLIF(@customer_id, ''),
    country = @country,
    line_amount = ROUND(
        CAST(@line_amount AS DECIMAL(40, 20)),
        3
    ),
    invoice_year = CAST(@invoice_year AS UNSIGNED),
    invoice_month = @invoice_month,
    has_customer_id =
        CASE LOWER(@has_customer_id)
            WHEN 'true' THEN 1
            WHEN 'false' THEN 0
            ELSE NULL
        END,
    transaction_type = @transaction_type,
    item_type = @item_type;

SHOW COUNT(*) WARNINGS;
SHOW WARNINGS LIMIT 20;
-- 创建电商客户分析数据库
CREATE DATABASE IF NOT EXISTS ecommerce_customer_analysis
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_0900_ai_ci;

-- 切换到项目数据库
USE ecommerce_customer_analysis;

-- 创建清洗后交易明细表
CREATE TABLE IF NOT EXISTS transactions (
    source_row INT UNSIGNED NOT NULL,
    invoice_no VARCHAR(10) NOT NULL,
    stock_code VARCHAR(20) NOT NULL,
    description VARCHAR(100) NULL,
    quantity INT NOT NULL,
    invoice_date DATETIME NOT NULL,
    unit_price DECIMAL(12, 3) NOT NULL,
    customer_id VARCHAR(10) NULL,
    country VARCHAR(50) NOT NULL,
    line_amount DECIMAL(14, 3) NOT NULL,
    invoice_year SMALLINT UNSIGNED NOT NULL,
    invoice_month CHAR(7) NOT NULL,
    has_customer_id TINYINT(1) NOT NULL,
    transaction_type VARCHAR(20) NOT NULL,
    item_type VARCHAR(30) NOT NULL,

    PRIMARY KEY (source_row),

    CONSTRAINT chk_has_customer_id
        CHECK (has_customer_id IN (0, 1)),

    CONSTRAINT chk_transaction_type
        CHECK (
            transaction_type IN (
                'Sale',
                'Cancellation',
                'StockAdjustment',
                'ZeroPrice',
                'PriceAdjustment'
            )
        ),

    CONSTRAINT chk_item_type
        CHECK (
            item_type IN (
                'Merchandise',
                'Postage',
                'Manual',
                'Carriage',
                'Discount',
                'Sample',
                'BankCharge',
                'PlatformFee',
                'GiftVoucher',
                'Commission',
                'BadDebtAdjustment'
            )
        )
)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_0900_ai_ci;
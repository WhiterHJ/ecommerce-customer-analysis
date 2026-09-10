# 业务指标口径说明

## 一、文档目的

本文档用于统一项目中 SQL、Python 和 Power BI 的业务指标计算口径。

同一个指标在不同工具中必须使用相同的数据范围、筛选条件和计算方法，避免出现名称相同但结果不同的情况。

## 二、数据基础

- 数据表：`ecommerce_customer_analysis.transactions`
- 清洗后总行数：536,641
- 数据时间范围：2010-12-01 至 2011-12-09
- 货币单位：英镑（GBP）
- 数据粒度：一行代表一个订单中的一项商品或收费明细
- 订单编号字段：`invoice_no`
- 客户编号字段：`customer_id`
- 明细金额字段：`line_amount`
- 交易分类字段：`transaction_type`
- 商品分类字段：`item_type`

2011年12月的数据只记录到12月9日，因此属于不完整月份。进行完整月份之间的趋势比较时，应单独标注或排除该月份。

数据集没有商品成本、物流成本、广告费用和其他经营费用，因此本项目只能分析销售金额，不能直接计算利润。

## 三、基础分析范围

| 分析范围 | SQL筛选条件 | 已知规模 | 主要用途 |
|---|---|---:|---|
| 清洗后全部记录 | 不筛选交易类型 | 536,641行 | 数据质量和交易类型检查 |
| 正常销售记录 | `transaction_type = 'Sale'` | 524,878行 | 销售趋势、国家分析和总体经营指标 |
| 有客户编号的正常销售 | `transaction_type = 'Sale' AND customer_id IS NOT NULL` | 392,692行、4,338名客户 | 客户分析、复购分析和RFM分析 |
| 正常商品销售 | `transaction_type = 'Sale' AND item_type = 'Merchandise'` | 由SQL计算 | 商品销量和商品销售额分析 |
| 取消交易 | `transaction_type = 'Cancellation'` | 9,251行 | 取消订单数量和取消金额分析 |
| 其他特殊交易 | `transaction_type IN ('StockAdjustment', 'ZeroPrice', 'PriceAdjustment')` | 由SQL分别计算 | 数据质量和特殊业务记录分析 |

缺失客户编号的正常销售记录仍然可以用于总体销售额、订单量、国家和时间趋势分析，但不能用于客户数、复购率和RFM分析。

## 四、核心经营指标

### 1. 销售额

英文名称：`sales_amount`

定义：正常销售记录产生的正向销售金额总和。

计算范围：

```sql
transaction_type = 'Sale'
```

计算方法：

```sql
ROUND(SUM(line_amount), 2)
```

该指标包括被分类为正常销售的商品和其他正向收费明细，因此属于总体开票销售金额，不等同于商品销售额，也不等同于利润。

### 2. 销售订单量

英文名称：`sales_order_count`

定义：至少包含一条正常销售记录的不同订单数量。

计算方法：

```sql
COUNT(DISTINCT invoice_no)
```

计算范围：

```sql
transaction_type = 'Sale'
```

不能直接使用 `COUNT(*)` 作为订单量，因为一个订单通常包含多条商品明细。

### 3. 可识别销售客户数

英文名称：`identified_customer_count`

定义：正常销售记录中具有客户编号的不同客户数量。

计算方法：

```sql
COUNT(DISTINCT customer_id)
```

计算范围：

```sql
transaction_type = 'Sale'
AND customer_id IS NOT NULL
```

该指标只代表能够识别客户编号的客户，不代表企业全部实际客户。

### 4. 平均订单金额

英文名称：`average_order_value`

定义：每个正常销售订单平均产生的销售金额。

计算方法：

```text
正常销售额 ÷ 正常销售订单量
```

对应SQL逻辑：

```sql
ROUND(
    SUM(line_amount) / COUNT(DISTINCT invoice_no),
    2
)
```

计算范围：

```sql
transaction_type = 'Sale'
```

### 5. 商品销售数量

英文名称：`merchandise_quantity`

定义：正常销售中普通商品的销售数量总和。

计算方法：

```sql
SUM(quantity)
```

计算范围：

```sql
transaction_type = 'Sale'
AND item_type = 'Merchandise'
```

邮费、手续费、折扣和人工调整等特殊记录不视为实际商品件数。

### 6. 商品销售额

英文名称：`merchandise_sales_amount`

定义：普通商品正常销售产生的金额。

计算方法：

```sql
ROUND(SUM(line_amount), 2)
```

计算范围：

```sql
transaction_type = 'Sale'
AND item_type = 'Merchandise'
```

商品排行必须使用该口径，避免把邮费、手续费和其他特殊编码当作商品。

### 7. 取消金额

英文名称：`cancellation_amount`

定义：取消交易对应负金额的绝对值。

计算方法：

```sql
ROUND(ABS(SUM(line_amount)), 2)
```

计算范围：

```sql
transaction_type = 'Cancellation'
```

取消交易的 `line_amount` 通常为负数，因此展示取消规模时取绝对值。

由于数据中没有支付、发货和退款状态，该指标只能称为取消金额，不能断定所有取消记录都已经完成退款。

### 8. 取消订单量

英文名称：`cancellation_order_count`

定义：不同取消单据编号的数量。

计算方法：

```sql
COUNT(DISTINCT invoice_no)
```

计算范围：

```sql
transaction_type = 'Cancellation'
```

### 9. 取消金额率

英文名称：`cancellation_amount_rate`

定义：取消金额相对于正常销售额的比例。

计算方法：

```text
取消金额 ÷ 正常销售额
```

结果以百分比展示。

该指标用于描述取消金额规模，不等同于企业财务口径中的实际退款率。

## 五、客户指标

### 1. 客户订单量

定义：同一客户正常销售订单编号的去重数量。

计算方法：

```sql
COUNT(DISTINCT invoice_no)
```

计算范围：

```sql
transaction_type = 'Sale'
AND customer_id IS NOT NULL
```

### 2. 复购客户

定义：正常销售订单量大于或等于2笔的可识别客户。

判断条件：

```text
客户正常销售订单量 >= 2
```

### 3. 客户复购率

英文名称：`repeat_customer_rate`

计算方法：

```text
复购客户数 ÷ 发生过正常购买的可识别客户数
```

缺失客户编号的交易不能用于判断是否来自同一客户，因此不参与复购率计算。

## 六、RFM指标

RFM分析只使用有客户编号的正常销售记录：

```sql
transaction_type = 'Sale'
AND customer_id IS NOT NULL
```

### Recency

定义：客户最后一次正常购买日期距离分析参考日期的天数。

为了保证 SQL、Python 和 Power BI 结果一致，本项目固定使用：

```text
分析参考日期：2011-12-10
```

该日期是数据集中最后交易日期的下一天。

Recency越小，表示客户最近购买时间越近。

### Frequency

定义：客户的不同正常销售订单数量。

计算方法：

```sql
COUNT(DISTINCT invoice_no)
```

不能使用交易明细行数代替订单数量。

### Monetary

定义：客户所有正常销售记录的销售金额总和。

计算方法：

```sql
ROUND(SUM(line_amount), 2)
```

## 七、时间分析口径

月度分析使用字段：

```sql
invoice_month
```

时间趋势默认使用正常销售记录：

```sql
transaction_type = 'Sale'
```

2011年12月只有1日至9日的数据，因此：

1. 可以在趋势图中保留；
2. 必须标注为不完整月份；
3. 不应直接与其他完整月份比较月度高低；
4. 计算完整月份平均值、增长率或排名时应排除。

## 八、国家和地区分析口径

国家或地区销售分析默认使用正常销售记录：

```sql
transaction_type = 'Sale'
```

主要指标包括：

- 销售额；
- 不同销售订单量；
- 可识别客户数；
- 平均订单金额。

英国是数据主体所在国家。分析其他市场表现时，应同时提供：

1. 包含英国的整体结果；
2. 排除英国后的海外市场结果。

## 九、商品分析口径

商品分析只使用：

```sql
transaction_type = 'Sale'
AND item_type = 'Merchandise'
```

商品销量使用：

```sql
SUM(quantity)
```

商品销售额使用：

```sql
SUM(line_amount)
```

商品排行不能把 `POST`、`DOT`、`M`、`D` 等特殊业务编码当作普通商品。

商品描述存在缺失，因此商品编号 `stock_code` 是商品分析的主要标识；描述只作为辅助展示字段。

## 十、统一计算规则

1. 先按照业务口径筛选数据，再计算指标。
2. 一个订单可以包含多条明细，订单量必须对 `invoice_no` 去重。
3. 客户级分析必须排除缺失客户编号的记录。
4. 正常销售、取消交易和其他调整记录分别分析，不直接混合。
5. 商品排行只分析 `Merchandise`。
6. 金额先汇总，再统一保留两位小数。
7. SQL、Python和Power BI必须使用相同筛选条件。
8. 分析结果只能解释交易行为，不能直接解释利润、购买动机或营销效果。
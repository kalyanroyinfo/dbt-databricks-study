WITH bronze_sales AS (
    SELECT
        sales_id,
        product_sk,
        customer_sk,
        {{ multiply('quantity', 'unit_price') }} as calculated_amount,
        gross_amount,
        payment_method
    FROM
        {{ ref('bronze_sales') }}
),
bronze_products AS (
    SELECT
        product_sk,
        product_name,
        category
    FROM
        {{ ref('bronze_product') }}
),
bronze_customers AS (
    SELECT
        customer_sk,
        gender
    FROM
        {{ ref('bronze_customer') }}
),
silver_sales_info AS (
    SELECT 
        bs.sales_id,
        bs.calculated_amount,
        bp.product_name,
        bp.category,
        bc.gender,
        bs.gross_amount,
        bs.payment_method
    FROM
        bronze_sales bs
    JOIN    
    bronze_products bp
        on
        bs.product_sk = bp.product_sk
    join
        bronze_customers bc
    on
        bs.customer_sk = bc.customer_sk
)
Select
category,
gender,
sum(gross_amount) as total_gross_amount
FROM
silver_sales_info
group by category, gender
order by total_gross_amount desc

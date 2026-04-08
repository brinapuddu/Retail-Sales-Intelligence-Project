/*
-----------------------------------------------------------------------------------------------------
Segmentation analysis SQL script for products and customers on the gold schema.
Covers product cost segmentation grouping products into three cost ranges via a CTE and CASE,
and customer segmentation classifying customers into VIP, Regular, and New groups based on
their lifespan and total spending, returning the total count per segment.
-----------------------------------------------------------------------------------------------------
*/

--Segment products into cost ranges and count how many products fall into each segment
WITH product_costs AS
    (
        SELECT
        SUM(cost) as product_sales,
        product_key,
        CASE 
            WHEN SUM(cost) < 100 THEN 'Below 100'
            WHEN SUM(cost) BETWEEN 100 AND 500 THEN 'Between 100 - 500'  
        ELSE 'Above 500'
        END cost_range,
        product_name
        FROM gold.dim_products 
        GROUP BY product_name, product_key
    )

SELECT 
cost_range, 
COUNT(product_key) AS No_products
FROM product_costs
GROUP BY cost_range
ORDER BY No_products;

--Group customers into three segments based on their spending behavior:

--VIP: Customers with at least 12 months of history and spending more than €5,000.
--Regular: Customers with at least 12 months of history but spending €5,000 or less.
--New: Customers with a lifespan less than 12 months.
--And find the total number of customers by each group.

WITH life_span_category AS (
SELECT 
    MIN(order_date) as first_order,
    MAX(order_date) as last_order,
    DATEDIFF(MONTH, MIN(order_date), MAX(order_date)) as life_span, 
    SUM(sales_amount) as total_spending,
    customer_key
    FROM gold.fact_sales s
    GROUP BY customer_key
)

SELECT 
customer_segment,
COUNT(customer_key) as total_customers
FROM 

(
    SELECT 
    total_spending, 
    life_span, 
    customer_key,
    CASE 
    WHEN total_spending > 5000 AND life_span >= 12 THEN 'VIP customers'
    WHEN total_spending <= 5000 AND life_span >= 12 THEN 'Regular customers'
    ELSE 'New customers'
    END customer_segment
    FROM life_span_category
)t
GROUP BY customer_segment;




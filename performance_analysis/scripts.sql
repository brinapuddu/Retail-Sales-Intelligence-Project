/*
-----------------------------------------------------------------------------------------------------
Performance analysis SQL script for product sales on the gold schema.
Covers yearly product sales aggregated via a CTE, benchmarked against each product's
all-time average using window functions, and compared to the prior year's sales using
LAG to classify year-over-year trends as increase, decrease, or no change.
-----------------------------------------------------------------------------------------------------
*/


--Analyze the yearly performance of product by comparing their sales to both average sales performance of the product and previous year's sales
WITH yearly_sales AS (
    SELECT
    YEAR(s.order_date) AS year_date,
    SUM(s.sales_amount) AS current_sales,
    p.product_name AS product_name
    FROM gold.fact_sales s
    LEFT JOIN gold.dim_products p 
    ON s.product_key = p.product_key
    WHERE order_date IS NOT NULL
    GROUP BY YEAR (s.order_date), p.product_name 

)

SELECT 
year_date, 
current_sales,
product_name, 
AVG(current_sales) OVER (PARTITION BY product_name) AS avg_sales,
current_sales - AVG(current_sales) OVER (PARTITION BY product_name) AS diff_avg,
CASE 
    WHEN current_sales - AVG(current_sales) OVER (PARTITION BY product_name) > 0 THEN 'above average'
    WHEN current_sales - AVG(current_sales) OVER (PARTITION BY product_name) < 0 THEN 'below average'
    ELSE 'avg'
END avg_change,
LAG(current_sales) OVER (PARTITION BY product_name ORDER BY year_date) AS previous_sale,
current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY year_date) AS yearly_diff,
CASE
    WHEN current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY year_date) > 0 THEN 'Increase'
    WHEN current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY year_date) < 0 THEN 'Decrease'
    ELSE 'No change'
END yearly_change
FROM yearly_sales
ORDER BY year_date, product_name;


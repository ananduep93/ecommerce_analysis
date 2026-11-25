CREATE DATABASE assignment_db;

USE assignment_db;

CREATE TABLE ecommerce (
    InvoiceNo VARCHAR(20),
    StockCode VARCHAR(20),
    Description TEXT,
    Quantity INT,
    InvoiceDate DATETIME,
    UnitPrice DECIMAL(12,4),
    CustomerID INT,
    Country VARCHAR(100)
);

USE assignment_db;

LOAD DATA LOCAL INFILE
'C:/mysql_data/data.csv'
INTO TABLE ecommerce
CHARACTER SET latin1
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(@invoice, @stock, @description,
 @qty, @date, @price, @customer, @country)
SET
 InvoiceNo = @invoice,
 StockCode = @stock,
 Description = NULLIF(@description, ''),
 Quantity = NULLIF(@qty, ''),
 InvoiceDate = STR_TO_DATE(
     @date, '%m/%d/%Y %H:%i'
 ),
 UnitPrice = NULLIF(@price, ''),
 CustomerID = NULLIF(@customer, ''),
 Country = @country;
 
 
 table ecommerce ;


-- Q1. Total number of transactions

SELECT COUNT(*) AS total_transactions
FROM ecommerce;

-- Q2. Number of unique invoices

SELECT COUNT(DISTINCT InvoiceNo) AS unique_invoices
FROM ecommerce;


-- Q3. Number of unique products

SELECT COUNT(DISTINCT StockCode) AS unique_products
FROM ecommerce;


-- Q4. Number of unique customers

SELECT COUNT(DISTINCT CustomerID) AS unique_customers
FROM ecommerce;


-- Q5. Display unique countries

SELECT DISTINCT Country
FROM ecommerce
ORDER BY Country;


-- Q6. Transactions from United Kingdom

SELECT *
FROM ecommerce
WHERE Country = 'United Kingdom';

-- Q7. Transactions with UnitPrice greater than 10

SELECT *
FROM ecommerce
WHERE UnitPrice > 10;


-- Q8. Total quantity of products sold

SELECT SUM(Quantity) AS total_quantity
FROM ecommerce
WHERE Quantity > 0 AND UnitPrice > 0;


-- Q9. Average, minimum and maximum UnitPrice

SELECT
    AVG(UnitPrice) AS average_price,
    MIN(UnitPrice) AS minimum_price,
    MAX(UnitPrice) AS maximum_price
FROM ecommerce;


-- Q10. Calculate total sales amount

SELECT SUM(Quantity * UnitPrice) AS total_sales
FROM ecommerce
WHERE Quantity > 0 AND UnitPrice > 0;


-- Q11. Countries with total sales above 10000

WITH country_sales AS (
    SELECT Country,
           SUM(Quantity * UnitPrice) AS total_sales
    FROM ecommerce
    WHERE Quantity > 0 AND UnitPrice > 0
    GROUP BY Country
)
SELECT *
FROM country_sales
WHERE total_sales > 10000;


-- Q12. Customers spending above average

WITH customer_sales AS (
    SELECT CustomerID,
           SUM(Quantity * UnitPrice) AS spending
    FROM ecommerce
    WHERE CustomerID IS NOT NULL
      AND Quantity > 0 AND UnitPrice > 0
    GROUP BY CustomerID
)
SELECT *
FROM customer_sales
WHERE spending > (
    SELECT AVG(spending)
    FROM customer_sales
)
ORDER BY spending DESC;

-- Q13. Rank countries by total sales

SELECT Country,
       SUM(Quantity * UnitPrice) AS total_sales,
       RANK() OVER (
           ORDER BY SUM(Quantity * UnitPrice) DESC
       ) AS sales_rank
FROM ecommerce
WHERE Quantity > 0 AND UnitPrice > 0
GROUP BY Country;


-- Q14. Top 3 products in each country

WITH product_sales AS (
    SELECT Country, StockCode,
           SUM(Quantity * UnitPrice) AS total_sales
    FROM ecommerce
    WHERE Quantity > 0 AND UnitPrice > 0
    GROUP BY Country, StockCode
),
ranked_products AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY Country
               ORDER BY total_sales DESC, StockCode
           ) AS product_rank
    FROM product_sales
)
SELECT *
FROM ranked_products
WHERE product_rank <= 3
ORDER BY Country, product_rank;

-- Q15. Monthly sales comparison

WITH monthly_sales AS (
    SELECT DATE_FORMAT(InvoiceDate, '%Y-%m') AS month,
           SUM(Quantity * UnitPrice) AS total_sales
    FROM ecommerce
    WHERE Quantity > 0 AND UnitPrice > 0
    GROUP BY DATE_FORMAT(InvoiceDate, '%Y-%m')
)
SELECT month,
       total_sales,
       LAG(total_sales) OVER (
           ORDER BY month
       ) AS previous_month_sales
FROM monthly_sales
ORDER BY month;



-- Q16. Top 5 countries by total sales

SELECT Country,
       SUM(Quantity * UnitPrice) AS total_sales
FROM ecommerce
WHERE Quantity > 0 AND UnitPrice > 0
GROUP BY Country
ORDER BY total_sales DESC
LIMIT 5;



-- Q17. Top 10 customers by spending

SELECT CustomerID,
       SUM(Quantity * UnitPrice) AS total_spending
FROM ecommerce
WHERE CustomerID IS NOT NULL
  AND Quantity > 0 AND UnitPrice > 0
GROUP BY CustomerID
ORDER BY total_spending DESC
LIMIT 10;

-- Q18. Top 10 products by revenue

SELECT StockCode,
       MAX(Description) AS product_name,
       SUM(Quantity * UnitPrice) AS revenue
FROM ecommerce
WHERE Quantity > 0 AND UnitPrice > 0
GROUP BY StockCode
ORDER BY revenue DESC
LIMIT 10;


-- Q19. Highest revenue month and monthly growth

WITH monthly_sales AS (
    SELECT DATE_FORMAT(InvoiceDate, '%Y-%m') AS month,
           SUM(Quantity * UnitPrice) AS revenue
    FROM ecommerce
    WHERE Quantity > 0 AND UnitPrice > 0
    GROUP BY DATE_FORMAT(InvoiceDate, '%Y-%m')
),
sales_comparison AS (
    SELECT month,
           revenue,
           LAG(revenue) OVER (
               ORDER BY month
           ) AS previous_revenue
    FROM monthly_sales
)
SELECT month,
       revenue,
       previous_revenue,
       revenue - previous_revenue AS sales_change,
       ROUND(
           (revenue - previous_revenue)
           / NULLIF(previous_revenue, 0) * 100, 2
       ) AS growth_percentage
FROM sales_comparison
ORDER BY revenue DESC;


-- Q20. Three business insights

/*
1. The United Kingdom generates the highest sales
   revenue. The company should focus on this market.

2. High-spending customers should be retained
   through loyalty programmes and special offers.

3. High-revenue products should be stocked
   adequately and promoted to increase sales.
*/










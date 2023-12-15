USE GDB023;

-- 1. Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.
SELECT DISTINCT(market) FROM DIM_CUSTOMER
WHERE CUSTOMER = 'Atliq Exclusive' AND REGION = 'APAC';


-- 2. What is the percentage of unique product increase in 2021 vs. 2020?
WITH UP21 AS(
	SELECT COUNT(DISTINCT(D.PRODUCT_CODE)) AS UNIQUE_PRODUCTS_2021,FISCAL_YEAR FROM DIM_PRODUCT D
    INNER JOIN FACT_SALES_MONTHLY S USING(PRODUCT_CODE)
    WHERE S.FISCAL_YEAR = '2021'
    ),
UP20 AS(
	SELECT COUNT(DISTINCT(D.PRODUCT_CODE)) AS UNIQUE_PRODUCTS_2020,FISCAL_YEAR FROM DIM_PRODUCT D
    INNER JOIN FACT_SALES_MONTHLY S USING(PRODUCT_CODE)
    WHERE S.FISCAL_YEAR = '2020'
    ) 
SELECT UP20.UNIQUE_PRODUCTS_2020,UP21.UNIQUE_PRODUCTS_2021,
	   ROUND(((UP21.UNIQUE_PRODUCTS_2021-UP20.UNIQUE_PRODUCTS_2020)/UP20.UNIQUE_PRODUCTS_2020)*100,2) AS PERCENT_INCREASE FROM UP21
INNER JOIN UP20;
    
    
-- 3. Provide a report with all the unique product counts for each segment and sort them in descending order of product counts.
SELECT SEGMENT, COUNT(DISTINCT(PRODUCT_CODE)) AS COUNT_UNIQUE_PRODUCTS 
FROM DIM_PRODUCT
GROUP BY 1 ORDER BY 2 DESC;

-- 4. Follow-up: Which segment had the most increase in unique products in 2021 vs 2020?
WITH UP20 AS(
	SELECT SEGMENT,COUNT(DISTINCT(D.PRODUCT_CODE)) AS UNIQUE_PRODUCTS_2020 FROM DIM_PRODUCT D
    INNER JOIN FACT_SALES_MONTHLY S USING(PRODUCT_CODE)
    WHERE S.FISCAL_YEAR = '2020'
    GROUP BY 1 ORDER BY 2 DESC
    ),
UP21 AS(
	SELECT SEGMENT,COUNT(DISTINCT(D.PRODUCT_CODE)) AS UNIQUE_PRODUCTS_2021 FROM DIM_PRODUCT D
    INNER JOIN FACT_SALES_MONTHLY S USING(PRODUCT_CODE)
    WHERE S.FISCAL_YEAR = '2021'
    GROUP BY 1 ORDER BY 2 DESC
    ) 
SELECT UP21.SEGMENT, UP20.UNIQUE_PRODUCTS_2020, UP21.UNIQUE_PRODUCTS_2021, 
(UP21.UNIQUE_PRODUCTS_2021-UP20.UNIQUE_PRODUCTS_2020) AS DIFFERENCE
FROM UP21 INNER JOIN UP20 USING(SEGMENT);

-- 5. Get the products that have the highest and lowest manufacturing costs.
SELECT D.PRODUCT_CODE, D.PRODUCT, ROUND(F.MANUFACTURING_COST,2) AS 'MANUFACTURING_COST (IN $)' 
FROM DIM_PRODUCT D
INNER JOIN FACT_MANUFACTURING_COST F USING(PRODUCT_CODE)
WHERE F.MANUFACTURING_COST IN 
(
( SELECT MAX(F.MANUFACTURING_COST)FROM FACT_MANUFACTURING_COST F),
( SELECT MIN(F.MANUFACTURING_COST)FROM FACT_MANUFACTURING_COST F)
)
GROUP BY 1,2,3 ORDER BY 3 DESC;


-- 6. Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct 
-- for the fiscal year 2021 and in the Indian market.
SELECT C.CUSTOMER_CODE,C.CUSTOMER, ROUND(AVG(I.PRE_INVOICE_DISCOUNT_PCT),3) AS 'AVG_DISCOUNT_PCT (IN $)'
FROM DIM_CUSTOMER C
INNER JOIN FACT_PRE_INVOICE_DEDUCTIONS I USING(CUSTOMER_CODE)
WHERE I.FISCAL_YEAR = '2021' AND C.MARKET = 'INDIA' 
AND I.PRE_INVOICE_DISCOUNT_PCT > 
		( SELECT ROUND(AVG(I.PRE_INVOICE_DISCOUNT_PCT),3) AS 'AVG_PRE_INVOICE_DISCOUNT_PCT (IN $)' 
        FROM FACT_PRE_INVOICE_DEDUCTIONS I)
GROUP BY 1,2 ORDER BY 3 DESC LIMIT 5;

-- 7. Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month. 
-- This analysis helps to get an idea of low and high-performing months and take strategic decisions.
SELECT MONTHNAME(SM.DATE) AS MONTH, SM.FISCAL_YEAR AS YEAR, 
CONCAT(SUM(ROUND((GP.GROSS_PRICE*SM.SOLD_QUANTITY)/1000000,2)),'M$') 
AS GROSS_SALES_AMOUNT
FROM FACT_SALES_MONTHLY SM
INNER JOIN FACT_GROSS_PRICE GP USING(FISCAL_YEAR)
INNER JOIN DIM_CUSTOMER DC USING(CUSTOMER_CODE)
WHERE CUSTOMER = 'ATLIQ EXCLUSIVE'
GROUP BY 1,2 ORDER BY 2;
  

-- 8. In which quarter of 2020, got the maximum total_sold_quantity?
SELECT  
CASE   WHEN MONTH(DATE) BETWEEN 1 AND 3 THEN 'Q1'
       WHEN MONTH(DATE) BETWEEN 4 AND 6 THEN 'Q2'
       WHEN MONTH(DATE) BETWEEN 7 AND 9 THEN 'Q3'
       ELSE 'Q4'
  END AS QUARTER,
CONCAT(ROUND(SUM(SOLD_QUANTITY/1000000),2),'M') AS TOTAL_QUANTITY_SOLD FROM FACT_sALES_MONTHLY
WHERE FISCAL_YEAR = '2020'
GROUP BY 1 ORDER BY 1;

-- 9. Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution?
WITH CGS AS
(SELECT DC.CHANNEL, CONCAT(SUM(ROUND((GP.GROSS_PRICE*SM.SOLD_QUANTITY)/1000000,2)),' M$') AS GROSS_SALES
FROM FACT_SALES_MONTHLY SM
INNER JOIN FACT_GROSS_PRICE GP USING(PRODUCT_CODE)
INNER JOIN DIM_CUSTOMER DC USING(CUSTOMER_CODE)
WHERE SM.FISCAL_YEAR = '2021'
GROUP BY 1 ORDER BY 2 DESC)
SELECT *,CONCAT(FORMAT(GROSS_SALES*100/SUM(GROSS_SALES) OVER(),2),'%') AS PCT FROM CGS
GROUP BY 1 ORDER BY 3 DESC;


-- 10. Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021?
WITH P AS
(	SELECT DIVISION,PRODUCT_CODE,PRODUCT,SUM(SOLD_QUANTITY) AS SOLD_QUANTITY FROM DIM_PRODUCT
	INNER JOIN FACT_SALES_MONTHLY USING(PRODUCT_CODE)
	WHERE FISCAL_YEAR = '2021' GROUP BY 1,2,3 ORDER BY 3 DESC),
PR AS
( SELECT *, DENSE_RANK() OVER(PARTITION BY DIVISION ORDER BY SOLD_QUANTITY DESC) AS RANKS FROM P)
SELECT * FROM PR WHERE RANKS < 4;




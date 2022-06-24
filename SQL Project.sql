--- Analysis
-- 1.
SELECT a.[Product_Category], a.[Product_Sub_Category], a.[Prod_id], b.[Ord_id], b.[Ship_id], b.[Cust_id], b.[Sales], b.[Discount], b.[Order_Quantity],
b.[Product_Base_Margin], c.[Order_Date], c.[Order_Priority], d.[Customer_Name], d.[Province], d.[Region], d.[Customer_segment],
e.[Order_ID], e.[Ship_Mode], e.[Ship_Date] 
INTO combined_table
FROM prod_dimen$ a JOIN market_fact$ b
	ON a.Prod_id = b.Prod_id 
JOIN orders_dimen c
	ON b.Ord_id = c.Ord_id
JOIN cust_dimen d
	ON b.Cust_id = d.Cust_id
JOIN shipping_dimen e
	ON b.Ship_id = e.Ship_id; 

-- 2. 
SELECT TOP 3 Customer_name, order_quantity
FROM combined_table
GROUP BY order_quantity, customer_name
ORDER BY order_quantity DESC;

-- 3.
ALTER TABLE combined_table
ADD [DaysTakenForDelivery] AS DATEDIFF(DAY, Order_Date, Ship_Date) PERSISTED

SELECT DaysTakenForDelivery
FROM combined_table;

-- 4.
SELECT TOP 1 Customer_Name, DaysTakenForDelivery
FROM combined_table
GROUP BY Customer_Name, DaysTakenForDelivery
ORDER BY DaysTakenForDelivery DESC;

-- 5.
select * from combined_table

SELECT DISTINCT Customer_Name
FROM combined_table
WHERE (MONTH(Order_Date) = 01)
AND (YEAR(Order_Date) = 2011)
GROUP BY Customer_Name

SELECT Customer_Name
FROM combined_table
GROUP BY Customer_Name 
HAVING COUNT(DISTINCT DATEPART(MONTH, Order_Date))
     = (SELECT COUNT(DISTINCT DATEPART(MONTH, Order_Date)) from combined_table);

-- 6.

	WITH CTE1 AS(
	SELECT Customer_Name, MIN(Order_Date) AS FirstOrder
	FROM combined_table
	GROUP BY Customer_Name)
	SELECT DISTINCT x.Customer_Name, CTE1.FirstOrder, Order_Date AS ThirdOrder
	FROM combined_table AS x JOIN CTE1
		ON x.Customer_Name = CTE1.Customer_Name
	WHERE order_date =
		(SELECT MIN(Order_Date)
		FROM combined_table
		WHERE Customer_Name = x.Customer_Name 
		AND Order_Date > 
			(SELECT  MIN(Order_Date)
			FROM combined_table
			WHERE Customer_Name = x.Customer_Name
			AND Order_Date > 
				(SELECT  MIN(Order_Date)
				FROM combined_table
				WHERE Customer_Name = x.Customer_Name)));

-- 7.
/* SELECT Customer_Name, COUNT(Order_ID) AS OrderNum
FROM combined_table
GROUP BY Customer_Name
ORDER BY Customer_Name -- This is right

SELECT Customer_Name, Prod_id, COUNT(Order_ID) AS Orders
FROM combined_table
WHERE Prod_id = 'Prod_11'
OR Prod_id = 'Prod_14'
GROUP BY Customer_Name, Prod_id -- This should be right too */

WITH CTE2 AS(
SELECT Customer_Name, Prod_id, COUNT(Order_ID) AS SpecificOrders
FROM combined_table
WHERE Prod_id = 'Prod_11'
OR Prod_id = 'Prod_14'
GROUP BY Customer_Name, Prod_id)
SELECT combined_table.Customer_Name, COUNT(Order_ID) AS TotalOrders, CTE2.SpecificOrders,
	(SELECT CTE2.SpecificOrders * 1.0 /COUNT(Order_ID)) AS RatioOfOrders
FROM combined_table JOIN CTE2
	ON combined_table.Customer_Name = CTE2.Customer_Name
GROUP BY combined_table.Customer_Name, CTE2.SpecificOrders
ORDER BY combined_table.Customer_Name;

--- Customer Segmentation
-- Grouping customers by how many orders placed
WITH CTE3 AS
(SELECT COUNT(Order_ID) AS OrderCount, Customer_Name FROM combined_table GROUP BY Customer_Name)
SELECT combined_table.Customer_Name, CASE
	WHEN (SELECT COUNT(Order_ID) FROM combined_table GROUP BY Customer_Name) >= AVG(ordercount)
		THEN 'Regular'
	WHEN (SELECT COUNT(Order_ID) FROM combined_table GROUP BY Customer_Name) < AVG(ordercount) 
		THEN 'Non Regular'
	END AS Customer_Label
FROM combined_table JOIN CTE3
	ON combined_table.customer_name = cte3.customer_name
GROUP BY combined_table.Customer_Name;

--- Retention Rate
SELECT Customer_Name, DATEPART(Month, Order_Date) AS OrderMonth
FROM combined_table
GROUP BY Customer_Name, 
DATEPART(Month, Order_Date);

SELECT Customer_Name, min(DATEPART(MONTH, Order_Date)) AS First
FROM combined_table
GROUP BY Customer_Name;

Select m.Customer_Name, m.Login_Month, n.First as First
FROM (SELECT Customer_Name, DATEPART(MONTH,Order_Date) AS Login_Month
	FROM combined_table GROUP BY Customer_Name, DATEPART(Month,Order_Date)) m,
(SELECT Customer_Name, MIN(DATEPART(MONTH, Order_Date)) AS First
FROM combined_table GROUP BY Customer_Name) n
WHERE m.Customer_Name = n.Customer_Name;

SELECT m.Customer_Name, m.Login_Month, n.First as First, m.login_Month - First AS Month_number 
FROM (SELECT Customer_Name, DATEPART(MONTH, Order_Date) AS Login_Month
FROM combined_table
GROUP BY Customer_Name, DATEPART(MONTH, Order_Date)) m,
(SELECT Customer_Name, MIN(DATEPART(Month, Order_Date)) AS FIRST
FROM combined_table
GROUP BY Customer_Name) n
WHERE m.Customer_Name = n.Customer_Name;

SELECT First,
SUM(CASE WHEN Month_number = 0 THEN 1 ELSE 0 END) AS Month_0,
SUM(CASE WHEN Month_number = 1 THEN 1 ELSE 0 END) AS Month_1,
SUM(CASE WHEN month_number = 2 THEN 1 ELSE 0 END) AS Month_2,
SUM(CASE WHEN Month_number = 3 THEN 1 ELSE 0 END) AS Month_3,
SUM(CASE WHEN Month_number = 4 THEN 1 ELSE 0 END) AS Month_4,
SUM(CASE WHEN Month_number = 5 THEN 1 ELSE 0 END) AS Month_5,
SUM(CASE WHEN Month_number = 6 THEN 1 ELSE 0 END) AS Month_6,
SUM(CASE WHEN Month_number = 7 THEN 1 ELSE 0 END) AS Month_7,
SUM(CASE WHEN Month_number = 8 THEN 1 ELSE 0 END) AS Month_8,
SUM(CASE WHEN Month_number = 9 THEN 1 ELSE 0 END) AS Month_9,
SUM(CASE WHEN Month_number = 10 THEN 1 ELSE 0 END) AS Month_10,
SUM(CASE WHEN Month_number = 11 THEN 1 ELSE 0 END) AS Month_11
FROM (SELECT m.Customer_Name, m.login_Month, n.First as First,
m.login_Month - First as Month_Number 
FROM (SELECT Customer_Name, DATEPART(MONTH, Order_date) AS Login_Month
FROM combined_table 
GROUP BY Customer_Name, DATEPART(Month, Order_Date)) m,
(SELECT Customer_Name, min(DATEPART(Month, Order_Date)) AS First
FROM combined_table 
GROUP BY Customer_Name) n WHERE m.Customer_Name = n.Customer_Name)
AS With_Month_Number
GROUP BY First
ORDER By First;
/*
1. Monthly Spending Rankings
Identify the top-spending customers each month using rankings.
*/

WITH customers_total_spending_per_month AS (
SELECT 
  customer_id, 
  TO_CHAR(DATE_TRUNC('month', invoice_date), 'YYYY-MM') AS invoice_month,
  SUM(total) AS total_spendings
FROM invoice
GROUP BY customer_id, TO_CHAR(DATE_TRUNC('month', invoice_date), 'YYYY-MM')
ORDER BY invoice_month
)

SELECT *
FROM (
  SELECT 
    customer_id,
    CONCAT(first_name, ' ', last_name) AS customer,
    invoice_month,
    total_spendings,
    DENSE_RANK() OVER(PARTITION BY invoice_month ORDER BY total_spendings DESC) AS monthly_customer_rank
  FROM customers_total_spending_per_month
  JOIN customer
  USING(customer_id))
WHERE monthly_customer_rank BETWEEN 1 AND 3


/*
2. Sales Trends Analysis
Track monthly sales and compare trends over time.
*/

WITH total_spending_per_month AS (
SELECT 
  TO_CHAR(DATE_TRUNC('month', invoice_date), 'YYYY-MM') AS month,
  SUM(Total) AS total_spendings
FROM invoice
GROUP BY TO_CHAR(DATE_TRUNC('month', invoice_date), 'YYYY-MM')
ORDER BY TO_CHAR(DATE_TRUNC('month', invoice_date), 'YYYY-MM')
)

SELECT 
  month,
  total_spendings,
  total_spendings - LAG(total_spendings) OVER(ORDER BY month) AS prev_month_spending_diff
FROM total_spending_per_month
ORDER BY month

/*
3. Longest Gaps Between Purchases**  
Find the longest time gaps between customer purchases.
*/

SELECT *
FROM (
SELECT 
    customer_id, 
    CONCAT(first_name, ' ', last_name) AS customer_name,
    invoice_date, 
    LAG(invoice_date) OVER(PARTITION BY customer_id ORDER BY invoice_date) AS previous_invoice_date,
    invoice_date - LAG(invoice_date) OVER(PARTITION BY customer_id ORDER BY invoice_date) AS time_diff_from_last_invoice
  FROM invoice
  JOIN customer
  USING(customer_id)
  ORDER BY time_diff_from_last_invoice DESC)
WHERE previous_invoice_date IS NOT NULL

/*
4. **Analiza długości tytułów utworów**  
   Napisz zapytanie, które zwróci:
   - Identyfikator utworu i jego tytuł.
   - Długość tytułu (liczba znaków).
   - Łączną liczbę sprzedaży dla utworu.
   - Ranking utworów na podstawie długości tytułów i ich sprzedaży.
*/

WITH track_total_sale AS (
  SELECT
    track_id,
    SUM(quantity) AS total_sale
  FROM invoice_line
  GROUP BY track_id
)
/*
ponizej 10
od 10 do
*/
SELECT 
  track_id,
  name AS track_name,
  LENGTH(name) AS track_name_length,
  total_sale,
  RANK() OVER(PARTITION BY LENGTH(name) ORDER BY total_sale DESC) AS track_rank
FROM track_total_sale
JOIN track
USING(track_id)
ORDER BY track_rank

SELECT 
name,
LENGTH(name) AS length
FROM track
ORDER BY length DESC

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
4. Track Title Lengths and Sales
Analyze the relationship between track title lengths and sales.
*/

WITH track_total_sale AS (
  SELECT
    track_id,
    SUM(quantity) AS total_sale
  FROM invoice_line
  GROUP BY track_id
), track_title_lengths AS(
  SELECT 
    track_id,
    name,
    CASE
      WHEN LENGTH(name) <= 10 THEN 'very short'
      WHEN LENGTH(name) <= 30 THEN 'short'
      WHEN LENGTH(name) <= 60 THEN 'medium'
      WHEN LENGTH(name) <= 100 THEN 'long'
      ELSE 'very long'
    END AS title_length
    FROM track
)

SELECT 
  title_length,
  ROUND(AVG(total_sale), 3) AS average_sale
FROM track_total_sale
JOIN track_title_lengths
USING(track_id)
GROUP BY title_length
ORDER BY average_sale DESC

/*
5. Keyword Analysis in Track Titles*
Identify the most common words in track titles and their sales impact.
*/

WITH top_track_words AS (
  SELECT 
    words_in_tracks, 
    COUNT(words_in_tracks) AS words_counted
  FROM (
    SELECT
    REGEXP_REPLACE(LOWER(REGEXP_SPLIT_TO_TABLE(name, ' |/')), '[^a-zA-Z0-9 ]', '', 'g') AS words_in_tracks
  FROM track
  ) AS split
  -- deleting stop words without semantic value
  WHERE words_in_tracks NOT IN ('', 'the', 'of', 'a', 'in', 'to', 'no', 'on', 'do', 'de', 'and', 'for', 'o', 'it', 'da', 'is', 'be', 'all', '2', 'e', 'pt', 'from', 'with')
  GROUP BY words_in_tracks
  HAVING COUNT(words_in_tracks) >= 25
  ORDER BY words_counted DESC
)

SELECT 
  words_in_tracks,
  words_counted,
  COUNT(DISTINCT(track_id)) AS unique_track_count,
  SUM(quantity) AS total_sale
FROM top_track_words
JOIN track
ON track.name ~* CONCAT('\m', words_in_tracks, '\M(?!'')')
JOIN invoice_line
USING(track_id)
GROUP BY words_in_tracks, words_counted
ORDER BY unique_track_count DESC

/*
6. Highest Average Invoice Value
Rank customers by their average invoice value.
*/

SELECT *
FROM (
  SELECT 
    customer_id,
    CONCAT(first_name, ' ', last_name) AS customer,
    ROUND(AVG(total), 3) AS total_avg,
    DENSE_RANK() OVER(ORDER BY ROUND(AVG(total), 3) DESC) AS customer_rank
  FROM customer
  JOIN invoice
  USING(customer_id)
  GROUP BY customer_id, first_name, last_name
  ORDER BY total_avg DESC)
WHERE customer_rank BETWEEN 1 AND 5

/*
7. Seasonality of Sales
Analyze monthly sales distribution and seasonal patterns.
*/

SELECT 
  invoice_date,
  SUM(total) AS total_month_sale,
  ROUND(SUM(total) / (SELECT SUM(total) FROM invoice) * 100, 3) AS percentage_of_total_sale
FROM
  (SELECT 
    TO_CHAR(DATE_TRUNC('month', invoice_date), 'YYYY-MM') AS invoice_date,
    total
  FROM invoice) AS month_sale
GROUP BY invoice_date
ORDER BY invoice_date

/*
8. Category Sales Contribution
Calculate each category’s percentage contribution to total sales.
*/

WITH total_genre_sale AS (
  SELECT SUM(unit_price * quantity) AS total_sale_value
  FROM invoice_line
)

SELECT 
  genre_name,
  genre_sale_value,
  ROUND(genre_sale_value / total_sale_value * 100, 2) AS percentage_of_total_sale_value
FROM (
  SELECT 
    genre.name AS genre_name,
    SUM(invoice_line.unit_price * quantity) AS genre_sale_value
  FROM genre
  JOIN track
  USING(genre_id)
  JOIN invoice_line
  USING(track_id)
  GROUP BY genre.name) AS genre_sale_value
CROSS JOIN total_genre_sale
ORDER BY percentage_of_total_sale_value DESC

/*
9. Customer Spending Declines
Identify customers whose monthly spending has decreased over time.
*/

WITH customer_monthly_spending AS (
  SELECT 
    customer_id,
    CONCAT(first_name, ' ', last_name) AS customer_name,
    TO_CHAR(DATE_TRUNC('month', invoice_date), 'YYYY-MM') AS invoice_month,
    SUM(total) AS monthly_spending
  FROM customer
  JOIN invoice
  USING(customer_id)
  GROUP BY customer_id, first_name, last_name, invoice_date)

SELECT 
  customer_id, 
  customer_name, 
  invoice_month, 
  monthly_spending,
  LAG(invoice_month) OVER(PARTITION BY customer_id ORDER BY invoice_month) AS previous_invoice_month,
  LAG(monthly_spending) OVER(PARTITION BY customer_id ORDER BY invoice_month) AS previous_monthly_spending,
  monthly_spending - LAG(monthly_spending) OVER(PARTITION BY customer_id ORDER BY invoice_month) AS difference_previous_monthly_spending
FROM customer_monthly_spending
ORDER BY difference_previous_monthly_spending
LIMIT 10;

/*
10. Track Length vs. Sales
Evaluate the correlation between track length and sales.
*/

SELECT corr(track_length_seconds, track_sale) AS track_length_sale_correlation
FROM (
  SELECT 
    milliseconds / 1000 AS track_length_seconds,
    SUM(invoice_line.unit_price * quantity) AS track_sale
  FROM track
  JOIN invoice_line
  USING(track_id)
  GROUP BY milliseconds / 1000 
) AS track_sale_by_length

/*
12. Best-Selling Albums
Determine the top revenue-generating albums.
*/

SELECT 
  album_id,
  SUM(invoice_line.unit_price * quantity) AS total_album_revenue
FROM album
JOIN track
USING(album_id)
JOIN invoice_line
USING(track_id)
GROUP BY album_id
ORDER BY total_album_revenue DESC
LIMIT 10;

/*
13. **Purchase Patterns by Weekday**  
Analyze the distribution of purchases by day of the week.
*/

WITH total_invoices AS (
  SELECT
    COUNT(invoice_id) AS total_count
  FROM invoice
)

SELECT
  TO_CHAR(invoice_date, 'Day') AS invoice_day,
  ROUND(COUNT(invoice_id) * 100.0/total_count, 2) AS invoice_percentage
FROM invoice
CROSS JOIN total_invoices
GROUP BY TO_CHAR(invoice_date, 'Day'), total_count
ORDER BY invoice_percentage DESC


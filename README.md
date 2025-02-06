# Chinook Database Analysis

## Summary 📊
This analysis explores customer spending behavior, sales trends, and purchasing patterns using SQL queries on the Chinook database. The findings highlight key insights into revenue-driving factors, customer retention, and product performance.

## Overview 🔍
The Chinook database provides a comprehensive dataset of customer transactions, products, and sales records. Using SQL queries, this project investigates various business metrics, including top customers, sales seasonality, and the impact of product attributes on revenue. Visualizations and statistical summaries further support the findings.

## Objectives 🎯

1. Identify high-value customers and their spending habits.
2. Analyze sales trends and seasonality.
3. Understand purchasing patterns across different time periods.
4. Evaluate product attributes and their influence on sales.
5. Assess customer retention and loyalty metrics.

---

## Tasks ✅

### 1. Monthly Spending Rankings
**Task:** Identify the top-spending customers each month using rankings.\
**Query:**

```sql
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
WHERE monthly_customer_rank BETWEEN 1 AND 3;
```
**Results:**
|   customer_id | customer           | invoice_month   |   total_spendings |   monthly_customer_rank |
|--------------:|:-------------------|:----------------|------------------:|------------------------:|
|            23 | John Gordon        | 2021-01         |             13.86 |                       1 |
|            14 | Mark Philips       | 2021-01         |              8.91 |                       2 |
|             8 | Daan Peeters       | 2021-01         |              5.94 |                       3 |
|             2 | Leonie Köhler      | 2021-02         |             13.86 |                       1 |
|            52 | Emma Jones         | 2021-02         |              8.91 |                       2 |
|            46 | Hugh O'Reilly      | 2021-02         |              5.94 |                       3 |
|            40 | Dominique Lefebvre | 2021-03         |             13.86 |                       1 |
|            31 | Martha Silk        | 2021-03         |              8.91 |                       2 |
|            25 | Victor Stevens     | 2021-03         |              5.94 |                       3 |

![Monthly Spending Ranking](assets/1.png)
*Bar graph visualizing the top-spending customers each month using rankings; ChatGPT generated this graph from SQL query results.*

### 2. Sales Trends Analysis**

**Task:** Track monthly sales and compare trends over time.

**Query:**

```sql
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
ORDER BY month;
```
**Results:**

| month   |   total_spendings |   prev_month_spending_diff |
|:--------|------------------:|---------------------------:|
| 2021-12 |             37.62 |                          0 |
| 2022-01 |             52.62 |                         15 |
| 2022-02 |             46.62 |                         -6 |
| 2022-03 |             44.62 |                         -2 |
| 2022-04 |             37.62 |                         -7 |
| 2022-05 |             37.62 |                          0 |

![Monthly Spending Differences](assets/2_1.png)
*Bar graph visualizing the sales trends analysis - monthly spedning differences; ChatGPT generated this graph from SQL query results.*

![Monthly Spending Over Tine](assets/2_2.png)
*Line graph visualizing the sales trends analysis - monthly spedning over time; ChatGPT generated this graph from SQL query results.*

### 3. Longest Gaps Between Purchases**

**Task:** Find the longest time gaps between customer purchases.

**Query:**

```sql
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
WHERE previous_invoice_date IS NOT NULL;
```
**Results:**

| customer_id | customer_name         | invoice_date       | previous_invoice_date | time_diff_from_last_invoice |
|------------|----------------------|--------------------|----------------------|----------------------------|
| 48         | Johannes Van der Berg | 2022-12-15        | 2021-05-10           | {"days": 584}              |
| 45         | Ladislav Kovács       | 2024-05-25        | 2022-10-19           | {"days": 584}              |
| 4          | Bjørn Hansen          | 2025-10-03        | 2024-02-27           | {"days": 584}              |
| 12         | Roberto Almeida       | 2025-03-31        | 2023-08-25           | {"days": 584}              |
| 3          | François Tremblay     | 2024-07-26        | 2022-12-20           | {"days": 584}              |

### 4. Track Title Lengths and Sales**

**Task:** Analyze the relationship between track title lengths and sales.

**Query:**

```sql
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
ORDER BY average_sale DESC;
```
**Results:**
| Title Length  | Average Sale |
|--------------|--------------|
| Long         | 1.200        |
| Short        | 1.131        |
| Medium       | 1.125        |
| Very Short   | 1.125        |
| Very Long    | 1.000        |

![Average Sales by Title Length](assets/4.png)
*Bar graph visualizing the relationship between track title lengths and sales; ChatGPT generated this graph from SQL query results.*

### 5. Keyword Analysis in Track Titles**

**Task:** Identify the most common words in track titles and their sales impact.
**Query:**

```sql
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
ORDER BY unique_track_count DESC;
```
**Results:**

| Word  | Words Counted | Unique Track Count | Total Sale |
|-------|--------------|--------------------|------------|
| You   | 129          | 80                 | 82         |
| I     | 111          | 66                 | 73         |
| Love  | 103          | 59                 | 69         |
| Me    | 88           | 52                 | 58         |
| My    | 68           | 33                 | 35         |

![Most Frequent Words in Tracks: Sales and Occurrences](assets/5.png)
*Bar graph visualizing the most frequent words in tracks: sales and occurrences; ChatGPT generated this graph from SQL query results.*

### 6. Highest Average Invoice Value**

**Task:** Rank customers by their average invoice value.

**Query:**

```sql
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
WHERE customer_rank BETWEEN 1 AND 5;
```
**Results:**

| Customer ID | Customer               | Average Invoice Value | Customer Rank |
|------------|------------------------|-----------------------|--------------|
| 6          | Helena Holý            | 7.089                 | 1            |
| 26         | Richard Cunningham     | 6.803                 | 2            |
| 57         | Luis Rojas             | 6.660                 | 3            |
| 45         | Ladislav Kovács        | 6.517                 | 4            |
| 46         | Hugh O'Reilly          | 6.517                 | 4            |
| 28         | Julia Barnett          | 6.231                 | 5            |
| 37         | Fynn Zimmermann        | 6.231                 | 5            |
| 24         | Frank Ralston          | 6.231                 | 5            |

![ Highest Average Invoice Value](assets/6.png)
*Bar graph visualizing customers with highest average invoice value; ChatGPT generated this graph from SQL query results.*

### 7. Seasonality of Sales**

**Task:** Analyze monthly sales distribution and seasonal patterns.

**Query:**

```sql
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
ORDER BY invoice_date;
```
**Resutls:**

| Invoice Date | Total Monthly Sales | Percentage of Total Sales |
|-------------|---------------------|--------------------------|
| 2021-01     | 35.64               | 1.531%                   |
| 2021-02     | 37.62               | 1.616%                   |
| 2021-03     | 37.62               | 1.616%                   |
| 2021-04     | 37.62               | 1.616%                   |
| 2021-05     | 37.62               | 1.616%                   |

![Seasonality of Sales](assets/7.png)
*Line graph visualizing seasonality of sales; ChatGPT generated this graph from SQL query results.*

### 8. Category Sales Contribution**

**Task:** Calculate each category’s percentage contribution to total sales.

**Query:**

```sql
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
ORDER BY percentage_of_total_sale_value DESC;
```
**Results:**

| Category Name         | Sales Value | Percentage of Total Sales |
|----------------------|------------|---------------------------|
| Rock                | 826.65     | 35.50%                    |
| Latin               | 382.14     | 16.41%                    |
| Metal               | 261.36     | 11.22%                    |
| Alternative & Punk  | 241.56     | 10.37%                    |
| TV Shows           | 93.53      | 4.02%                     |

![Category Sales Contribution](assets/8.png)
*Bar and line graph visualizing sales and percentage of total sales per category; ChatGPT generated this graph from SQL query results.*

### 9. Customer Spending Declines**

**Task:** Identify customers whose monthly spending has decreased over time.
**Query:**

```sql
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
```
**Results:**
| Customer ID | Customer Name         | Invoice Month | Monthly Spending | Previous Invoice Month | Previous Monthly Spending | Spending Decline |
|------------|-----------------------|--------------|------------------|------------------------|--------------------------|------------------|
| 57         | Luis Rojas             | 2023-08      | 1.98             | 2022-01                | 17.91                     | -15.93           |
| 26         | Richard Cunningham     | 2025-04      | 8.91             | 2024-08                | 23.86                     | -14.95           |
| 45         | Ladislav Kovács        | 2022-10      | 8.91             | 2022-02                | 21.86                     | -12.95           |
| 46         | Hugh O'Reilly          | 2023-12      | 8.91             | 2023-04                | 21.86                     | -12.95           |
| 37         | Fynn Zimmermann        | 2024-11      | 1.98             | 2023-04                | 14.91                     | -12.93           |

![Customer Spending Declines Over Time](assets/9.png)
*Bar graph visualizing the customer spending declines; ChatGPT generated this graph from SQL query results.*

### 10. Track Length vs. Sales**

**Task:** Evaluate the correlation between track length and sales.

**Query:**

```sql
SELECT corr(track_length_seconds, track_sale) AS track_length_sale_correlation
FROM (
  SELECT 
    milliseconds / 1000 AS track_length_seconds,
    invoice_line.unit_price * quantity AS track_sale
  FROM track
  JOIN invoice_line
  USING(track_id)
) AS track_sale_by_length;
```
**Results:**
| Track Length & Sale Coreelation  | 
|------------|
| 0.9335378478105226         |
---

### 11. Rarest Customers**

**Task:** Identify customers who have made the fewest purchases.

**Query:**

```sql
SELECT 
  customer_id,
  CONCAT(first_name, ' ', last_name) AS least_frequent_customer,
  COUNT(invoice_id) AS number_of_purchases
FROM invoice
JOIN customer
USING(customer_id)
GROUP BY customer_id, first_name, last_name
ORDER BY number_of_purchases
LIMIT 1;
```
**Results:**
| Customer ID | Least Frequent Customer | Number of Purchases |
|-------------|-------------------------|---------------------|
| 59          | Puja Srivastava          | 6                   |


### 12. Best-Selling Albums**

**Task:** Determine the top revenue-generating albums.

**Query:**

```sql
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
```
**Results:**
| Album ID | Total Album Revenue |
|----------|---------------------|
| 253      | 35.82               |
| 251      | 31.84               |
| 23       | 26.73               |
| 231      | 25.87               |
| 228      | 25.87               |
| 141      | 25.74               |
| 73       | 24.75               |
| 227      | 23.88               |
| 229      | 21.89               |
| 224      | 21.78               |


### 13. Purchase Patterns by Weekday**

**Task:** Analyze the distribution of purchases by day of the week.

**Query:**

```sql
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
ORDER BY invoice_percentage DESC;
```
**Results:**
| Invoice Day | Invoice Percentage |
|-------------|--------------------|
| Monday      | 14.56              |
| Thursday    | 14.32              |
| Tuesday     | 14.32              |
| Saturday    | 14.32              |
| Friday      | 14.32              |
| Wednesday   | 14.08              |
| Sunday      | 14.08              |

![Distribution of Purchases by Day of the Week](assets/13.png)
*Bar graph visualizing the distribution of purchases by day of the week; ChatGPT generated this graph from SQL query results.*

### 14. Most Active Customers**

**Task:** Find customers who purchased the most tracks.

**Query:**

```sql
SELECT 
  customer_id,
  CONCAT(first_name, ' ', last_name) AS customer_name,
  SUM(number_of_tracks) AS total_number_of_tracks,
  DENSE_RANK() OVER(ORDER BY SUM(number_of_tracks) DESC) AS customer_rank
FROM (
  SELECT 
    customer_id,
    invoice_id,
    COUNT(track_id) AS number_of_tracks
  FROM invoice_line
  JOIN invoice
  USING(invoice_id)
  GROUP BY customer_id, invoice_id) AS tracks_per_invoice
JOIN customer
USING(customer_id)
GROUP BY customer_id, first_name, last_name;
```
**Results:**
| Customer ID | Customer Name      | Total Number of Tracks | Customer Rank |
|-------------|--------------------|------------------------|---------------|
| 30          | Edward Francis     | 38                     | 1             |
| 34          | João Fernandes     | 38                     | 1             |
| 19          | Tim Goyer          | 38                     | 1             |
| 26          | Richard Cunningham | 38                     | 1             |
| 37          | Fynn Zimmermann    | 38                     | 1             |
| 55          | Mark Taylor        | 38                     | 1             |
| 46          | Hugh O'Reilly      | 38                     | 1             |
| 13          | Fernanda Ramos     | 38                     | 1             |
| 24          | Frank Ralston      | 38                     | 1             |
| 49          | Stanisław Wójcik   | 38                     | 1             |

### 15. Track Length Frequency**

**Task:** Group tracks by length ranges and analyze their occurrence.

**Query:**

```sql
WITH total_tracks AS (
  SELECT
    COUNT(track_id) AS number_of_tracks_total
  FROM track
)

SELECT
  lenth_category,
  COUNT(track_id) AS number_of_tracks,
  ROUND((COUNT(track_id) / number_of_tracks_total::numeric) * 100, 2) AS percentage_of_total
FROM(
  SELECT 
    track_id,
    CASE
      WHEN milliseconds / 1000 BETWEEN 0 AND 59 THEN 'Less than 1 minute'
      WHEN milliseconds / 1000 BETWEEN 60 AND 119 THEN 'Between 1 and 2 minutes'
      WHEN milliseconds / 1000 BETWEEN 120 AND 179 THEN 'Between 2 and 3 minutes'
      WHEN milliseconds / 1000 BETWEEN 180 AND 239 THEN 'Between 3 and 4 minutes'
      WHEN milliseconds / 1000 BETWEEN 240 AND 299 THEN 'Between 4 and 5 minutes'
      ELSE 'Over 5 minutes' END AS lenth_category
  FROM track) AS track_length_category
CROSS JOIN total_tracks
GROUP BY lenth_category, number_of_tracks_total
ORDER BY percentage_of_total DESC;
```
**Results:**
| Length Category                | Number of Tracks | Percentage of Total |
|---------------------------------|------------------|---------------------|
| Over 5 minutes                 | 1069             | 30.52               |
| Between 3 and 4 minutes        | 982              | 28.03               |
| Between 4 and 5 minutes        | 972              | 27.75               |
| Between 2 and 3 minutes        | 387              | 11.05               |
| Between 1 and 2 minutes        | 66               | 1.88                |
| Less than 1 minute             | 27               | 0.77                |

![Number of Tracks by Length Category](assets/15.png)
*Bar graph visualizing the number of tracks by length category; ChatGPT generated this graph from SQL query results.*

### 16. Top-Selling Genres**

**Task:** Identify the genres that generate the highest sales.

**Query:**

```sql
WITH total_tracks_sold AS(
  SELECT 
    SUM(quantity) AS number_of_tracks_sold_total
  FROM invoice_line
)

SELECT 
  genre_id,
  genre_name,
  number_of_tracks_sold,
  ROUND((number_of_tracks_sold / number_of_tracks_sold_total::numeric) * 100, 2) AS pertentage_of_market
FROM
  (SELECT 
    genre_id,
    genre.name AS genre_name,
    SUM(quantity) AS number_of_tracks_sold
  FROM invoice_line
  JOIN track
  USING(track_id)
  JOIN genre
  USING(genre_id)
  GROUP BY genre_id, genre.name) AS sale_by_category
CROSS JOIN total_tracks_sold
ORDER BY pertentage_of_market DESC;
```
**Results:**
| Genre ID | Genre Name        | Number of Tracks Sold | Percentage of Market |
|----------|-------------------|-----------------------|----------------------|
| 1        | Rock              | 835                   | 37.28                |
| 7        | Latin             | 386                   | 17.23                |
| 3        | Metal             | 264                   | 11.79                |
| 4        | Alternative & Punk | 244                   | 10.89                |
| 2        | Jazz              | 80                    | 3.57                 |
| 6        | Blues             | 61                    | 2.72                 |
| 19       | TV Shows          | 47                    | 2.10                 |
| 24       | Classical         | 41                    | 1.83                 |
| 14       | R&B/Soul          | 41                    | 1.83                 |
| 8        | Reggae            | 30                    | 1.34                 |

### 17. Order Value Analysis by Country**

**Task:** Analyze the average order value across different countries to identify high-spending regions and their contribution to total revenue.

**Query:**

```sql
WITH market_total_sale AS (
  SELECT
    SUM(total) AS total_sale
  FROM invoice
)

SELECT 
  billing_country,
  AVG(total) AS average_total_sale,
  COUNT(invoice_id) AS number_of_invoices,
  SUM(total) AS total_sale,
  ROUND((SUM(total) / market_total_sale.total_sale) * 100, 2) AS total_sale_percentrage_of_market
FROM invoice
CROSS JOIN market_total_sale
GROUP BY billing_country, market_total_sale.total_sale;
```
**Results:**
| Billing Country | Average Total Sale | Number of Invoices | Total Sale | Total Sale Percentage of Market |
|-----------------|--------------------|--------------------|------------|----------------------------------|
| India           | 5.79               | 13                 | 75.26      | 3.23                             |
| Finland         | 5.95               | 7                  | 41.62      | 1.79                             |
| Portugal        | 5.52               | 14                 | 77.24      | 3.32                             |
| United Kingdom  | 5.37               | 21                 | 112.86     | 4.85                             |
| Argentina       | 5.37               | 7                  | 37.62      | 1.62                             |
| Australia       | 5.37               | 7                  | 37.62      | 1.62                             |
| Canada          | 5.43               | 56                 | 303.96     | 13.05                            |
| Italy           | 5.37               | 7                  | 37.62      | 1.62                             |
| Ireland         | 6.52               | 7                  | 45.62      | 1.96                             |
| Chile           | 6.66               | 7                  | 46.62      | 2.00                             |


### 18. Analysis of Sales Growth Dynamics by Country**

**Task:** Analyze the annual sales growth dynamics by country, including total sales, year-over-year percentage change, and country ranking based on growth trends.

**Query:**

```sql
WITH sale_comparison AS (
  SELECT 
    billing_country,
    year,
    total_sale,
    LAG(total_sale) OVER(PARTITION BY billing_country ORDER BY billing_country, year) AS total_sale_prev_year
  FROM (
    SELECT 
      billing_country,
      TO_CHAR(DATE_TRUNC('year', invoice_date), 'YYYY') AS year,
      SUM(total) AS total_sale
    FROM invoice
    GROUP BY billing_country, DATE_TRUNC('year', invoice_date)
    ORDER BY billing_country, DATE_TRUNC('year', invoice_date)) AS sale_by_country
  WHERE billing_country IN (
    SELECT DISTINCT billing_country
    FROM invoice
    WHERE TO_CHAR(DATE_TRUNC('year', invoice_date), 'YYYY')  IN ('2023', '2024')
    GROUP BY billing_country
    HAVING(COUNT(DISTINCT TO_CHAR(DATE_TRUNC('year', invoice_date), 'YYYY') )) = 2
  ) AND year IN ('2023', '2024'))

SELECT 
  billing_country,
  year,
  total_sale,
  total_sale_prev_year,
  CONCAT(ROUND((total_sale - total_sale_prev_year)/total_sale_prev_year * 100, 1), '%') AS sales_growth
FROM sale_comparison
WHERE total_sale_prev_year IS NOT NULL
ORDER BY (total_sale - total_sale_prev_year)/total_sale_prev_year * 100 DESC;
```
**Results:**
| Billing Country    | Year | Total Sale | Total Sale Previous Year | Sales Growth |
|--------------------|------|------------|--------------------------|--------------|
| Australia          | 2024 | 22.77      | 1.98                     | 1050.0%      |
| Portugal          | 2024 | 24.77      | 8.91                     | 178.0%       |
| Brazil            | 2024 | 53.46      | 19.80                    | 170.0%       |
| Czech Republic    | 2024 | 19.83      | 12.87                    | 54.1%        |
| USA               | 2024 | 127.98     | 103.01                   | 24.2%        |
| Chile             | 2024 | 6.93       | 5.94                     | 16.7%        |
| France            | 2024 | 36.66      | 42.61                    | -14.0%       |
| Canada            | 2024 | 42.57      | 55.44                    | -23.2%       |
| United Kingdom    | 2024 | 9.90       | 17.82                    | -44.4%       |
| Norway            | 2024 | 8.91       | 17.84                    | -50.1%       |
| India             | 2024 | 10.89      | 24.75                    | -56.0%       |
| Germany           | 2024 | 18.81      | 48.57                    | -61.3%       |
| Netherlands       | 2024 | 0.99       | 12.90                    | -92.3%       |
| Finland           | 2024 | 0.99       | 15.88                    | -93.8%       |

![Sales Growth by Country in 2024](assets/18.png)
*Bar graph visualizing sales growth by country in 2024; ChatGPT generated this graph from SQL query results.*

### 19. Customer Retention Analysis**

**Task:** Evaluate customer retention based on purchase frequency.

**Query:**

```sql
SELECT 
  customer_id,
  CONCAT(first_name, ' ', last_name) AS customer_name,
  MIN(invoice_date) AS first_invoice,
  MAX(invoice_date) AS last_invoice,
  MAX(invoice_date) - MIN(invoice_date) AS time_between_first_and_last_invoice,
  COUNT(invoice_id) AS number_of_invoices
FROM invoice
JOIN customer
USING(customer_id)
GROUP BY customer_id, first_name, last_name;
```
**Results:**
| Customer ID | Customer Name     | First Invoice          | Last Invoice           | Time Between Invoices (Days) | Number of Invoices |
|-------------|-------------------|------------------------|------------------------|-----------------------------|--------------------|
| 16          | Frank Harris      | 2021-02-19 00:00:00    | 2025-07-04 00:00:00    | 1596                        | 7                  |
| 18          | Michelle Brooks   | 2022-05-12 00:00:00    | 2025-10-08 00:00:00    | 1245                        | 7                  |
| 34          | João Fernandes    | 2021-05-05 00:00:00    | 2024-10-01 00:00:00    | 1245                        | 7                  |
| 17          | Jack Smith        | 2021-03-04 00:00:00    | 2024-07-31 00:00:00    | 1245                        | 7                  |
| 50          | Enrique Muñoz     | 2021-06-23 00:00:00    | 2025-11-05 00:00:00    | 1596                        | 7                  |
| 19          | Tim Goyer         | 2021-03-04 00:00:00    | 2024-09-13 00:00:00    | 1289                        | 7                  |
| 6           | Helena Holý       | 2021-07-11 00:00:00    | 2025-11-13 00:00:00    | 1586                        | 7                  |
| 26          | Richard Cunningham| 2021-11-07 00:00:00    | 2025-04-05 00:00:00    | 1245                        | 7                  |
| 36          | Hannah Schneider  | 2021-05-05 00:00:00    | 2024-11-14 00:00:00    | 1289                        | 7                  |
| 3           | François Tremblay | 2022-03-11 00:00:00    | 2025-09-20 00:00:00    | 1289                        | 7                  |


### 20. Analysis of Average Time Between Customer Purchases**

**Task:** Analyze the average number of days between consecutive purchases for each customer to identify the most frequent buyers and assess customer loyalty.

**Query:**

```sql
SELECT 
  customer_id,
  CONCAT(first_name, ' ', last_name),
  AVG(time_from_prev_invoice) AS average_time_between_purchases,
  DENSE_RANK() OVER(ORDER BY AVG(time_from_prev_invoice)) AS customer_rank_avg_time,
  COUNT(invoice_id) AS number_of_invoices
FROM (
SELECT 
  customer_id,
  invoice_id,
  invoice_date,
  LAG(invoice_date) OVER(PARTITION BY customer_id ORDER BY invoice_date),
  invoice_date - LAG(invoice_date) OVER(PARTITION BY customer_id ORDER BY invoice_date) AS time_from_prev_invoice
FROM invoice) AS time_between_purchases
JOIN customer
USING(customer_id)
WHERE time_from_prev_invoice IS NOT NULL
GROUP BY customer_id, first_name, last_name;
```
**Results:**
| Customer ID | Customer Name        | Average Time Between Purchases (Days) | Customer Rank Average Time | Number of Invoices |
|-------------|----------------------|---------------------------------------|----------------------------|--------------------|
| 1           | Luís Gonçalves       | 207                                   | 1                          | 6                  |
| 34          | João Fernandes       | 207                                   | 1                          | 6                  |
| 18          | Michelle Brooks      | 207                                   | 1                          | 6                  |
| 17          | Jack Smith           | 207                                   | 1                          | 6                  |
| 26          | Richard Cunningham   | 207                                   | 1                          | 6                  |
| 5           | František Wichterlová| 207                                   | 1                          | 6                  |
| 55          | Mark Taylor          | 207                                   | 1                          | 6                  |
| 39          | Camille Bernard      | 207                                   | 1                          | 6                  |
| 13          | Fernanda Ramos       | 207                                   | 1                          | 6                  |
| 47          | Lucas Mancini        | 207                                   | 1                          | 6                  |

---

## What I Learned
### 1. Advanced SQL Queries 🛠️

- Learned how to use Common Table Expressions (CTEs) and window functions such as `DENSE_RANK()` and `LAG()` to analyze customer spending trends and purchasing behaviors.
- Applied ranking functions to identify top customers based on spending trends and monthly sales.

### 2. Customer Segmentation & Retention 📊

- Gained experience in identifying high-value customers, tracking their spending habits, and detecting potential churn based on purchasing gaps.
- Used SQL queries to analyze the frequency of customer purchases and identify those at risk of churn.

### 3. Sales Trend Analysis 📈

- Developed skills in analyzing monthly sales trends, recognizing seasonality in revenue, and assessing the impact of time-based factors on business performance.
- Evaluated year-over-year sales changes to determine growth trends and highlight business performance improvements.

### 4. Data Visualization & Reporting 🎨

- Used SQL-generated data to create visualizations that effectively communicate findings, including customer rankings, sales trends, and category performance.
- Implemented various chart types (bar, line, and ranking graphs) to better illustrate purchasing patterns and revenue distributions.

### 5. Business Insights & Decision Making 💡

- Learned how to interpret data-driven insights to optimize marketing strategies, improve customer engagement, and enhance overall business operations.
- Applied data analysis results to suggest operational improvements, such as refining product offerings based on high-performing categories.
---

## Conclusions  🏁
The analysis of the Chinook database has provided valuable insights into customer behavior, sales trends, and product performance. Key takeaways include:
- Customer Segmentation & Retention: Identifying high-value customers and tracking their spending habits is crucial for improving customer retention strategies.
- Sales Trends & Seasonality: Monthly and yearly sales fluctuations highlight the importance of understanding market trends and optimizing inventory management accordingly.
- Product Performance Analysis: Track attributes, such as title length and genre, influence sales performance, guiding better content and product recommendations.
- Operational Efficiency: Detecting longest gaps between purchases and customer spending declines allows businesses to create targeted re-engagement strategies.
- Business Optimization: Data-driven decision-making improves marketing strategies, pricing models, and overall revenue generation.

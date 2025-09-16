use blinkitdb;
SELECT * FROM blinkit_data;
SELECT COUNT(*) FROM blinkit_data;

UPDATE blinkit_data
SET Item_Fat_Content =
  CASE
    WHEN Item_Fat_Content IN ('lf','low fat','lowfat') THEN 'Low Fat'
    WHEN Item_Fat_Content IN ('reg','regular') THEN 'Regular'
    ELSE Item_Fat_Content
  END;

SELECT DISTINCT(Item_Fat_Content) FROM blinkit_data;

SELECT CAST(SUM(Sales)/1000000 AS DECIMAL(10,2)) AS Total_Sales_Millions from blinkit_data;

SELECT CAST(AVG(Sales) AS DECIMAL(10,1)) AS Avg_Sales from blinkit_data;

SELECT COUNT(*) AS No_of_Items from blinkit_data;

SELECT CAST(AVG(Rating) AS DECIMAL(10,2)) AS Avg_Rating from blinkit_data;

### 1) Total Sales by Fat Content
SELECT
  item_fat_content,
  SUM(sales) AS total_sales,
  AVG(sales) AS avg_sales,
  COUNT(DISTINCT item_identifier) AS distinct_items,
  AVG(rating) AS avg_rating
FROM blinkit_data
GROUP BY item_fat_content
ORDER BY total_sales DESC;

### 2) Total Sales by Item Type
SELECT
  item_type,
  SUM(sales) AS total_sales,
  AVG(sales) AS avg_sales,
  COUNT(DISTINCT item_identifier) AS distinct_items,
  AVG(rating) AS avg_rating
FROM blinkit_data
GROUP BY item_type
ORDER BY total_sales DESC;

### 3) Fat Content by Outlet
SELECT
  outlet_identifier,
  item_fat_content,
  SUM(sales) AS total_sales,
  AVG(sales) AS avg_sales,
  COUNT(DISTINCT item_identifier) AS items_count,
  AVG(rating) AS avg_rating
FROM blinkit_data
GROUP BY outlet_identifier, item_fat_content
ORDER BY outlet_identifier, total_sales DESC;

### 4) Sales by Outlet Establishment Year
SELECT
  outlet_establishment_year,
  SUM(sales) AS total_sales,
  AVG(sales) AS avg_sales,
  COUNT(DISTINCT outlet_identifier) AS outlet_count,
  AVG(rating) AS avg_rating
FROM blinkit_data
GROUP BY outlet_establishment_year
ORDER BY outlet_establishment_year;

### 5) Sales by Outlet Size
SELECT
  outlet_size,
  SUM(sales) AS total_sales,
  AVG(sales) AS avg_sales,
  COUNT(DISTINCT outlet_identifier) AS outlet_count,
  AVG(rating) AS avg_rating
FROM blinkit_data
GROUP BY outlet_size
ORDER BY total_sales DESC;

### 6) Sales by Outlet Type
SELECT
  outlet_type,
  SUM(sales) AS total_sales,
  AVG(sales) AS avg_sales,
  COUNT(DISTINCT outlet_identifier) AS outlet_count,
  AVG(rating) AS avg_rating
FROM blinkit_data
GROUP BY outlet_type
ORDER BY total_sales DESC;

### 7) Sales by Location Type (Tier)
SELECT
  outlet_location_type,
  SUM(sales) AS total_sales,
  AVG(sales) AS avg_sales,
  COUNT(DISTINCT outlet_identifier) AS outlet_count,
  AVG(rating) AS avg_rating
FROM blinkit_data
GROUP BY outlet_location_type
ORDER BY total_sales DESC;

### 8) Top 10 Items by Sales
SELECT
  item_identifier,
  item_type,
  SUM(sales) AS total_sales,
  AVG(rating) AS avg_rating,
  ROUND(SUM(sales) * 100 / (SELECT SUM(sales) FROM blinkit_grocery), 2) AS pct_of_total_sales
FROM blinkit_data
GROUP BY item_identifier, item_type
ORDER BY total_sales DESC
LIMIT 10;

### 9) Bottom 10 Items by Sales
SELECT
  item_identifier,
  item_type,
  SUM(sales) AS total_sales,
  AVG(rating) AS avg_rating
FROM blinkit_data
GROUP BY item_identifier, item_type
ORDER BY total_sales ASC
LIMIT 10;

### 10) Item Visibility Impact (Quartiles)
SELECT
  vis_quartile,
  COUNT(*) AS rows_in_quartile,
  AVG(sales) AS avg_sales,
  SUM(sales) AS total_sales,
  AVG(rating) AS avg_rating
FROM (
  SELECT *,
         NTILE(4) OVER (ORDER BY item_visibility) AS vis_quartile
  FROM blinkit_data
) t
GROUP BY vis_quartile
ORDER BY vis_quartile;

### 11) Item Weight Buckets vs Sales
SELECT
  FLOOR(item_weight/5)*5 AS weight_bucket,
  SUM(sales) AS total_sales,
  AVG(sales) AS avg_sales,
  AVG(rating) AS avg_rating
FROM blinkit_data
GROUP BY weight_bucket
ORDER BY weight_bucket;

### 12) Sales Distribution by Rating
SELECT
  FLOOR(rating) AS rating_bucket,
  SUM(sales) AS total_sales,
  AVG(sales) AS avg_sales
FROM blinkit_data
GROUP BY rating_bucket
ORDER BY rating_bucket DESC;

### 13) Avg Sales per Outlet
SELECT
  outlet_identifier,
  SUM(sales) AS total_sales,
  AVG(sales) AS avg_sales,
  AVG(rating) AS avg_rating,
  COUNT(DISTINCT item_identifier) AS item_count
FROM blinkit_data
GROUP BY outlet_identifier
ORDER BY total_sales DESC;


### 14) Item Type by Outlet Type
SELECT
  outlet_type,
  item_type,
  SUM(sales) AS total_sales,
  ROUND(SUM(sales) * 100 / SUM(SUM(sales)) OVER (PARTITION BY outlet_type), 2) AS pct_within_outlet_type,
  AVG(rating) AS avg_rating
FROM blinkit_data
GROUP BY outlet_type, item_type
ORDER BY outlet_type, total_sales DESC;

### 15) Fat Content vs Rating
SELECT
  item_fat_content,
  AVG(rating) AS avg_rating,
  AVG(sales) AS avg_sales,
  SUM(sales) AS total_sales,
  COUNT(DISTINCT item_identifier) AS items_count
FROM blinkit_data
GROUP BY item_fat_content
ORDER BY total_sales DESC;

### 16) Sales by Outlet Age
SELECT
  CASE
    WHEN outlet_establishment_year < 2010 THEN 'Before 2010'
    WHEN outlet_establishment_year BETWEEN 2010 AND 2015 THEN '2010-2015'
    ELSE 'After 2015'
  END AS age_group,
  SUM(sales) AS total_sales,
  AVG(sales) AS avg_sales,
  COUNT(DISTINCT outlet_identifier) AS outlet_count
FROM blinkit_data
GROUP BY age_group
ORDER BY total_sales DESC;

### 17) High Visibility but Low Sales
 -- top 25% visibility
WITH ranked AS (
    SELECT item_identifier,
           AVG(item_visibility) AS avg_visibility,
           SUM(sales) AS total_sales,
           AVG(rating) AS avg_rating
    FROM blinkit_data
    GROUP BY item_identifier
),
quartiles AS (
    SELECT item_identifier,
           avg_visibility,
           total_sales,
           avg_rating,
           NTILE(4) OVER (ORDER BY avg_visibility) AS visibility_quartile
    FROM ranked
)
SELECT *
FROM quartiles
WHERE visibility_quartile = 4  
  AND total_sales < (SELECT AVG(sales) FROM blinkit_data)
ORDER BY avg_visibility DESC, total_sales ASC
LIMIT 20;

### 18) Low Visibility but High Sales
SELECT item_identifier,
       AVG(item_visibility) AS avg_visibility,
       SUM(sales) AS total_sales,
       AVG(rating) AS avg_rating
FROM blinkit_data
GROUP BY item_identifier
HAVING avg_visibility < (
         SELECT AVG(item_visibility)
         FROM blinkit_data
       )
   AND SUM(sales) > (
         SELECT AVG(sales)
         FROM blinkit_data
       )
ORDER BY total_sales DESC
LIMIT 20;


### 19) Sales by Outlet Size + Tier
SELECT
  outlet_size,
  outlet_location_type,
  SUM(sales) AS total_sales,
  AVG(sales) AS avg_sales,
  COUNT(DISTINCT outlet_identifier) AS outlet_count
FROM blinkit_data
GROUP BY outlet_size, outlet_location_type
ORDER BY outlet_size, total_sales DESC;

### 20) Rating vs Sales Gap Analysis
WITH sales_ranked AS (
    SELECT
        item_identifier,
        SUM(sales) AS total_sales,
        AVG(rating) AS avg_rating,
        NTILE(5) OVER (ORDER BY SUM(sales)) AS sales_percentile
    FROM blinkit_data
    GROUP BY item_identifier
)
SELECT *
FROM sales_ranked
WHERE sales_percentile = 5   -- top 20% sales
   OR avg_rating < 3
ORDER BY total_sales DESC;


### 21) Item Type × Fat Content
SELECT
  item_type,
  item_fat_content,
  SUM(sales) AS total_sales,
  AVG(sales) AS avg_sales,
  AVG(rating) AS avg_rating
FROM blinkit_data
GROUP BY item_type, item_fat_content
ORDER BY item_type, total_sales DESC;

### 22) Sales Concentration (Pareto 80/20)
WITH item_totals AS (
  SELECT item_identifier, SUM(sales) AS total_sales
  FROM blinkit_data
  GROUP BY item_identifier
),
ranked AS (
  SELECT item_identifier, total_sales,
         SUM(total_sales) OVER (ORDER BY total_sales DESC) AS running_total,
         SUM(total_sales) OVER () AS grand_total
  FROM item_totals
)
SELECT
  item_identifier,
  total_sales,
  running_total,
  grand_total,
  ROUND(running_total*100/grand_total, 2) AS cumulative_pct
FROM ranked
ORDER BY total_sales DESC;

### 23) Outlet Rating Impact
WITH outlet_stats AS (
  SELECT outlet_identifier,
         AVG(rating) AS outlet_avg_rating,
         SUM(sales) AS outlet_total_sales
  FROM blinkit_data
  GROUP BY outlet_identifier
)
SELECT
  CASE
    WHEN outlet_avg_rating >= 4.5 THEN '4.5+'
    WHEN outlet_avg_rating >= 4.0 THEN '4.0-4.49'
    WHEN outlet_avg_rating >= 3.5 THEN '3.5-3.99'
    ELSE '<3.5'
  END AS rating_band,
  COUNT(*) AS outlet_count,
  AVG(outlet_total_sales) AS avg_sales_per_outlet
FROM outlet_stats
GROUP BY rating_band
ORDER BY rating_band DESC;

### 24) Compare Supermarket Types
SELECT
  outlet_type,
  outlet_size,
  SUM(sales) AS total_sales,
  AVG(sales) AS avg_sales,
  AVG(rating) AS avg_rating,
  COUNT(DISTINCT outlet_identifier) AS outlet_count
FROM blinkit_data
WHERE outlet_type LIKE 'Supermarket%'
GROUP BY outlet_type, outlet_size
ORDER BY total_sales DESC;




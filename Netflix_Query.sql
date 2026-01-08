Create database netflix;
use netflix;
 create database new_netflix;
use new_netflix;
 -- netflix table
CREATE TABLE netflix (
    show_id VARCHAR(10) PRIMARY KEY,
    type VARCHAR(20), 
    title VARCHAR(255),         
    director VARCHAR(255),             
    cast TEXT,                     
    country VARCHAR(255),             
    date_added VARCHAR(50),             
    release_year INT,                      
    rating VARCHAR(20),              
    duration VARCHAR(50),              
    listed_in VARCHAR(255),             
    description TEXT                      
);

 -- netflix viewership table 
CREATE TABLE netflix_viewership (
    show_id TEXT,
    type TEXT,
    release_year INT,
    total_views_millions INT,
    avg_watch_time_minutes INT,
    peak_region TEXT
);
 -- netflix content cost table
CREATE TABLE netflix_content_costs (
    show_id TEXT,
    type TEXT,
    production_cost_million_usd INT,
    marketing_cost_million_usd INT,
    estimated_revenue_million_usd INT
);

 -- Check total rows
SELECT COUNT(*) FROM netflix;
SELECT COUNT(*) FROM netflix_viewership;
SELECT COUNT(*) FROM netflix_content_costs;

 -- Now previewing the data
SELECT * FROM netflix LIMIT 5;
SELECT * FROM netflix_viewership LIMIT 5;
SELECT * FROM netflix_content_costs LIMIT 5;



 -- Question 1 Count the number of Movies vs TV Shows
SELECT type, COUNT(*) AS total
FROM netflix_viewership
GROUP BY type;

 -- Question 2 Find the most common rating for movies and TV shows
SELECT type, rating, rating_count
FROM (
    SELECT type, rating,
           COUNT(*) AS rating_count,
           ROW_NUMBER() OVER (PARTITION BY type ORDER BY COUNT(*) DESC) AS rn
    FROM netflix
    GROUP BY type, rating
) t
WHERE rn = 1;

 -- Question 3  List all movies released in a specific year (e.g., 2020)
SELECT title
FROM netflix
WHERE type = 'Movie'
AND release_year = 2020;

 -- Question 4 Find the top 5 countries with the most content on Netflix
SELECT country, COUNT(*) AS total_content
FROM netflix
GROUP BY country
ORDER BY total_content DESC
LIMIT 5;

 -- Question 5 Identify the longest movie
SELECT title, duration
FROM netflix
WHERE type = 'Movie'
ORDER BY duration DESC
LIMIT 1;

 -- Question 6 Find content added in the last 5 years
SELECT title, date_added
FROM netflix
WHERE STR_TO_DATE(date_added, '%M %d, %Y') >= (
SELECT MAX(STR_TO_DATE(date_added, '%M %d, %Y')) 
FROM netflix) - INTERVAL 5 YEAR;

 -- Question 7 Find all the movies/TV shows by director 'Rajiv Chilaka'!
SELECT title, type
FROM netflix
WHERE director LIKE '%Rajiv Chilaka%';

 -- Question 8 List all TV shows with more than 5 seasons
SELECT title, duration
FROM netflix
WHERE type = 'TV Show'
AND CAST(SUBSTRING_INDEX(duration, ' ', 1) AS UNSIGNED) > 5;

 -- Question 9 Count the number of content items in each genre
SELECT TRIM(listed_in) AS genre, COUNT(*) AS total_count
FROM netflix
GROUP BY genre;

 -- Question 10 Find each year and the average numbers of content release in
 -- India on netflix. return top 5 year with highest avg content release!
SELECT release_year, COUNT(*) AS avg_release
FROM netflix
WHERE country LIKE '%India%'
GROUP BY release_year
ORDER BY avg_release DESC
LIMIT 5;

 -- Question 11 List all movies that are documentaries
SELECT type, listed_in
FROM netflix
WHERE type = 'Movie' 
AND listed_in LIKE '%Documentaries%';

 -- Question 12 Find all content without a director
SELECT title, type
FROM netflix
WHERE director IS NULL OR director = '';

 -- Question 13 Find how many movies actor 'Salman Khan' appeared in last 10 years!
SELECT type, cast, country date_added
FROM netflix
WHERE cast LIKE '%Salman Khan%'
AND release_year > 2015;

 -- Question 14 Find the top 10 actors who have appeared in the highest
 -- number of movies produced in India.
WITH RECURSIVE numbers AS (
    SELECT 1 AS n
    UNION ALL
    SELECT n + 1 FROM numbers WHERE n < 10
)
SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(cast, ',', n), ',', -1)) AS actor,
       COUNT(*) AS total_movies
FROM netflix
JOIN numbers ON CHAR_LENGTH(cast) - CHAR_LENGTH(REPLACE(cast, ',', '')) + 1 >= n
WHERE country LIKE '%India%'
  AND type = 'Movie'
GROUP BY actor
ORDER BY total_movies DESC
LIMIT 10;

 -- Question 15 Categorize the content based on the presence of the keywords
 -- 'kill' and 'violence' in the description field. Label content containing
 -- these keywords as 'Bad' and all other content as 'Good'. Count how
 -- many items fall into each category.
SELECT
CASE
    WHEN LOWER(description) LIKE '%kill%'
      OR LOWER(description) LIKE '%violence%'
    THEN 'Bad'
    ELSE 'Good'
END AS category,
COUNT(*) AS total_count
FROM netflix
GROUP BY category;

 -- Question 16 For each content type (Movie / TV Show), find the top 3 most
 -- profitable titles released after 2018, where profitability is defined as:
 -- estimated_revenue − (production_cost + marketing_cost).
 -- Also display their rank within each type.
WITH profit_calc AS (
    SELECT
        c.show_id,
        c.type,
        v.release_year,
        (c.estimated_revenue_million_usd -
        (c.production_cost_million_usd + c.marketing_cost_million_usd)) AS profit_in_million_usd
    FROM netflix_content_costs c
    JOIN netflix_viewership v
        ON c.show_id = v.show_id
    WHERE v.release_year > 2018
),
ranked_profit AS (
    SELECT
        show_id,
        type,
        release_year,
        profit_in_million_usd,
        RANK() OVER (
            PARTITION BY type
            ORDER BY profit_in_million_usd DESC
        ) AS profit_rank
    FROM profit_calc
)
SELECT
    show_id,
    type,
    release_year,
    profit_in_million_usd,
    profit_rank
FROM ranked_profit
WHERE profit_rank <= 3
ORDER BY type, profit_rank;

 -- Question 17 Among titles where average watch time is above the overall
 -- platform average, identify the country that contributes the highest
 -- total views, and show the top contributing title from that country
WITH platform_avg AS (
    SELECT AVG(avg_watch_time_minutes) AS overall_avg_watch_time
    FROM netflix_viewership
),
filtered AS (
    SELECT *
    FROM netflix_viewership, platform_avg
    WHERE avg_watch_time_minutes > overall_avg_watch_time
),
region_totals AS (
    SELECT peak_region,
           SUM(total_views_millions) AS region_total_views
    FROM filtered
    GROUP BY peak_region
),
top_region AS (
    SELECT peak_region
    FROM region_totals
    ORDER BY region_total_views DESC
    LIMIT 1
)
SELECT f.peak_region, f.show_id, f.total_views_millions
FROM filtered f
JOIN top_region tr ON f.peak_region = tr.peak_region
ORDER BY f.total_views_millions DESC
LIMIT 1;

 -- Question 18 Which content type (Movie / TV Show) has higher average watch time?
SELECT
    type,
    AVG(avg_watch_time_minutes) AS avg_watch_time
FROM netflix_viewership
GROUP BY type;

 -- Question 19 Which region (peak_region) generates the highest total views overall?
SELECT
    peak_region,
    ROUND(SUM(total_views_millions) / 1000, 2) AS total_views_billion
FROM netflix_viewership
GROUP BY peak_region
ORDER BY total_views_billion DESC
LIMIT 1;

 -- Question 20 Which titles have high views but low profitability?
SELECT
    v.show_id,
    v.type,
    v.total_views_millions,
    (c.estimated_revenue_million_usd -
     (c.production_cost_million_usd + c.marketing_cost_million_usd)) AS low_profit
FROM netflix_viewership v
JOIN netflix_content_costs c
ON v.show_id = c.show_id
WHERE (c.estimated_revenue_million_usd -
      (c.production_cost_million_usd + c.marketing_cost_million_usd)) <= 0
ORDER BY v.total_views_millions DESC;

 -- Question 21 What is the average profitability of Movies vs TV Shows?
SELECT
    type,
    ROUND(AVG(estimated_revenue_million_usd -
       (production_cost_million_usd + marketing_cost_million_usd)),2) AS avg_profit_in_millions
FROM netflix_content_costs
GROUP BY type;

 -- Question 22 Find the top 5 most profitable titles, along with their total views, released after 2018.
WITH profit_cte AS (
    SELECT
        c.show_id,
        c.type,
        (c.estimated_revenue_million_usd -
        (c.production_cost_million_usd + c.marketing_cost_million_usd)) AS profit_in_millions
    FROM netflix_content_costs c
),
views_cte AS (
    SELECT
        show_id,
        SUM(total_views_millions) AS total_views_in_millions
    FROM netflix_viewership
    GROUP BY show_id
)
SELECT
    p.show_id,
    p.type,
    p.profit_in_millions,
    v.total_views_in_millions
FROM profit_cte p
JOIN views_cte v ON p.show_id = v.show_id
JOIN netflix n ON p.show_id = n.show_id
WHERE n.release_year > 2018
ORDER BY p.profit_in_millions DESC
LIMIT 5;

 -- Question 23 Find titles whose average watch time is above the platform average AND profit is also above avarage?
SELECT
    v.show_id,
    v.type,
    v.avg_watch_time_minutes,
    (c.estimated_revenue_million_usd -
    (c.production_cost_million_usd + c.marketing_cost_million_usd)) AS profit_in_millions
FROM netflix_viewership v
JOIN netflix_content_costs c
ON v.show_id = c.show_id
WHERE v.avg_watch_time_minutes >
    (SELECT AVG(avg_watch_time_minutes) FROM netflix_viewership)
AND (c.estimated_revenue_million_usd -
    (c.production_cost_million_usd + c.marketing_cost_million_usd)) >
    (SELECT AVG(estimated_revenue_million_usd -
	(production_cost_million_usd + marketing_cost_million_usd))
FROM netflix_content_costs);

 -- Question 24 Which content type contributes the highest total profit, and what is its average watch time?
WITH profit_by_type AS (
    SELECT
        type,
        ROUND(SUM(estimated_revenue_million_usd -
           (production_cost_million_usd + marketing_cost_million_usd))/1000, 2) AS total_profit_in_billions_usd
    FROM netflix_content_costs
    GROUP BY type
),
watchtime_by_type AS (
    SELECT
        type,
        ROUND(AVG(avg_watch_time_minutes),2) AS avg_watch_time
    FROM netflix_viewership
    GROUP BY type
)
SELECT
    p.type,
    p.total_profit_in_billions_usd,
    w.avg_watch_time
FROM profit_by_type p
JOIN watchtime_by_type w
ON p.type = w.type
ORDER BY p.total_profit_in_billions_usd DESC;




Create database netflix;
use netflix;
 create database new_netflix;
use new_netflix;
 -- netflix table
CREATE TABLE netflix (
    show_id      VARCHAR(10) PRIMARY KEY,  -- The ID tag (like 's1')
    type         VARCHAR(20),              -- Movie or TV Show?
    title        VARCHAR(255),             -- The Name
    director     VARCHAR(255),             -- Who made it?
    cast         TEXT,                     -- The Actors
    country      VARCHAR(255),             -- Where it's from
    date_added   VARCHAR(50),              -- When Netflix added it
    release_year INT,                      -- When it came out
    rating       VARCHAR(20),              -- PG-13, R, etc.
    duration     VARCHAR(50),              -- How long is it?
    listed_in    VARCHAR(255),             -- Genre (Comedy, Action)
    description  TEXT                      -- What is it about?
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
WITH rating_counts AS (
    SELECT type, rating, COUNT(*) AS rating_count
    FROM netflix
    GROUP BY type, rating
)
SELECT r.type, r.rating, r.rating_count
FROM rating_counts r
JOIN (
    SELECT type, MAX(rating_count) AS max_count
    FROM rating_counts
    GROUP BY type
) x
ON r.type = x.type AND r.rating_count = x.max_count;

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
AND release_year > 2014; -- Assuming 2024 is current year

 -- Question 14 Find the top 10 actors who have appeared in the highest
 -- number of movies produced in India.
SELECT cast AS actor, COUNT(*) AS total_movies
FROM netflix
WHERE country LIKE '%India%'
AND type = 'Movie'
GROUP BY cast
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
filtered_titles AS (
    SELECT *
    FROM netflix_viewership
    WHERE avg_watch_time_minutes >
          (SELECT overall_avg_watch_time FROM platform_avg)
),
region_views AS (
    SELECT
        peak_region,
        SUM(total_views_millions) AS total_views
    FROM filtered_titles
    GROUP BY peak_region
),
top_region AS (
    SELECT peak_region
    FROM region_views
    ORDER BY total_views DESC
    LIMIT 1
)
SELECT
    f.peak_region,
    f.show_id,
    f.total_views_millions
FROM filtered_titles f
WHERE f.peak_region = (SELECT peak_region FROM top_region)
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
    SUM(total_views_millions) AS total_views
FROM netflix_viewership
GROUP BY peak_region
ORDER BY total_views DESC
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
    AVG(estimated_revenue_million_usd -
       (production_cost_million_usd + marketing_cost_million_usd)) AS avg_profit_in_millions
FROM netflix_content_costs
GROUP BY type;

 -- Question 22 Find the top 5 most profitable titles, along with their total views, released after 2018.
WITH profit_cte AS (
    SELECT
        c.show_id,
        c.type,
        (c.estimated_revenue_million_usd -
        (c.production_cost_million_usd + c.marketing_cost_million_usd)) AS profit
    FROM netflix_content_costs c
),
views_cte AS (
    SELECT
        show_id,
        SUM(total_views_millions) AS total_views
    FROM netflix_viewership
    GROUP BY show_id
)
SELECT
    p.show_id,
    p.type,
    p.profit,
    v.total_views
FROM profit_cte p
JOIN views_cte v ON p.show_id = v.show_id
JOIN netflix n ON p.show_id = n.show_id
WHERE n.release_year > 2018
ORDER BY p.profit DESC
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
        SUM(estimated_revenue_million_usd -
           (production_cost_million_usd + marketing_cost_million_usd)) AS total_profit_in_millions_usd
    FROM netflix_content_costs
    GROUP BY type
),
watchtime_by_type AS (
    SELECT
        type,
        AVG(avg_watch_time_minutes) AS avg_watch_time
    FROM netflix_viewership
    GROUP BY type
)
SELECT
    p.type,
    p.total_profit_in_millions_usd,
    w.avg_watch_time
FROM profit_by_type p
JOIN watchtime_by_type w
ON p.type = w.type
ORDER BY p.total_profit_in_millions_usd DESC;




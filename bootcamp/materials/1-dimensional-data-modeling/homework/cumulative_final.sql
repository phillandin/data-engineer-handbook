INSERT INTO actors_1
 WITH yesterday AS (
  SELECT *
  FROM actors_1
  WHERE current_year = 2020
),
today_cte as (
	select actor as actor_name,
		actorid as actor_id,
		ARRAY[ROW(
			year, film, votes, rating, filmid
		)::films] as films
	from actor_films
	where year = 2021
),
today as (
select actor_name,
	actor_id,
	year,
	ARRAY_AGG(films) as films
	, CASE
        WHEN AVG(f.rating) > 8 THEN 'star'::quality_class_type
        WHEN AVG(f.rating) > 7 THEN 'good'::quality_class_type
        WHEN AVG(f.rating) > 6 THEN 'average'::quality_class_type
        ELSE 'bad'
    END AS quality_class
from today_cte, unnest(films) as f
group by actor_name, actor_id, f.year
)
	select
	    COALESCE(t.actor_name, y.actor_name) AS actor_name,
	    coalesce(t.actor_id, y.actor_id) as actor_id,
	    case
			when y.films is null then t.films
			when t.year is null then y.films
			else y.films || t.films
		end as films,
	    coalesce(t.quality_class, y.quality_class) as quality_class,
	    t.year IS NOT NULL AS is_active,
	    COALESCE(t.year, y.current_year + 1) AS current_year
	FROM today AS t
	FULL OUTER JOIN yesterday AS y
	ON t.actor_name = y.actor_name;
create table actors_1000 (
	actor_name text,
	actor_id text,
	films_0 films[],
	films_1 films[],
	quality_class quality_class_type,
	is_active boolean,
	current_year int
);

  INSERT INTO actors_1
 WITH yesterday AS (
  SELECT *
  FROM actors_1
  WHERE current_year = 1970
),
today AS (
  SELECT *
  FROM actor_films
  WHERE year = 1971
)
SELECT
    COALESCE(t.actor, y.actor_name) AS actor,
    coalesce(t.actorid, y.actor_id) as actor_id,
    coalesce(y.films,
    	ARRAY[ROW(
			t.year, t.film, t.votes, t.rating, t.filmid
		)::films]
	) as films,
	'good'::quality_class_type as quality_class,
    -- , CASE
    --     WHEN AVG(t.rating) > 8 THEN 'star'::quality_class_type
    --     WHEN AVG(t.rating) > 7 THEN 'good'::quality_class_type
    --     WHEN AVG(t.rating) > 6 THEN 'average'::quality_class_type
    --     ELSE 'bad'
    -- END AS quality_class,
    t.year IS NOT NULL AS is_active,
    COALESCE(t.year, y.current_year + 1) AS year
FROM today AS t
FULL OUTER JOIN yesterday AS y
ON t.actor = y.actor_name
where t.actor = 'Alain Delon';

  INSERT INTO actors_1000
 WITH yesterday AS (
  SELECT *
  FROM actors_1000
  WHERE current_year = 1970
),
today AS (
  SELECT *
  FROM actor_films
  WHERE year = 1971
)
SELECT 
    COALESCE(t.actor, y.actor_name) AS actor,
    coalesce(t.actorid, y.actor_id) as actor_id,
	array_agg(
		case
			when y.films_0 is null
				then ARRAY[ROW(
					t.year, t.film, t.votes, t.rating, t.filmid
				)::films]
			else y.films_0
		end) as films_0,
	array_agg(
		case
		when t.year is not null 
			then array[row(
				t.year, t.film, t.votes, t.rating, t.filmid
			)::films]
		else null
	end) as films_1,
	'good'::quality_class_type as quality_class,
    -- , CASE
    --     WHEN AVG(t.rating) > 8 THEN 'star'::quality_class_type
    --     WHEN AVG(t.rating) > 7 THEN 'good'::quality_class_type
    --     WHEN AVG(t.rating) > 6 THEN 'average'::quality_class_type
    --     ELSE 'bad'
    -- END AS quality_class,
    t.year IS NOT NULL AS is_active,
    COALESCE(t.year, y.current_year + 1) AS year
FROM today AS t
FULL OUTER JOIN yesterday AS y
ON t.actor = y.actor_name
where y.actor_name = 'Alain Delon'
GROUP BY 1,2,5,6,7;


select *
from actors_1;

with cte as (
select actor_name,
length(films::varchar) as longy
from actors_1
)
select * from cte order by longy desc limit 20;

select *
from actor_films
where actor = 'Alain Delon'
and year = 1971;

-- try using this idea with Union to insert to table; last_years records unioned with this years records put into films_array
select *
from actors_1
where actor_name = 'Alain Delon';
with cte as (
select actor_name, actor_id, unnest(films_1) as films
from actors_1000
)
select actor_name, actor_id, ARRAY_AGG(films)
from cte
group by 1, 2;
where actor_name = 'Alain Delon'
and current_year = 1971;

where actor_name = 'Alain Delon'
and current_year = 1970;

truncate table actors_1;
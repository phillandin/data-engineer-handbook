INSERT INTO actors_1
 WITH yesterday AS (
  SELECT *
  FROM actors_1
  WHERE current_year = 1969
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

select *
from actors_1
where actor_name = 'Johnny Depp'
order by actor_name, current_year desc;

select actor, actorid, count(*) over (partition by actor order by actorid)
from actor_films
group by 1, 2
order by 3 desc;

select actor_name,
	actor_id,
	array_agg(films),
	quality_class,
	max(current_year)
from actors_1
group by actor_name, actor_id, quality_class, is_active, current_year;

-- truncate table actors_1;

-- SCD table creation
create table actors_history_scd (
	actor_name text,
	quality_class quality_class_type,
	is_active boolean,
	start_year integer,
	end_year integer,
	this_year integer,
	primary key(actor_name, start_year)
);

-- insert into actors_history_scd
with previous as (
	select actor_name,
		current_year,
		quality_class,
		is_active,
		lag(quality_class, 1) over (partition by actor_name order by current_year) as previous_quality_class,
		lag(is_active, 1) over (partition by actor_name order by current_year) as previous_is_active
	from actors_1
	where current_year <= 2021
),
indicators as (
	select *,
		case when quality_class <> previous_quality_class then 1
		when is_active <> previous_is_active then 1
		else 0
		end as change_indicator	
	from previous
),
with_streaks as (
select *,
	sum(change_indicator) over (partition by actor_name order by current_year) as streak_identifier
from indicators
),
scd as (
select actor_name,
	quality_class,
	is_active,
	min(current_year) as start_year,
	max(current_year) as end_year,
	2021 as this_season
from with_streaks
group by actor_name,
	streak_identifier,
	is_active,
	quality_class
)
select *
from scd
where actor_name = 'Jake Ryan'
order by actor_name, end_year desc;
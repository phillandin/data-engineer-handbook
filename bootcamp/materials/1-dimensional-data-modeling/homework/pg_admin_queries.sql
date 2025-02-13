-- Database: postgres

-- DROP DATABASE IF EXISTS postgres;
create type year_films_array as (
	year integer,
	films films_array
);

create type films_array as (
	film text,
	votes integer,
	rating real,
	filmid text
);
 
create type quality_class_type as
	enum ('star', 'good', 'average', 'bad');

drop table actors;
create table actors (
	actor_name text,
	actor_id text,
	films films_array[],
	-- quality_class quality_class_type,
	-- is_active boolean,
	current_year int
);

insert into actors
with last_year as (
    select actor_name,
        actor_id,
        films,
        -- quality_class,
        -- is_active,
		current_year
    from actors
    where current_year = 1969
),
this_year as (
	SELECT 
	    actor, 
	    actorid, 
	    year, 
	    ARRAY_AGG(ROW(film, votes, rating, filmid)::films_array) AS films
	FROM actor_films
    where year = 1970
	GROUP BY actor, actorid, year
)
select coalesce(ly.actor_name, ty.actor) as actor_name,
    coalesce(ly.actor_id, ty.actorid) as actor_id,
    coalesce(ly.films,
		case when ty.year is not null then
	        array[row(
				ty.year,
	            ty.films
	        )]
        else ly.films END)
    as films,
	ty.year as current_year
from last_year ly
full outer join this_year ty
on ly.actor_name = ty.actor;

select *
from actors
where current_year = 1971
;

-- v. 2
with last_year as (
    select actor_name,
        actor_id,
        films,
        -- quality_class,
        -- is_active,
		current_year
    from actors
    where current_year = 1969
),
this_year as (
	SELECT 
	    actor, 
	    actorid, 
	    year, 
	    ARRAY_AGG(ROW(film, votes, rating, filmid)) AS films
	FROM actor_films
    where year = 1970
	GROUP BY actor, actorid, year
)
insert into actors
select coalesce(ly.actor_name, ty.actor) as actor_name,
    coalesce(ly.actor_id, ty.actorid) as actor_id,
	array_agg(
		coalesce(
			ly.films,
			array[]::films_array[]
		) ||  case when ty.films is not null then
			array[row(
				ty.year,
				ty.films
			)::year_films_array]
			else array[]::year_films_array[] end
	) as films,
	ty.year as current_year
from last_year ly
full outer join this_year ty
on ly.actor_name = ty.actor;

-- random answer:
drop table actors_1;
create table actors_1 (
	actor_name text,
	actor_id text,
	films films[],
	quality_class quality_class_type,
	is_active boolean,
	current_year int
);

create type films as (
	year integer,
	film text,
	votes integer,
	rating real,
	filmid text
)

INSERT INTO actors_1
 WITH yesterday AS (
  SELECT *
  FROM actors
  WHERE current_year = 1969
),
today AS (
  SELECT *
  FROM actor_films
  WHERE year = 1970
)
SELECT 
    COALESCE(t.actor, y.actor_name) AS actor,
    COALESCE(t.year, y.current_year + 1) AS year,
    ARRAY_AGG(
        COALESCE(y.films,
            ARRAY[]::films[]
            ) || CASE WHEN t.film IS NOT NULL THEN
                ARRAY[ROW(
                t.year,
                t.film,
                t.votes,
                t.rating,
                t.filmid)::films]
                ELSE ARRAY[]::films[] END)
            as films,
    CASE
        WHEN AVG(t.rating) > 8 THEN 'star'
        WHEN AVG(t.rating) > 7 THEN 'good'
        WHEN AVG(t.rating) > 6 THEN 'average'
        ELSE 'bad'
    END AS quality_class,
    t.year IS NOT NULL AS is_active
FROM today AS t
FULL OUTER JOIN yesterday AS y
ON t.actor = y.actor_name
GROUP BY 1,2,5; 

  SELECT *
  FROM actor_films

  -- latest attempt (working on figuring out lateral view)
  INSERT INTO actors_1
 WITH yesterday AS (
  SELECT *
  FROM actors_1
  WHERE current_year = 1969
),
today AS (
  SELECT *
  FROM actor_films
  WHERE year = 1970
)
SELECT 
    COALESCE(t.actor, y.actor_name) AS actor,
    coalesce(t.actorid, y.actor_id) as actor_id,
	array_agg(
		case
			when y.films is null
				then ARRAY[ROW(
					t.year, t.film, t.votes, t.rating, t.filmid
				)::films]
			when t.year is not null 
				then y.films || array[row(
					t.year, t.film, t.votes, t.rating, t.filmid
				)::films]
			else y.films
	end) as films,
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
GROUP BY 1,2,4,5,6;

select *
from actors_1
where current_year = 1979;

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

select *
from actors_1
where actor_name = 'Alain Delon';

select *
from actors_1
lateral view unnest(films);
where actor_name = 'Alain Delon'
and current_year = 1970;

truncate table actors_1;
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
			array[]::year_films_array[]
		) ||  case when ty.films is not null then
			then array[row(
				ty.year,
				ty.films
			)::year_films_array]
			else array[]:year_films_array[] end
	) as films,
	ty.year as current_year
from last_year ly
full outer join this_year ty
on ly.actor_name = ty.actor;

select *
from actors
where current_year = 1971
;

-- working here to figure out how to make above query go; need to cast line 83 field?
with cte as (
SELECT 
    actor, 
    actorid, 
    year, 
    ARRAY_AGG(ROW(film, votes, rating, filmid)::films_array) AS films
FROM actor_films
GROUP BY actor, actorid, year
)
select actor,
actorid,
array_agg(row(year, films)) as films
from cte
group by actor, actorid;

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
    case when ly.films is null
		then array_agg[row(
			ty.year,
            ty.films
        )::year_films_array]
		when ty.year is not null
			then ly.films || array_agg[row(
				ty.year,
				ty.films
			)::year_films_array]
        else ly.films END
    as films,
	ty.year as current_year
from last_year ly
full outer join this_year ty
on ly.actor_name = ty.actor;
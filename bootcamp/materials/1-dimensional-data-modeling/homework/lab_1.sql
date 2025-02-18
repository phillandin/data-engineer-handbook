create type scd_type as (
	scoring_class scoring_class,
	is_active boolean,
	start_season integer,
	end_season integer
);

with last_season_scd as (
	select * from players_scd
	where this_season = 2021
	and end_season = 2021
),
historical_scd as (
	select player_name,
		scoring_class,
		is_active,
		start_season,
		end_season
	from players_scd
	where this_season = 2021
	and end_season < 2021
),
this_season_data as (
	select * from players_1
	where current_season = 2022
),
unchanged_records as (
	select ts.player_name,
		ts.scoring_class,
		ts.is_active,
		ls.start_season,
		ls.this_season as end_season
	from this_season_data ts
	join last_season_scd ls
	on ls.player_name = ts.player_name
	where ts.scoring_class = ls.scoring_class
	and ts.is_active = ls.is_active
),
changed_records as (
	select ts.player_name,
		ts.scoring_class,
		ts.is_active,
		ls.start_season,
		ls.this_season as end_season,
		unnest(array[
			row(
				ls.scoring_class,
				ls.is_active,
				ls.start_season,
				ls.end_season
			)::scd_type,
			row(
				ts.scoring_class,
				ts.is_active,
				ts.current_season,
				ts.current_season
			)::scd_type
		]) as records
	from this_season_data ts
	left join last_season_scd ls
	on ls.player_name = ts.player_name
	where (ts.scoring_class <> ls.scoring_class
		or ts.is_active <> ls.is_active)
),
unnested_changed_records as (
	select player_name,
		(records::scd_type).scoring_class,
		(records::scd_type).is_active,
		(records::scd_type).start_season,
		(records::scd_type).end_season
	from changed_records
),
new_records as (
	select ts.player_name,
		ts.scoring_class,
		ts.is_active,
		ts.current_season as start_season,
		ts.current_season as end_season
	from this_season_data ts
	left join last_season_scd ls
	on ts.player_name = ls.player_name
	where ls.player_name is null
),
final_scd as (
	select *
	from historical_scd
	union all
	select *
	from unchanged_records
	union all
	select *
	from unnested_changed_records
	union all
	select *
	from new_records
)
select *
from final_scd
order by player_name;

select * from players_1
where current_season = 2022
order by player_name;


--notebook 2
CREATE TYPE season_stats_1 AS (
	season Integer,
	pts REAL,
	ast REAL,
	reb REAL,
	weight INTEGER
	);


 CREATE TABLE players_1 (
     player_name TEXT,
     height TEXT,
     college TEXT,
     country TEXT,
     draft_year TEXT,
     draft_round TEXT,
     draft_number TEXT,
     season_stats season_stats[],
     scoring_class scoring_class,
     years_since_last_active INTEGER,
     current_season INTEGER,
     is_active BOOLEAN,
     PRIMARY KEY (player_name, current_season)
 );

WITH last_season AS (
    SELECT * FROM players_1
    WHERE current_season = 2024
), 
this_season AS (
    SELECT * FROM player_seasons
    WHERE season = 2025
)
INSERT INTO players_1
SELECT
        COALESCE(ls.player_name, ts.player_name) as player_name,
        COALESCE(ls.height, ts.height) as height,
        COALESCE(ls.college, ts.college) as college,
        COALESCE(ls.country, ts.country) as country,
        COALESCE(ls.draft_year, ts.draft_year) as draft_year,
        COALESCE(ls.draft_round, ts.draft_round) as draft_round,
        COALESCE(ls.draft_number, ts.draft_number)
            as draft_number,
        case when ls.season_stats is null
			then ARRAY[ROW(
                ts.season,
                ts.pts,
                ts.ast,
                ts.reb,
				ts.weight
			)::season_stats]
			when ts.season is not null 
				then ls.season_stats || array[row(
	                ts.season,
	                ts.pts,
	                ts.ast,
	                ts.reb, ts.weight
				)::season_stats]
			else ls.season_stats
		end as season_stats,
		CASE
			WHEN ts.season IS NOT NULL THEN
			 (CASE WHEN ts.pts > 20 THEN 'star'
				WHEN ts.pts > 15 THEN 'good'
				WHEN ts.pts > 10 THEN 'average'
				ELSE 'bad' END)::scoring_class
			ELSE ls.scoring_class
		end as scoring_class,
		case when ts.season is not null
			then 0
			else ls.years_since_last_active + 1
		end as years_since_last_active,
		coalesce(ts.season, ls.current_season + 1) as current_season,
		case when ts.season is not null
			then true
		end as is_active
    FROM this_season ts
    FULL OUTER JOIN last_season ls
    ON ls.player_name = ts.player_name;


select * from players_1 where current_season = 2002

drop table players_scd;

create table players_scd(
player_name text,
scoring_class scoring_class,
is_active boolean,
start_season integer,
end_season integer,
this_season integer,
primary key(player_name, start_season)
);

insert into players_scd
with previous as (
	select player_name,
		current_season,
		scoring_class,
		is_active,
		lag(scoring_class, 1) over (partition by player_name order by current_season) as previous_scoring_class,
		lag(is_active, 1) over (partition by player_name order by current_season) as previous_is_active
	from players_1
	where current_season <= 2021
),
indicators as (
	select *,
		case when scoring_class <> previous_scoring_class then 1
		when is_active <> previous_is_active then 1
		else 0
		end as change_indicator	
	from previous
),
with_streaks as (
select *,
	sum(change_indicator) over (partition by player_name order by current_season) as streak_identifier
from indicators
),
with_with as (
select player_name,
scoring_class,
is_active,
min(current_season) as start_season,
max(current_season) as end_season,
2021 as this_season
from with_streaks
group by player_name, streak_identifier,
is_active,
scoring_class
)
select *
from with_with
order by this_season desc, end_season desc
;
-- select *,
-- 	sum(change_indicator) over (partition by player_name order by current_season)
-- 		as streak_identifier
-- from indicators

select *
from players_scd
where this_season = 2021
order by this_season desc;

	select player_name,
		current_season,
		scoring_class,
		is_active,
		lag(scoring_class, 1) over (partition by player_name order by current_season) as previous_scoring_class,
		lag(is_active, 1) over (partition by player_name order by current_season) as previous_is_active
	from players_1
	where current_season <= 2021
order by current_season desc;
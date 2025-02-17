WITH last_season AS (
    SELECT * FROM players
    WHERE current_season = 1997

), this_season AS (
     SELECT * FROM player_seasons
    WHERE season = 1998
)
INSERT INTO players
SELECT
        COALESCE(ls.player_name, ts.player_name) as player_name,
        COALESCE(ls.height, ts.height) as height,
        COALESCE(ls.college, ts.college) as college,
        COALESCE(ls.country, ts.country) as country,
        COALESCE(ls.draft_year, ts.draft_year) as draft_year,
        COALESCE(ls.draft_round, ts.draft_round) as draft_round,
        COALESCE(ls.draft_number, ts.draft_number)
            as draft_number,
        COALESCE(ls.seasons,
            ARRAY[]::season_stats[]
            ) || CASE WHEN ts.season IS NOT NULL THEN
                ARRAY[ROW(
                ts.season,
                ts.pts,
                ts.ast,
                ts.reb, ts.weight)::season_stats]
                ELSE ARRAY[]::season_stats[] END
            as seasons,
         CASE
             WHEN ts.season IS NOT NULL THEN
                 (CASE WHEN ts.pts > 20 THEN 'star'
                    WHEN ts.pts > 15 THEN 'good'
                    WHEN ts.pts > 10 THEN 'average'
                    ELSE 'bad' END)::scoring_class
             ELSE ls.scoring_class
         END as scoring_class,
         ts.season IS NOT NULL as is_active,
         1998 AS current_season

    FROM last_season ls
    FULL OUTER JOIN this_season ts
    ON ls.player_name = ts.player_name;

-- my query
 CREATE TYPE season_stats AS (
                         season Integer,
                         pts REAL,
                         ast REAL,
                         reb REAL,
                         weight INTEGER
                       );
					   
 CREATE TYPE scoring_class AS
     ENUM ('bad', 'average', 'good', 'star');


 CREATE TABLE players (
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
     is_active BOOLEAN,
     current_season INTEGER,
     PRIMARY KEY (player_name, current_season)
 );

select * from players where current_season = 2001;

select * from player_seasons order by season;

WITH last_season AS (
    SELECT * FROM players
    WHERE current_season = 2000
), 
this_season AS (
    SELECT * FROM player_seasons
    WHERE season = 2001
)
INSERT INTO players
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
		case when ts.season is not null
			then true
		end,
		coalesce(ts.season, ls.current_season + 1) as current_season
    FROM this_season ts
    FULL OUTER JOIN last_season ls
    ON ls.player_name = ts.player_name;

	select player_name,
	(season_stats[1]::season_stats).pts as first_season,
	(season_stats[cardinality(season_stats)]::season_stats).pts as latest_season
	from players
	where current_season = 2001;
	
create table fct_game_details(
	dim_game_date date,
	dim_season integer,
	dim_team_id integer,
	dim_player_id integer,
	dim_player_name text,
	dim_start_position text,
	dim_is_playing_at_home boolean,
	dim_did_not_play boolean,
	dim_did_not_dress boolean,
	dim_not_with_team boolean,
	m_minutes real,
	m_fgm integer,
	m_fga integer,
	m_fg3m integer,
	m_fg3a integer,
	m_ftm integer,
	m_fta integer,
	m_oreb integer,
	m_dreb integer,
	m_reb integer,
	m_ast integer,
	m_stl integer,
	m_blk integer,
	m_turnovers integer,
	m_pf integer,
	m_pts integer,
	m_plus_minus integer,
	primary key (dim_game_date, dim_team_id, dim_player_id)
);

select dim_player_name,
count(1) as num_games,
count(case when dim_not_with_team then 1 End),
cast(count(case when dim_not_with_team then 1 End) as real)/count(1) as bail_pct
from fct_game_details gd
group by 1 order by 4 desc;


insert into fct_game_details
WITH deduped as (
	select 
		g.game_date_est,
		g.season,
		g.home_team_id,
		gd.*,
		row_number() over(partition by gd.game_id, team_id, player_id order by g.game_date_est) as row_num
	from game_details gd
	join games g
	on gd.game_id = g.game_id
)
select
	game_date_est as dim_game_date,
	season as dim_season,
	team_id as dim_team_id,
	player_id as dim_player_id,
	player_name as dim_player_name,
	start_position as dim_start_position,
	team_id = home_team_id as dim_is_playing_at_home,
	coalesce(position('DNP' in comment), 0) > 0 as dim_did_not_play,
	coalesce(position('DND' in comment), 0) > 0 as dim_did_not_dress,
	coalesce(position('NWT' in comment), 0) > 0 as dim_not_with_team,
	cast(split_part(min, ':', 1) as real) + cast(split_part(min, ':', 2) as real)/60 as M_minutes,
	fgm as m_fgm,
	fga as m_fga,
	fg3m as m_fg3m,
	fg3a as m_fg3a,
	ftm as m_ftm,
	fta as m_fta,
	oreb as m_oreb,
	dreb as m_dreb,
	reb as m_reb,
	ast as m_ast,
	stl as m_stl,
	blk as m_blk,
	"TO" as m_turnovers,
	pf as m_pf,
	pts as m_pts,
	plus_minus as m_plus_minus
from deduped
where row_num = 1;


select game_id,
team_id,
player_id,
count(1)
from game_details
group by 1,2,3
having count(1) > 1;

select *
from fct_game_details;

with agg_prepped as (
	select dim_player_name,
		dim_is_playing_at_home,
		sum(m_fgm) as fgm_count,
		sum(m_fga) as fga_count,
		sum(m_fg3m) as fg3m_count,
		sum(m_fg3a) as fg3a_count
	from fct_game_details
	group by dim_player_name,
		dim_is_playing_at_home
), agg_agged as (
	select dim_player_name,
		dim_is_playing_at_home,
		fgm_count,
		fga_count,
		case when fga_count = 0 then 0
			else fgm_count::real / fga_count::real
		end as two_pt_shot_percentage,
		fg3m_count,
		fg3a_count,
		case when fg3a_count = 0 then 0
			else fg3m_count::real / fg3a_count::real
		end as three_pt_shot_percentage
	from agg_prepped
	order by dim_player_name
), pct_agg as (
select dim_player_name,
	max(case when dim_is_playing_at_home then fgm_count end) as home_two_pt_total,
	max(case when dim_is_playing_at_home then fga_count end) as home_two_pt_attempt_total,
	max(case when dim_is_playing_at_home then two_pt_shot_percentage
	end) as home_two_pt_percent,
	max(case when not dim_is_playing_at_home then fgm_count end) as away_two_pt_total,
	max(case when not dim_is_playing_at_home then fga_count end) as away_two_pt_attempt_total,
	max(case when not dim_is_playing_at_home then two_pt_shot_percentage
	end) as away_two_pt_percent,
	max(case when dim_is_playing_at_home then fg3m_count end) as home_three_pt_total,
	max(case when dim_is_playing_at_home then fg3a_count end) as home_three_pt_attempt_total,
	max(case when dim_is_playing_at_home then three_pt_shot_percentage
	end) as home_three_pt_percent,
	max(case when not dim_is_playing_at_home then fg3m_count end) as away_three_pt_total,
	max(case when not dim_is_playing_at_home then fg3a_count end) as away_three_pt_attempt_total,
	max(case when not dim_is_playing_at_home then three_pt_shot_percentage
	end) as away_three_pt_percent
from agg_agged
group by 1
having max(case when dim_is_playing_at_home then fga_count end) > 2000
)
select dim_player_name,
home_three_pt_total + away_three_pt_total as total_threes,
home_three_pt_percent,
away_three_pt_percent
from pct_agg
order by 3 desc;

-- query to deduplicate game_details
with deduped as (
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
select count(*)
from deduped
where row_num = 1;

-- creating user_devices_cumulated
create table user_devices_cumulated (
	user_id text,
	dates_active jsonb,
	date date,
	primary key (user_id, date)
);

 -- query that FINALLY WORKED
insert into user_devices_cumulated
with yesterday as (
	SELECT
	    user_id,
	    je.key AS browser_type,
	    date,
	    je.value::jsonb AS dates_active
	from user_devices_cumulated,
	LATERAL jsonb_each(device_activity_datelist::jsonb) je
	where date = date('2023-01-04')
),
yesterday_prepped as (
	SELECT 
	    user_id,
	    browser_type,
	    ARRAY(
	        SELECT value::date 
	        FROM jsonb_array_elements_text(dates_active)
	    ) AS dates_active_array,
	    date
	FROM yesterday
),
today as (
	select
		cast(e.user_id as text) as user_id,
		date(cast(e.event_time as timestamp)) as date_active,
		case
			when d.browser_type is null then 'Unknown'
			else d.browser_type
		end as browser_type
	from events e
	left join devices d on e.device_id = d.device_id
	where
		date(cast(e.event_time as timestamp)) = date('2023-01-05')
		and e.user_id is not null
	group by e.user_id, d.browser_type, date(cast(e.event_time as timestamp))
),
preagg as (
	select
		coalesce(y.user_id, t.user_id) as user_id,
		coalesce(y.browser_type, t.browser_type) as browser_type,
		case when y.dates_active_array is null then array[t.date_active]
			when t.date_active is NULL then y.dates_active_array
			else array[t.date_active] || y.dates_active_array
		end as dates_active,
		coalesce(t.date_active, y.date + interval '1 day') as date
	from today t
	full outer join yesterday_prepped y
	on t.user_id = y.user_id
)
select user_id,
	jsonb_object_agg(browser_type, dates_active) as device_activity_datelist,
	date
from preagg
group by user_id, date;


select *,
    (SELECT COUNT(*) FROM jsonb_object_keys(dates_active)) AS key_count
from user_devices_cumulated_2
where date = '2023-01-21'
order by key_count DESC, user_id;

select e.user_id, e.event_time, d.browser_type, row_number() over(partition by user_id order by event_time, browser_type) as row_num
from events e left join devices d on d.device_id = e.device_id
where e.user_id is not null and user_id != '14434123505499000000'
order by row_num desc;

with cte as (
	select e.user_id, date(e.event_time) as date, d.browser_type
	from events e left join devices d on d.device_id = e.device_id
	where e.user_id is not null
	group by 1, 2, 3
)
select *, row_number() over(partition by user_id order by date, browser_type) as row_num
from cte
order by row_num desc, user_id
;

select *
from user_devices_cumulated_2
where user_id = '14434123505499000000';

SELECT
    user_id,
    je.key AS browser_type,
    date,
    array[cast(cast(jsonb_agg(je.value::jsonb)#>'{0,0}' as text) as date)] AS dates_active
FROM user_devices_cumulated,
LATERAL jsonb_array_elements(dates_active::jsonb) elem,
LATERAL jsonb_each(elem) je
group by user_id, je.key, date;

select * from user_devices_cumulated;



select
	user_id,
	date,
	cast(dates_active::jsonb->>0 as jsonb)
from user_devices_cumulated;

select e.*,
d.browser_type
from events e
left join devices d on e.device_id = d.device_id;


-- BEFORE RUINING
insert into user_devices_cumulated_1
with yesterday as (
	select
		*
	from user_devices_cumulated
	where date = date('2022-12-31')
),
today as (
	select
		cast(e.user_id as text) as user_id,
		date(cast(e.event_time as timestamp)) as date_active,
		case
			when d.browser_type is null then 'Unknown'
			else d.browser_type
		end as browser_type
	from events e
	left join devices d on e.device_id = d.device_id
	where
		date(cast(e.event_time as timestamp)) = date('2023-01-01')
		and e.user_id is not null
	group by e.user_id, d.browser_type, date(cast(e.event_time as timestamp))
), preagg as (
	select
		coalesce(t.user_id, y.user_id) as user_id,
		CASE
			when y.dates_active is null then json_build_object(
				t.browser_type, array[t.date_active]
			)::jsonb
			when t.date_active is null then y.dates_active
			else json_build_object(
				t.browser_type, array[t.date_active]
			)::jsonb || y.dates_active::jsonb
		end as dates_active,
		coalesce(t.date_active, y.date + interval '1 day') as date
	from today t
	full outer join yesterday y
	on t.user_id = y.user_id
	order by user_id
)
select user_id, json_agg(dates_active)::jsonb as dates_active, date
from preagg
group by user_id, date;

select *
from user_devices_cumulated_1
order by date desc;
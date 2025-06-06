create table host_activity_reduced (
	host text,
	month_start date,
	hit_array int[],
	unique_visitors_array int[],
	primary key (host, month_start)
);

	select
		host,
		date(event_time) as date,
		count(*) as num_hits,
		count(distinct user_id) as distinct_users
	from events
	group by host, date(event_time)
	order by date;

select *
from host_activity_reduced;

truncate table host_activity_reduced;

insert into host_activity_reduced
with daily_aggregate as (
	select
		host,
		date(event_time) as date,
		count(*) as num_hits,
		count(distinct user_id) as unique_users
	from events
	where date(event_time) = date('2023-01-21')
	group by host, date(event_time)
),
yesterday_array as (
	select *
	from host_activity_reduced
	where month_start = date('2023-01-01')
)
select 
	coalesce(da.host, ya.host) as host,
	coalesce(ya.month_start, date_trunc('month', da.date)) as month_start,
	case
		when ya.hit_array is not null
			THEN hit_array || array[coalesce(da.num_hits, 0)]
-- 		when ya.month_start is null
-- 			then array[coalesce(da.num_site_hits, 0)]
		when hit_array is null
			then array_fill(0, array[coalesce(date - date(date_trunc('month', date)), 0)])
				|| array[coalesce(da.num_hits, 0)]
	end	as hit_array,
	case
		when ya.unique_visitors_array is not null
			THEN unique_visitors_array || array[coalesce(da.unique_users, 0)]
-- 		when ya.month_start is null
-- 			then array[coalesce(da.num_site_hits, 0)]
		when unique_visitors_array is null
			then array_fill(0, array[coalesce(date - date(date_trunc('month', date)), 0)])
				|| array[coalesce(da.unique_users, 0)]
	end	as unique_visitors_array
from daily_aggregate da
full outer join yesterday_array ya on da.host = ya.host
on conflict (host, month_start)
DO
update set hit_array = excluded.hit_array,
	unique_visitors_array = excluded.unique_visitors_array;
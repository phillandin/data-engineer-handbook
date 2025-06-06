select *
from user_devices_cumulated_2
where date = '2023-01-31';


WITH starter AS (
    SELECT uc.device_activity_datelist @> ARRAY [DATE(d.valid_date)]   AS is_active,
           EXTRACT(
               DAY FROM DATE('2023-03-31') - d.valid_date) AS days_since,
           uc.user_id
    FROM user_devices_cumulated_2 uc
             CROSS JOIN
         (SELECT generate_series('2023-02-28', '2023-03-31', INTERVAL '1 day') AS valid_date) as d
    WHERE date = DATE('2023-03-31')
)
select *
from starter;
     bits AS (
         SELECT user_id,
                SUM(CASE
                        WHEN is_active THEN POW(2, 32 - days_since)
                        ELSE 0 END)::bigint::bit(32) AS datelist_int,
                DATE('2023-03-31') as date
         FROM starter
         GROUP BY user_id
     )

     INSERT INTO user_datelist_int
     SELECT * FROM bits;

select * from user_datelist_int;

with user_devices_exploded as (
	select
		user_id,
		date,
		key as device,
		array(select jsonb_array_elements_text(value)::date) as dates_active
	from user_devices_cumulated_2,
	lateral jsonb_each(device_activity_datelist)
	where date = date('2023-01-31')
),
series as (
	select *
	from generate_series(date('2023-01-01'), date('2023-01-31'), interval '1 day') as series_date
),
placeholder_ints as (
	select 
		case WHEN
			dates_active @> array[date(series_date)]
			then cast(pow(2, 32 - (date - date(series_date))) as bigint)
			else 0
		end as placeholder_int_value,
		*
	from user_devices_exploded cross join series
)
select user_id,
	cast(cast(sum(placeholder_int_value) as bigint) as bit(32)) as device_activity_datelist,
	bit_count(cast(cast(sum(placeholder_int_value) as bigint) as bit(32))) > 0 as dim_is_monthly_active,
	bit_count(cast('11111110000000000000000000000000' as bit(32)) &
		cast(cast(sum(placeholder_int_value) as bigint) as bit(32))) > 0 as dim_is_weekly_active
from placeholder_ints
group by user_id
order by user_id;

select *
from users_cumulated;
with signup_date as (
  select  user_id, full_name, email, country, signup_source, signup_device, promo_signup_flag,
  to_date (
  case 
    when length (split_part (clean_date_signup, '-', 3))=4
    then concat (split_part (clean_date_signup, '-', 3), '-',
     lpad(split_part (clean_date_signup, '-', 2), 2, '0'), '-',
     lpad(split_part (clean_date_signup, '-', 1), 2, '0'))
    when length (split_part (clean_date_signup, '-', 3))=2
    then concat ('20', split_part (clean_date_signup, '-', 3), '-',
     lpad(split_part (clean_date_signup, '-', 2), 2, '0'), '-',
     lpad(split_part (clean_date_signup, '-', 1), 2, '0'))
    end, 'YYYY-MM-DD') as signup_date_clean
    from (
     select user_id, full_name, email, country, signup_source, signup_device, promo_signup_flag,
     replace (replace (split_part (trim (signup_datetime), ' ', 1), '.', '-'), '/', '-') AS clean_date_signup
     from public.cohort_users_raw
     ) as cleaned_users
    ),
 event_date as (
  select  event_id, user_id, event_type, revenue,
  to_date (
  case 
    when length (split_part (clean_date_event, '-', 3))=4
    then concat (split_part (clean_date_event, '-', 3), '-',
     lpad(split_part (clean_date_event, '-', 2), 2, '0'), '-',
     lpad(split_part (clean_date_event, '-', 1), 2, '0'))
    when length (split_part (clean_date_event, '-', 3))=2
    then concat ('20', split_part (clean_date_event, '-', 3), '-',
     lpad(split_part (clean_date_event, '-', 2), 2, '0'), '-',
     lpad(split_part (clean_date_event, '-', 1), 2, '0'))
    end, 'YYYY-MM-DD') as event_date
   from (
     select event_id, user_id, event_type, revenue,
     replace (replace (split_part (trim (event_datetime), ' ', 1), '.', '-'), '/', '-') AS clean_date_event
     from public.cohort_events_raw
    ) as cleaned_events
   ),
 joined_table as (
 select 
    sd.user_id,
    sd.full_name,
    sd.email,
    sd.country,
    sd.signup_source,
    sd.signup_device,
    sd.promo_signup_flag,
    to_char (sd.signup_date_clean, 'YYYY-MM') as cohort_month,
    ev.event_id,
    ev.event_type,
    ev.revenue,
    to_char (ev.event_date, 'YYYY-MM') as activity_month,
    (extract (year from ev.event_date) - extract (year from sd.signup_date_clean)) * 12
    +
    (extract (month from ev.event_date) - extract (month from sd.signup_date_clean)) as month_offset
from signup_date as sd
inner join event_date as ev
    on sd.user_id = ev.user_id
)
select 
promo_signup_flag,
cohort_month,
month_offset,
count (distinct user_id) AS users_total
from joined_table
where activity_month between '2025-01' and '2025-06'
and event_type != 'test_event'
group by promo_signup_flag, cohort_month, month_offset
order by promo_signup_flag, cohort_month, month_offset;

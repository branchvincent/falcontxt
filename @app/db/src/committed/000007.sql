--! Previous: sha1:62dd22ec3ac716714894d84bf1fc1df970b8bbd8
--! Hash: sha1:a74dc8ded75d5e7b7ceb325532c8000942aa32f7

alter table app_public.metric_definitions add column if not exists units text;
comment on column app_public.metric_definitions.units is 'The units of the metric.';

create or replace function app_public.facilities_metrics(
    facility app_public.facilities,
    name text,
    "interval" interval default '1 hour'
  ) returns setof app_public.metric as $$ BEGIN
    return query execute format('
    select
        time_bucket(%L, time) as time,
        count(*)::double precision,
        first(value, time),
        last(value, time),
        avg(value) as avg,
        sum(value) as sum,
        min(value) as min,
        max(value) as max
    from app_public.%I
    where facility_id = %s
    group by 1', interval, name, facility.id);
  END $$ language plpgsql stable strict;

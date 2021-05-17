--! Previous: sha1:77672d2ac143aefed94dc2517a137a0b0469471e
--! Hash: sha1:cee93f1d6c8c670fc330af3cfdab7f005913c88b

drop type if exists app_public.facility_ranking cascade;
create type app_public.facility_ranking as (
	rank integer,
    id integer,
    value float,
    tags text[]
);

create or replace function app_public.facility_rankings(metric text, tags text[] default '{}', "interval" interval default '30 days'::interval) returns setof app_public.facility_ranking
    language plpgsql stable strict
as $$ begin
    return query execute format('
    select
        (row_number() over (order by sum(m.value) desc))::int as rank,
        f.id,
        sum(m.value) as value,
        f.tags
    from
        app_public.facilities f
        join app_public.%I m on f.id = m.facility_id
    where
        f.tags @> %L
        and m.time >= now() - interval %L
    group by 2
    order by value desc', metric, tags, interval);
end $$;

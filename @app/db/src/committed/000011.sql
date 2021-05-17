--! Previous: sha1:65acdab79965a61345bb7ec38e7698a688f00793
--! Hash: sha1:e0ed95ff61513df5c8a777ed1a05478d62399174

create or replace function app_public.facility_distinct_tags()
returns text[] as $$
    select array_agg(distinct c)
    from (
        select unnest(tags)
        from app_public.facilities
        ) as t(c);
$$ language sql strict immutable;

--! Previous: sha1:f93354162c9928415ff10c18efbb3ef715a09f14
--! Hash: sha1:6065c54f7a8225db88c604072593b7426abfc823

--- Triggers ---

-- Ensure `created_at` is never mutated and `updated_at` is monotonically increasing
create or replace function app_private.tg__timestamps() returns trigger as $$
begin
    NEW.created_at = (case when TG_OP = 'INSERT' then now() else OLD.created_at end);
    NEW.updated_at = (case when TG_OP = 'UPDATE' and OLD.updated_at >= now() then OLD.updated_at + interval '1 millisecond' else NOW() end);
    return NEW;
end;
$$ language plpgsql volatile set search_path to pg_catalog, public, pg_temp;

-- Slugify
create or replace function app_private.slugify(value TEXT)
returns text as $$
    select trim(both '-' from regexp_replace(lower(trim(value)), '[^a-z0-9\\-_]+', '-', 'gi'))
$$ language sql strict immutable;

create or replace function app_private.tg__slugify_name() returns trigger as $$
begin
    NEW.slug := app_private.slugify(NEW.name);
    RETURN NEW;
end;
$$ language plpgsql volatile set search_path to pg_catalog, public, pg_temp;

--- Organizations ---
drop table if exists app_public.organizations cascade;
create table app_public.organizations (
    id serial primary key,
    name text not null check (char_length(name) < 80),
    slug text not null unique check (slug ~* '^[a-z0-9-]{1,80}$'),
    created_at timestamptz default now(),
    updated_at timestamptz default now()
);
create trigger _organizations_set_updated_at
  before update on app_public.organizations
  for each row execute procedure app_private.tg__timestamps();
create trigger _organizations_set_slug
  before insert on app_public.organizations
  for each row WHEN (NEW.name is not null and NEW.slug is null)
  execute procedure app_private.tg__slugify_name();

grant insert, select, update, delete on app_public.organizations to ":DATABASE_VISITOR";

comment on table app_public.organizations is 'An organization.';
comment on column app_public.organizations.id is 'The primary unique identifier for the org.';
comment on column app_public.organizations.name is 'The org’s name.';
comment on column app_public.organizations.slug is 'The org’s slug.';
comment on column app_public.organizations.created_at is 'The time this org was created.';
comment on column app_public.organizations.updated_at is 'The time this org was updated.';

--- Facilities ---
drop table if exists app_public.facilities;
create table app_public.facilities (
    id serial primary key,
    organization_id integer not null references app_public.organizations(id) on delete cascade,
    name text not null check (char_length(name) < 80),
    slug text not null unique check (slug ~* '^[a-z0-9-]{1,80}$'),
    created_at timestamptz default now(),
    updated_at timestamptz default now()
);
create trigger _facilities_set_updated_at
  before update on app_public.facilities
  for each row execute procedure app_private.tg__timestamps();
create trigger _facilities_set_slug
  before insert on app_public.facilities
  for each row WHEN (NEW.name is not null and NEW.slug is null)
  execute procedure app_private.tg__slugify_name();

grant insert, select, update, delete on app_public.facilities to ":DATABASE_VISITOR";

comment on table app_public.facilities is 'A facility.';
comment on column app_public.facilities.id is 'The primary unique identifier for the facility.';
comment on column app_public.facilities.organization_id is 'The facility’s associated organization.';
comment on column app_public.facilities.name is 'The facility’s name.';
comment on column app_public.facilities.slug is 'The facility’s slug.';
comment on column app_public.facilities.created_at is 'The time this facility was created.';
comment on column app_public.facilities.updated_at is 'The time this facility was updated.';

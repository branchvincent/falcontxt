--! Previous: sha1:6065c54f7a8225db88c604072593b7426abfc823
--! Hash: sha1:2cf49657e3c79c24bf8a4e60d1f2c610811fd75e

-- Devices
drop table if exists app_public.devices cascade;
create table if not exists app_public.devices(
    id serial primary key,
    facility_id int not null references app_public.facilities,
    name text not null check (char_length(name) < 80),
    slug text not null unique check (slug ~* '^[a-z0-9-]{1,80}$'),
    description text not null default '',
    created_at timestamptz default now(),
    updated_at timestamptz default now()
);
create trigger _devices_set_updated_at
  before update on app_public.devices
  for each row execute procedure app_private.tg__timestamps();
create trigger _devices_set_slug
  before insert on app_public.devices
  for each row WHEN (NEW.name is not null and NEW.slug is null)
  execute procedure app_private.tg__slugify_name();

grant insert, select, update, delete on app_public.devices to ":DATABASE_VISITOR";

comment on table app_public.devices is 'A device producing data.';
comment on column app_public.devices.id is 'The primary unique identifier for the device.';
comment on column app_public.devices.facility_id is 'The device’s associated facility.';
comment on column app_public.devices.name is 'The device’s name.';
comment on column app_public.devices.slug is 'The device’s slug.';
comment on column app_public.devices.slug is 'The device’s description.';
comment on column app_public.devices.created_at is 'The time this device was created.';
comment on column app_public.devices.updated_at is 'The time this device was updated.';

-- Readings
drop table if exists app_public.readings;
create table app_public.readings(
    time timestamptz not null,
    device_id int not null references app_public.devices(id),
    label varchar not null,
    data jsonb not null,
    metadata jsonb default '{}'
);

create index if not exists readings_device_time_idx on app_public.readings(device_id, time desc);
create unique index if not exists readings_device_label_time_idx on app_public.readings(device_id, label, time desc);
create index if not exists readings_data_idx on app_public.readings using gin (data);
create index if not exists readings_metadata_idx on app_public.readings using gin (metadata);
select create_hypertable('app_public.readings', 'time', if_not_exists => true);

grant insert, select, update, delete on app_public.readings to ":DATABASE_VISITOR";

comment on table app_public.readings is 'A reading from a device.';
comment on column app_public.readings.time is 'The time of the reading.';
comment on column app_public.readings.device_id is 'The reading’s associated device.';
comment on column app_public.readings.label is 'The reading’s name.';
comment on column app_public.readings.data is 'The readings’s slug.';
comment on column app_public.readings.metadata is 'The readings’s metadata.';

-- Metric definitions
drop table if exists app_public.metric_definitions;
create table app_public.metric_definitions(
    id serial primary key,
    name varchar not null unique,
    query varchar not null
);

grant insert, select, update, delete on app_public.metric_definitions to ":DATABASE_VISITOR";

comment on table app_public.metric_definitions is 'The definition of a metric.';
comment on column app_public.metric_definitions.id is 'The id of the metric definition.';
comment on column app_public.metric_definitions.name is 'The metric’s name.';
comment on column app_public.metric_definitions.query is 'The metric’s definition.';

INSERT INTO app_public.organizations(id, name) VALUES (1, 'ndustrial.io') ON CONFLICT DO NOTHING;
INSERT INTO app_public.facilities(id, organization_id, name, tags) VALUES (1, 1, 'Raleigh HQ', '{regionEast, NC}') ON CONFLICT DO NOTHING;
INSERT INTO app_public.facilities(id, organization_id, name, tags) VALUES (2, 1, 'Kentucky HQ', '{regionEast, KY}') ON CONFLICT DO NOTHING;
INSERT INTO app_public.facilities(id, organization_id, name, tags) VALUES (3, 1, 'Durham HQ', '{regionEast, NC}') ON CONFLICT DO NOTHING;
INSERT INTO app_public.facilities(id, organization_id, name, tags) VALUES (4, 1, 'Chapel Hill HQ', '{regionEast, NC}') ON CONFLICT DO NOTHING;
INSERT INTO app_public.facilities(id, organization_id, name, tags) VALUES (5, 1, 'Cary HQ', '{regionEast, NC}') ON CONFLICT DO NOTHING;

INSERT INTO app_public.devices(id, facility_id, name) VALUES (1, 1, 'meter1') ON CONFLICT DO NOTHING;
INSERT INTO app_public.devices(id, facility_id, name) VALUES (2, 2, 'meter2') ON CONFLICT DO NOTHING;
INSERT INTO app_public.devices(id, facility_id, name) VALUES (3, 3, 'meter3') ON CONFLICT DO NOTHING;
INSERT INTO app_public.devices(id, facility_id, name) VALUES (4, 4, 'meter4') ON CONFLICT DO NOTHING;
INSERT INTO app_public.devices(id, facility_id, name) VALUES (5, 5, 'meter5') ON CONFLICT DO NOTHING;

CREATE OR REPLACE FUNCTION random_between(low numeric ,high numeric)
   RETURNS INT AS
$$
BEGIN
   RETURN floor(random()* (high - low + 1) + low);
END;
$$ language plpgsql STRICT;


INSERT INTO app_public.readings
SELECT
    t AS time,
    m.id AS device_id,
    'usage' AS label,
    random_between(18000, 22000)::text::jsonb AS data,
    '{}'::jsonb AS metadata
FROM
    generate_series('2020-01-01'::timestamptz, now(), '1 day') t,
    (SELECT id FROM app_public.devices) m
ON CONFLICT (device_id, time, label) DO UPDATE SET data = EXCLUDED.data;

INSERT INTO app_public.readings
SELECT
    t AS time,
    m.id AS device_id,
    'spend' AS label,
    random_between(3000, 8000)::text::jsonb AS data,
    '{}'::jsonb AS metadata
FROM
    generate_series('2020-01-01'::timestamptz, now(), '1 day') t,
    (SELECT id FROM app_public.devices) m
ON CONFLICT (device_id, time, label) DO UPDATE SET data = EXCLUDED.data;

INSERT INTO app_public.readings
SELECT
    t AS time,
    m.id AS device_id,
    'revenue' AS label,
    random_between(35000, 65000)::text::jsonb AS data,
    '{}'::jsonb AS metadata
FROM
    generate_series('2020-01-01'::timestamptz, now(), '1 day') t,
    (SELECT id FROM app_public.devices) m
ON CONFLICT (device_id, time, label) DO UPDATE SET data = EXCLUDED.data;

INSERT INTO app_public.readings
SELECT
    t AS time,
    m.id AS device_id,
    'inbound_volume' AS label,
    random_between(7.5e5, 12.5e5)::text::jsonb AS data,
    '{}'::jsonb AS metadata
FROM
    generate_series('2020-01-01'::timestamptz, now(), '1 day') t,
    (SELECT id FROM app_public.devices) m
ON CONFLICT (device_id, time, label) DO UPDATE SET data = EXCLUDED.data;

INSERT INTO app_public.readings
SELECT
    t AS time,
    m.id AS device_id,
    'outbound_volume' AS label,
    random_between(7.5e5, 12.5e5)::text::jsonb AS data,
    '{}'::jsonb AS metadata
FROM
    generate_series('2020-01-01'::timestamptz, now(), '1 day') t,
    (SELECT id FROM app_public.devices) m
ON CONFLICT (device_id, time, label) DO UPDATE SET data = EXCLUDED.data;

DROP FUNCTION app_public.random_between;

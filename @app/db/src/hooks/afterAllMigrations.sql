INSERT INTO app_public.organizations(id, name) VALUES (1, 'ndustrial.io') ON CONFLICT DO NOTHING;
INSERT INTO app_public.facilities(organization_id, name) VALUES (1, 'Raleigh HQ') ON CONFLICT DO NOTHING;

INSERT INTO app_public.devices(facility_id, name) VALUES (1, 'meter1') ON CONFLICT DO NOTHING;
INSERT INTO app_public.devices(facility_id, name) VALUES (1, 'meter2') ON CONFLICT DO NOTHING;

INSERT INTO app_public.readings
SELECT
    t AS time,
    m.id AS device_id,
    'usage' AS label,
    floor((random() * 7 + 10) * (row_number() OVER ()))::text::jsonb AS data,
    '{}'::jsonb AS metadata
FROM
    generate_series('2021-01-01'::timestamptz, now(), '1 day') t,
    (SELECT id FROM app_public.devices WHERE name IN ('meter1', 'meter2')) m
ON CONFLICT (device_id, time, label) DO UPDATE SET data = EXCLUDED.data;

INSERT INTO app_public.readings
SELECT
    t AS time,
    m.id AS device_id,
    'cost' AS label,
    round((random() * 2)::numeric, 2)::text::jsonb AS data,
    '{}'::jsonb AS metadata
FROM
    generate_series('2021-01-01'::timestamptz, now(), '1 day') t,
    (SELECT id FROM app_public.devices WHERE name IN ('meter1', 'meter2')) m
ON CONFLICT (device_id, time, label) DO UPDATE SET data = EXCLUDED.data;

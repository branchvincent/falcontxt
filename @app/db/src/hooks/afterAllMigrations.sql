INSERT INTO app_public.organizations(id, name) VALUES (1, 'ndustrial.io') ON CONFLICT DO NOTHING;
INSERT INTO app_public.facilities(organization_id, name) VALUES (1, 'Raleigh HQ') ON CONFLICT DO NOTHING;

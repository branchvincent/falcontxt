--
-- PostgreSQL database dump
--

-- Dumped from database version 13.2 (Debian 13.2-1.pgdg100+1)
-- Dumped by pg_dump version 13.3

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: timescaledb; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS timescaledb WITH SCHEMA public;


--
-- Name: EXTENSION timescaledb; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION timescaledb IS 'Enables scalable inserts and complex queries for time-series data';


--
-- Name: app_hidden; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA app_hidden;


--
-- Name: SCHEMA app_hidden; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA app_hidden IS 'User-accessible but private implementation details';


--
-- Name: app_private; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA app_private;


--
-- Name: SCHEMA app_private; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA app_private IS 'Private credentials accessible only to database owner';


--
-- Name: app_public; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA app_public;


--
-- Name: SCHEMA app_public; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA app_public IS 'Core public interface and schema for GraphQL';


--
-- Name: timescale_analytics; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS timescale_analytics WITH SCHEMA public;


--
-- Name: EXTENSION timescale_analytics; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION timescale_analytics IS 'timescale_analytics';


--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: slugify(text); Type: FUNCTION; Schema: app_private; Owner: -
--

CREATE FUNCTION app_private.slugify(value text) RETURNS text
    LANGUAGE sql IMMUTABLE STRICT
    AS $$
    select trim(both '-' from regexp_replace(lower(trim(value)), '[^a-z0-9\\-_]+', '-', 'gi'))
$$;


--
-- Name: tg__slugify_name(); Type: FUNCTION; Schema: app_private; Owner: -
--

CREATE FUNCTION app_private.tg__slugify_name() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'pg_catalog', 'public', 'pg_temp'
    AS $$
begin
    NEW.slug := app_private.slugify(NEW.name);
    RETURN NEW;
end;
$$;


--
-- Name: tg__timestamps(); Type: FUNCTION; Schema: app_private; Owner: -
--

CREATE FUNCTION app_private.tg__timestamps() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'pg_catalog', 'public', 'pg_temp'
    AS $$
begin
    NEW.created_at = (case when TG_OP = 'INSERT' then now() else OLD.created_at end);
    NEW.updated_at = (case when TG_OP = 'UPDATE' and OLD.updated_at >= now() then OLD.updated_at + interval '1 millisecond' else NOW() end);
    return NEW;
end;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: devices; Type: TABLE; Schema: app_public; Owner: -
--

CREATE TABLE app_public.devices (
    id integer NOT NULL,
    facility_id integer NOT NULL,
    name text NOT NULL,
    slug text NOT NULL,
    description text DEFAULT ''::text NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT devices_name_check CHECK ((char_length(name) < 80)),
    CONSTRAINT devices_slug_check CHECK ((slug ~* '^[a-z0-9-]{1,80}$'::text))
);


--
-- Name: TABLE devices; Type: COMMENT; Schema: app_public; Owner: -
--

COMMENT ON TABLE app_public.devices IS 'A device producing data.';


--
-- Name: COLUMN devices.id; Type: COMMENT; Schema: app_public; Owner: -
--

COMMENT ON COLUMN app_public.devices.id IS 'The primary unique identifier for the device.';


--
-- Name: COLUMN devices.facility_id; Type: COMMENT; Schema: app_public; Owner: -
--

COMMENT ON COLUMN app_public.devices.facility_id IS 'The device’s associated facility.';


--
-- Name: COLUMN devices.name; Type: COMMENT; Schema: app_public; Owner: -
--

COMMENT ON COLUMN app_public.devices.name IS 'The device’s name.';


--
-- Name: COLUMN devices.slug; Type: COMMENT; Schema: app_public; Owner: -
--

COMMENT ON COLUMN app_public.devices.slug IS 'The device’s description.';


--
-- Name: COLUMN devices.created_at; Type: COMMENT; Schema: app_public; Owner: -
--

COMMENT ON COLUMN app_public.devices.created_at IS 'The time this device was created.';


--
-- Name: COLUMN devices.updated_at; Type: COMMENT; Schema: app_public; Owner: -
--

COMMENT ON COLUMN app_public.devices.updated_at IS 'The time this device was updated.';


--
-- Name: devices_id_seq; Type: SEQUENCE; Schema: app_public; Owner: -
--

CREATE SEQUENCE app_public.devices_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: devices_id_seq; Type: SEQUENCE OWNED BY; Schema: app_public; Owner: -
--

ALTER SEQUENCE app_public.devices_id_seq OWNED BY app_public.devices.id;


--
-- Name: facilities; Type: TABLE; Schema: app_public; Owner: -
--

CREATE TABLE app_public.facilities (
    id integer NOT NULL,
    organization_id integer NOT NULL,
    name text NOT NULL,
    slug text NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT facilities_name_check CHECK ((char_length(name) < 80)),
    CONSTRAINT facilities_slug_check CHECK ((slug ~* '^[a-z0-9-]{1,80}$'::text))
);


--
-- Name: TABLE facilities; Type: COMMENT; Schema: app_public; Owner: -
--

COMMENT ON TABLE app_public.facilities IS 'A facility.';


--
-- Name: COLUMN facilities.id; Type: COMMENT; Schema: app_public; Owner: -
--

COMMENT ON COLUMN app_public.facilities.id IS 'The primary unique identifier for the facility.';


--
-- Name: COLUMN facilities.organization_id; Type: COMMENT; Schema: app_public; Owner: -
--

COMMENT ON COLUMN app_public.facilities.organization_id IS 'The facility’s associated organization.';


--
-- Name: COLUMN facilities.name; Type: COMMENT; Schema: app_public; Owner: -
--

COMMENT ON COLUMN app_public.facilities.name IS 'The facility’s name.';


--
-- Name: COLUMN facilities.slug; Type: COMMENT; Schema: app_public; Owner: -
--

COMMENT ON COLUMN app_public.facilities.slug IS 'The facility’s slug.';


--
-- Name: COLUMN facilities.created_at; Type: COMMENT; Schema: app_public; Owner: -
--

COMMENT ON COLUMN app_public.facilities.created_at IS 'The time this facility was created.';


--
-- Name: COLUMN facilities.updated_at; Type: COMMENT; Schema: app_public; Owner: -
--

COMMENT ON COLUMN app_public.facilities.updated_at IS 'The time this facility was updated.';


--
-- Name: facilities_id_seq; Type: SEQUENCE; Schema: app_public; Owner: -
--

CREATE SEQUENCE app_public.facilities_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: facilities_id_seq; Type: SEQUENCE OWNED BY; Schema: app_public; Owner: -
--

ALTER SEQUENCE app_public.facilities_id_seq OWNED BY app_public.facilities.id;


--
-- Name: metric_definitions; Type: TABLE; Schema: app_public; Owner: -
--

CREATE TABLE app_public.metric_definitions (
    id integer NOT NULL,
    name character varying NOT NULL,
    query character varying NOT NULL
);


--
-- Name: TABLE metric_definitions; Type: COMMENT; Schema: app_public; Owner: -
--

COMMENT ON TABLE app_public.metric_definitions IS 'The definition of a metric.';


--
-- Name: COLUMN metric_definitions.id; Type: COMMENT; Schema: app_public; Owner: -
--

COMMENT ON COLUMN app_public.metric_definitions.id IS 'The id of the metric definition.';


--
-- Name: COLUMN metric_definitions.name; Type: COMMENT; Schema: app_public; Owner: -
--

COMMENT ON COLUMN app_public.metric_definitions.name IS 'The metric’s name.';


--
-- Name: COLUMN metric_definitions.query; Type: COMMENT; Schema: app_public; Owner: -
--

COMMENT ON COLUMN app_public.metric_definitions.query IS 'The metric’s definition.';


--
-- Name: metric_definitions_id_seq; Type: SEQUENCE; Schema: app_public; Owner: -
--

CREATE SEQUENCE app_public.metric_definitions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: metric_definitions_id_seq; Type: SEQUENCE OWNED BY; Schema: app_public; Owner: -
--

ALTER SEQUENCE app_public.metric_definitions_id_seq OWNED BY app_public.metric_definitions.id;


--
-- Name: organizations; Type: TABLE; Schema: app_public; Owner: -
--

CREATE TABLE app_public.organizations (
    id integer NOT NULL,
    name text NOT NULL,
    slug text NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT organizations_name_check CHECK ((char_length(name) < 80)),
    CONSTRAINT organizations_slug_check CHECK ((slug ~* '^[a-z0-9-]{1,80}$'::text))
);


--
-- Name: TABLE organizations; Type: COMMENT; Schema: app_public; Owner: -
--

COMMENT ON TABLE app_public.organizations IS 'An organization.';


--
-- Name: COLUMN organizations.id; Type: COMMENT; Schema: app_public; Owner: -
--

COMMENT ON COLUMN app_public.organizations.id IS 'The primary unique identifier for the org.';


--
-- Name: COLUMN organizations.name; Type: COMMENT; Schema: app_public; Owner: -
--

COMMENT ON COLUMN app_public.organizations.name IS 'The org’s name.';


--
-- Name: COLUMN organizations.slug; Type: COMMENT; Schema: app_public; Owner: -
--

COMMENT ON COLUMN app_public.organizations.slug IS 'The org’s slug.';


--
-- Name: COLUMN organizations.created_at; Type: COMMENT; Schema: app_public; Owner: -
--

COMMENT ON COLUMN app_public.organizations.created_at IS 'The time this org was created.';


--
-- Name: COLUMN organizations.updated_at; Type: COMMENT; Schema: app_public; Owner: -
--

COMMENT ON COLUMN app_public.organizations.updated_at IS 'The time this org was updated.';


--
-- Name: organizations_id_seq; Type: SEQUENCE; Schema: app_public; Owner: -
--

CREATE SEQUENCE app_public.organizations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: organizations_id_seq; Type: SEQUENCE OWNED BY; Schema: app_public; Owner: -
--

ALTER SEQUENCE app_public.organizations_id_seq OWNED BY app_public.organizations.id;


--
-- Name: readings; Type: TABLE; Schema: app_public; Owner: -
--

CREATE TABLE app_public.readings (
    "time" timestamp with time zone NOT NULL,
    device_id integer NOT NULL,
    label character varying NOT NULL,
    data jsonb NOT NULL,
    metadata jsonb DEFAULT '{}'::jsonb
);


--
-- Name: TABLE readings; Type: COMMENT; Schema: app_public; Owner: -
--

COMMENT ON TABLE app_public.readings IS 'A reading from a device.';


--
-- Name: COLUMN readings."time"; Type: COMMENT; Schema: app_public; Owner: -
--

COMMENT ON COLUMN app_public.readings."time" IS 'The time of the reading.';


--
-- Name: COLUMN readings.device_id; Type: COMMENT; Schema: app_public; Owner: -
--

COMMENT ON COLUMN app_public.readings.device_id IS 'The reading’s associated device.';


--
-- Name: COLUMN readings.label; Type: COMMENT; Schema: app_public; Owner: -
--

COMMENT ON COLUMN app_public.readings.label IS 'The reading’s name.';


--
-- Name: COLUMN readings.data; Type: COMMENT; Schema: app_public; Owner: -
--

COMMENT ON COLUMN app_public.readings.data IS 'The readings’s slug.';


--
-- Name: COLUMN readings.metadata; Type: COMMENT; Schema: app_public; Owner: -
--

COMMENT ON COLUMN app_public.readings.metadata IS 'The readings’s metadata.';


--
-- Name: devices id; Type: DEFAULT; Schema: app_public; Owner: -
--

ALTER TABLE ONLY app_public.devices ALTER COLUMN id SET DEFAULT nextval('app_public.devices_id_seq'::regclass);


--
-- Name: facilities id; Type: DEFAULT; Schema: app_public; Owner: -
--

ALTER TABLE ONLY app_public.facilities ALTER COLUMN id SET DEFAULT nextval('app_public.facilities_id_seq'::regclass);


--
-- Name: metric_definitions id; Type: DEFAULT; Schema: app_public; Owner: -
--

ALTER TABLE ONLY app_public.metric_definitions ALTER COLUMN id SET DEFAULT nextval('app_public.metric_definitions_id_seq'::regclass);


--
-- Name: organizations id; Type: DEFAULT; Schema: app_public; Owner: -
--

ALTER TABLE ONLY app_public.organizations ALTER COLUMN id SET DEFAULT nextval('app_public.organizations_id_seq'::regclass);


--
-- Name: devices devices_pkey; Type: CONSTRAINT; Schema: app_public; Owner: -
--

ALTER TABLE ONLY app_public.devices
    ADD CONSTRAINT devices_pkey PRIMARY KEY (id);


--
-- Name: devices devices_slug_key; Type: CONSTRAINT; Schema: app_public; Owner: -
--

ALTER TABLE ONLY app_public.devices
    ADD CONSTRAINT devices_slug_key UNIQUE (slug);


--
-- Name: facilities facilities_pkey; Type: CONSTRAINT; Schema: app_public; Owner: -
--

ALTER TABLE ONLY app_public.facilities
    ADD CONSTRAINT facilities_pkey PRIMARY KEY (id);


--
-- Name: facilities facilities_slug_key; Type: CONSTRAINT; Schema: app_public; Owner: -
--

ALTER TABLE ONLY app_public.facilities
    ADD CONSTRAINT facilities_slug_key UNIQUE (slug);


--
-- Name: metric_definitions metric_definitions_name_key; Type: CONSTRAINT; Schema: app_public; Owner: -
--

ALTER TABLE ONLY app_public.metric_definitions
    ADD CONSTRAINT metric_definitions_name_key UNIQUE (name);


--
-- Name: metric_definitions metric_definitions_pkey; Type: CONSTRAINT; Schema: app_public; Owner: -
--

ALTER TABLE ONLY app_public.metric_definitions
    ADD CONSTRAINT metric_definitions_pkey PRIMARY KEY (id);


--
-- Name: organizations organizations_pkey; Type: CONSTRAINT; Schema: app_public; Owner: -
--

ALTER TABLE ONLY app_public.organizations
    ADD CONSTRAINT organizations_pkey PRIMARY KEY (id);


--
-- Name: organizations organizations_slug_key; Type: CONSTRAINT; Schema: app_public; Owner: -
--

ALTER TABLE ONLY app_public.organizations
    ADD CONSTRAINT organizations_slug_key UNIQUE (slug);


--
-- Name: readings_data_idx; Type: INDEX; Schema: app_public; Owner: -
--

CREATE INDEX readings_data_idx ON app_public.readings USING gin (data);


--
-- Name: readings_device_label_time_idx; Type: INDEX; Schema: app_public; Owner: -
--

CREATE UNIQUE INDEX readings_device_label_time_idx ON app_public.readings USING btree (device_id, label, "time" DESC);


--
-- Name: readings_device_time_idx; Type: INDEX; Schema: app_public; Owner: -
--

CREATE INDEX readings_device_time_idx ON app_public.readings USING btree (device_id, "time" DESC);


--
-- Name: readings_metadata_idx; Type: INDEX; Schema: app_public; Owner: -
--

CREATE INDEX readings_metadata_idx ON app_public.readings USING gin (metadata);


--
-- Name: readings_time_idx; Type: INDEX; Schema: app_public; Owner: -
--

CREATE INDEX readings_time_idx ON app_public.readings USING btree ("time" DESC);


--
-- Name: devices _devices_set_slug; Type: TRIGGER; Schema: app_public; Owner: -
--

CREATE TRIGGER _devices_set_slug BEFORE INSERT ON app_public.devices FOR EACH ROW WHEN (((new.name IS NOT NULL) AND (new.slug IS NULL))) EXECUTE FUNCTION app_private.tg__slugify_name();


--
-- Name: devices _devices_set_updated_at; Type: TRIGGER; Schema: app_public; Owner: -
--

CREATE TRIGGER _devices_set_updated_at BEFORE UPDATE ON app_public.devices FOR EACH ROW EXECUTE FUNCTION app_private.tg__timestamps();


--
-- Name: facilities _facilities_set_slug; Type: TRIGGER; Schema: app_public; Owner: -
--

CREATE TRIGGER _facilities_set_slug BEFORE INSERT ON app_public.facilities FOR EACH ROW WHEN (((new.name IS NOT NULL) AND (new.slug IS NULL))) EXECUTE FUNCTION app_private.tg__slugify_name();


--
-- Name: facilities _facilities_set_updated_at; Type: TRIGGER; Schema: app_public; Owner: -
--

CREATE TRIGGER _facilities_set_updated_at BEFORE UPDATE ON app_public.facilities FOR EACH ROW EXECUTE FUNCTION app_private.tg__timestamps();


--
-- Name: organizations _organizations_set_slug; Type: TRIGGER; Schema: app_public; Owner: -
--

CREATE TRIGGER _organizations_set_slug BEFORE INSERT ON app_public.organizations FOR EACH ROW WHEN (((new.name IS NOT NULL) AND (new.slug IS NULL))) EXECUTE FUNCTION app_private.tg__slugify_name();


--
-- Name: organizations _organizations_set_updated_at; Type: TRIGGER; Schema: app_public; Owner: -
--

CREATE TRIGGER _organizations_set_updated_at BEFORE UPDATE ON app_public.organizations FOR EACH ROW EXECUTE FUNCTION app_private.tg__timestamps();


--
-- Name: readings ts_insert_blocker; Type: TRIGGER; Schema: app_public; Owner: -
--

CREATE TRIGGER ts_insert_blocker BEFORE INSERT ON app_public.readings FOR EACH ROW EXECUTE FUNCTION _timescaledb_internal.insert_blocker();


--
-- Name: devices devices_facility_id_fkey; Type: FK CONSTRAINT; Schema: app_public; Owner: -
--

ALTER TABLE ONLY app_public.devices
    ADD CONSTRAINT devices_facility_id_fkey FOREIGN KEY (facility_id) REFERENCES app_public.facilities(id);


--
-- Name: facilities facilities_organization_id_fkey; Type: FK CONSTRAINT; Schema: app_public; Owner: -
--

ALTER TABLE ONLY app_public.facilities
    ADD CONSTRAINT facilities_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES app_public.organizations(id) ON DELETE CASCADE;


--
-- Name: readings readings_device_id_fkey; Type: FK CONSTRAINT; Schema: app_public; Owner: -
--

ALTER TABLE ONLY app_public.readings
    ADD CONSTRAINT readings_device_id_fkey FOREIGN KEY (device_id) REFERENCES app_public.devices(id);


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: -
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
GRANT USAGE ON SCHEMA public TO visitor;


--
-- Name: SCHEMA app_hidden; Type: ACL; Schema: -; Owner: -
--

GRANT USAGE ON SCHEMA app_hidden TO visitor;


--
-- Name: SCHEMA app_public; Type: ACL; Schema: -; Owner: -
--

GRANT USAGE ON SCHEMA app_public TO visitor;


--
-- Name: FUNCTION slugify(value text); Type: ACL; Schema: app_private; Owner: -
--

REVOKE ALL ON FUNCTION app_private.slugify(value text) FROM PUBLIC;


--
-- Name: FUNCTION tg__slugify_name(); Type: ACL; Schema: app_private; Owner: -
--

REVOKE ALL ON FUNCTION app_private.tg__slugify_name() FROM PUBLIC;


--
-- Name: FUNCTION tg__timestamps(); Type: ACL; Schema: app_private; Owner: -
--

REVOKE ALL ON FUNCTION app_private.tg__timestamps() FROM PUBLIC;


--
-- Name: TABLE devices; Type: ACL; Schema: app_public; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE app_public.devices TO visitor;


--
-- Name: SEQUENCE devices_id_seq; Type: ACL; Schema: app_public; Owner: -
--

GRANT SELECT,USAGE ON SEQUENCE app_public.devices_id_seq TO visitor;


--
-- Name: TABLE facilities; Type: ACL; Schema: app_public; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE app_public.facilities TO visitor;


--
-- Name: SEQUENCE facilities_id_seq; Type: ACL; Schema: app_public; Owner: -
--

GRANT SELECT,USAGE ON SEQUENCE app_public.facilities_id_seq TO visitor;


--
-- Name: TABLE metric_definitions; Type: ACL; Schema: app_public; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE app_public.metric_definitions TO visitor;


--
-- Name: SEQUENCE metric_definitions_id_seq; Type: ACL; Schema: app_public; Owner: -
--

GRANT SELECT,USAGE ON SEQUENCE app_public.metric_definitions_id_seq TO visitor;


--
-- Name: TABLE organizations; Type: ACL; Schema: app_public; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE app_public.organizations TO visitor;


--
-- Name: SEQUENCE organizations_id_seq; Type: ACL; Schema: app_public; Owner: -
--

GRANT SELECT,USAGE ON SEQUENCE app_public.organizations_id_seq TO visitor;


--
-- Name: TABLE readings; Type: ACL; Schema: app_public; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE app_public.readings TO visitor;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: app_hidden; Owner: -
--

ALTER DEFAULT PRIVILEGES FOR ROLE "user" IN SCHEMA app_hidden REVOKE ALL ON SEQUENCES  FROM "user";
ALTER DEFAULT PRIVILEGES FOR ROLE "user" IN SCHEMA app_hidden GRANT SELECT,USAGE ON SEQUENCES  TO visitor;


--
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: app_hidden; Owner: -
--

ALTER DEFAULT PRIVILEGES FOR ROLE "user" IN SCHEMA app_hidden REVOKE ALL ON FUNCTIONS  FROM PUBLIC;
ALTER DEFAULT PRIVILEGES FOR ROLE "user" IN SCHEMA app_hidden REVOKE ALL ON FUNCTIONS  FROM "user";
ALTER DEFAULT PRIVILEGES FOR ROLE "user" IN SCHEMA app_hidden GRANT ALL ON FUNCTIONS  TO visitor;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: app_public; Owner: -
--

ALTER DEFAULT PRIVILEGES FOR ROLE "user" IN SCHEMA app_public REVOKE ALL ON SEQUENCES  FROM "user";
ALTER DEFAULT PRIVILEGES FOR ROLE "user" IN SCHEMA app_public GRANT SELECT,USAGE ON SEQUENCES  TO visitor;


--
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: app_public; Owner: -
--

ALTER DEFAULT PRIVILEGES FOR ROLE "user" IN SCHEMA app_public REVOKE ALL ON FUNCTIONS  FROM PUBLIC;
ALTER DEFAULT PRIVILEGES FOR ROLE "user" IN SCHEMA app_public REVOKE ALL ON FUNCTIONS  FROM "user";
ALTER DEFAULT PRIVILEGES FOR ROLE "user" IN SCHEMA app_public GRANT ALL ON FUNCTIONS  TO visitor;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: public; Owner: -
--

ALTER DEFAULT PRIVILEGES FOR ROLE "user" IN SCHEMA public REVOKE ALL ON SEQUENCES  FROM "user";
ALTER DEFAULT PRIVILEGES FOR ROLE "user" IN SCHEMA public GRANT SELECT,USAGE ON SEQUENCES  TO visitor;


--
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: public; Owner: -
--

ALTER DEFAULT PRIVILEGES FOR ROLE "user" IN SCHEMA public REVOKE ALL ON FUNCTIONS  FROM PUBLIC;
ALTER DEFAULT PRIVILEGES FOR ROLE "user" IN SCHEMA public REVOKE ALL ON FUNCTIONS  FROM "user";
ALTER DEFAULT PRIVILEGES FOR ROLE "user" IN SCHEMA public GRANT ALL ON FUNCTIONS  TO visitor;


--
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: -; Owner: -
--

ALTER DEFAULT PRIVILEGES FOR ROLE "user" REVOKE ALL ON FUNCTIONS  FROM PUBLIC;


--
-- PostgreSQL database dump complete
--


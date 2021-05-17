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


SET default_tablespace = '';

SET default_table_access_method = heap;

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
    tags text[],
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
-- Name: facility_ranking; Type: TYPE; Schema: app_public; Owner: -
--

CREATE TYPE app_public.facility_ranking AS (
	rank integer,
	facility app_public.facilities,
	value double precision,
	tags text[]
);


--
-- Name: metric; Type: TYPE; Schema: app_public; Owner: -
--

CREATE TYPE app_public.metric AS (
	"time" timestamp with time zone,
	count double precision,
	first double precision,
	last double precision,
	avg double precision,
	sum double precision,
	min double precision,
	max double precision
);


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


--
-- Name: facilities_metrics(app_public.facilities, text, interval); Type: FUNCTION; Schema: app_public; Owner: -
--

CREATE FUNCTION app_public.facilities_metrics(facility app_public.facilities, name text, "interval" interval DEFAULT '01:00:00'::interval) RETURNS SETOF app_public.metric
    LANGUAGE plpgsql STABLE STRICT
    AS $$ BEGIN
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
  END $$;


--
-- Name: facility_distinct_tags(); Type: FUNCTION; Schema: app_public; Owner: -
--

CREATE FUNCTION app_public.facility_distinct_tags() RETURNS text[]
    LANGUAGE sql IMMUTABLE STRICT
    AS $$
    select array_agg(distinct c)
    from (
        select unnest(tags)
        from app_public.facilities
        ) as t(c);
$$;


--
-- Name: facility_rankings(text, text[], interval); Type: FUNCTION; Schema: app_public; Owner: -
--

CREATE FUNCTION app_public.facility_rankings(metric text, tags text[] DEFAULT '{}'::text[], "interval" interval DEFAULT '30 days'::interval) RETURNS SETOF app_public.facility_ranking
    LANGUAGE plpgsql STABLE STRICT
    AS $$ begin
    return query execute format('
    select
        (row_number() over (order by sum(m.value) desc))::int as rank,
        f,
        sum(m.value) as value,
        f.tags
    from
        app_public.facilities f
        join app_public.%I m on f.id = m.facility_id
    where
        f.tags @> %L
        and m.time >= now() - interval %L
    group by f.id
    order by value desc', metric, tags, interval);
end $$;


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
-- Name: _hyper_1_10_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: -
--

CREATE TABLE _timescaledb_internal._hyper_1_10_chunk (
    CONSTRAINT constraint_10 CHECK ((("time" >= '2020-02-27 00:00:00+00'::timestamp with time zone) AND ("time" < '2020-03-05 00:00:00+00'::timestamp with time zone)))
)
INHERITS (app_public.readings);


--
-- Name: _hyper_1_11_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: -
--

CREATE TABLE _timescaledb_internal._hyper_1_11_chunk (
    CONSTRAINT constraint_11 CHECK ((("time" >= '2020-03-05 00:00:00+00'::timestamp with time zone) AND ("time" < '2020-03-12 00:00:00+00'::timestamp with time zone)))
)
INHERITS (app_public.readings);


--
-- Name: _hyper_1_12_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: -
--

CREATE TABLE _timescaledb_internal._hyper_1_12_chunk (
    CONSTRAINT constraint_12 CHECK ((("time" >= '2020-03-12 00:00:00+00'::timestamp with time zone) AND ("time" < '2020-03-19 00:00:00+00'::timestamp with time zone)))
)
INHERITS (app_public.readings);


--
-- Name: _hyper_1_13_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: -
--

CREATE TABLE _timescaledb_internal._hyper_1_13_chunk (
    CONSTRAINT constraint_13 CHECK ((("time" >= '2020-03-19 00:00:00+00'::timestamp with time zone) AND ("time" < '2020-03-26 00:00:00+00'::timestamp with time zone)))
)
INHERITS (app_public.readings);


--
-- Name: _hyper_1_14_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: -
--

CREATE TABLE _timescaledb_internal._hyper_1_14_chunk (
    CONSTRAINT constraint_14 CHECK ((("time" >= '2020-03-26 00:00:00+00'::timestamp with time zone) AND ("time" < '2020-04-02 00:00:00+00'::timestamp with time zone)))
)
INHERITS (app_public.readings);


--
-- Name: _hyper_1_15_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: -
--

CREATE TABLE _timescaledb_internal._hyper_1_15_chunk (
    CONSTRAINT constraint_15 CHECK ((("time" >= '2020-04-02 00:00:00+00'::timestamp with time zone) AND ("time" < '2020-04-09 00:00:00+00'::timestamp with time zone)))
)
INHERITS (app_public.readings);


--
-- Name: _hyper_1_16_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: -
--

CREATE TABLE _timescaledb_internal._hyper_1_16_chunk (
    CONSTRAINT constraint_16 CHECK ((("time" >= '2020-04-09 00:00:00+00'::timestamp with time zone) AND ("time" < '2020-04-16 00:00:00+00'::timestamp with time zone)))
)
INHERITS (app_public.readings);


--
-- Name: _hyper_1_17_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: -
--

CREATE TABLE _timescaledb_internal._hyper_1_17_chunk (
    CONSTRAINT constraint_17 CHECK ((("time" >= '2020-04-16 00:00:00+00'::timestamp with time zone) AND ("time" < '2020-04-23 00:00:00+00'::timestamp with time zone)))
)
INHERITS (app_public.readings);


--
-- Name: _hyper_1_18_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: -
--

CREATE TABLE _timescaledb_internal._hyper_1_18_chunk (
    CONSTRAINT constraint_18 CHECK ((("time" >= '2020-04-23 00:00:00+00'::timestamp with time zone) AND ("time" < '2020-04-30 00:00:00+00'::timestamp with time zone)))
)
INHERITS (app_public.readings);


--
-- Name: _hyper_1_19_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: -
--

CREATE TABLE _timescaledb_internal._hyper_1_19_chunk (
    CONSTRAINT constraint_19 CHECK ((("time" >= '2020-04-30 00:00:00+00'::timestamp with time zone) AND ("time" < '2020-05-07 00:00:00+00'::timestamp with time zone)))
)
INHERITS (app_public.readings);


--
-- Name: _hyper_1_1_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: -
--

CREATE TABLE _timescaledb_internal._hyper_1_1_chunk (
    CONSTRAINT constraint_1 CHECK ((("time" >= '2019-12-26 00:00:00+00'::timestamp with time zone) AND ("time" < '2020-01-02 00:00:00+00'::timestamp with time zone)))
)
INHERITS (app_public.readings);


--
-- Name: _hyper_1_20_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: -
--

CREATE TABLE _timescaledb_internal._hyper_1_20_chunk (
    CONSTRAINT constraint_20 CHECK ((("time" >= '2020-05-07 00:00:00+00'::timestamp with time zone) AND ("time" < '2020-05-14 00:00:00+00'::timestamp with time zone)))
)
INHERITS (app_public.readings);


--
-- Name: _hyper_1_21_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: -
--

CREATE TABLE _timescaledb_internal._hyper_1_21_chunk (
    CONSTRAINT constraint_21 CHECK ((("time" >= '2020-05-14 00:00:00+00'::timestamp with time zone) AND ("time" < '2020-05-21 00:00:00+00'::timestamp with time zone)))
)
INHERITS (app_public.readings);


--
-- Name: _hyper_1_22_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: -
--

CREATE TABLE _timescaledb_internal._hyper_1_22_chunk (
    CONSTRAINT constraint_22 CHECK ((("time" >= '2020-05-21 00:00:00+00'::timestamp with time zone) AND ("time" < '2020-05-28 00:00:00+00'::timestamp with time zone)))
)
INHERITS (app_public.readings);


--
-- Name: _hyper_1_23_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: -
--

CREATE TABLE _timescaledb_internal._hyper_1_23_chunk (
    CONSTRAINT constraint_23 CHECK ((("time" >= '2020-05-28 00:00:00+00'::timestamp with time zone) AND ("time" < '2020-06-04 00:00:00+00'::timestamp with time zone)))
)
INHERITS (app_public.readings);


--
-- Name: _hyper_1_24_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: -
--

CREATE TABLE _timescaledb_internal._hyper_1_24_chunk (
    CONSTRAINT constraint_24 CHECK ((("time" >= '2020-06-04 00:00:00+00'::timestamp with time zone) AND ("time" < '2020-06-11 00:00:00+00'::timestamp with time zone)))
)
INHERITS (app_public.readings);


--
-- Name: _hyper_1_25_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: -
--

CREATE TABLE _timescaledb_internal._hyper_1_25_chunk (
    CONSTRAINT constraint_25 CHECK ((("time" >= '2020-06-11 00:00:00+00'::timestamp with time zone) AND ("time" < '2020-06-18 00:00:00+00'::timestamp with time zone)))
)
INHERITS (app_public.readings);


--
-- Name: _hyper_1_26_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: -
--

CREATE TABLE _timescaledb_internal._hyper_1_26_chunk (
    CONSTRAINT constraint_26 CHECK ((("time" >= '2020-06-18 00:00:00+00'::timestamp with time zone) AND ("time" < '2020-06-25 00:00:00+00'::timestamp with time zone)))
)
INHERITS (app_public.readings);


--
-- Name: _hyper_1_27_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: -
--

CREATE TABLE _timescaledb_internal._hyper_1_27_chunk (
    CONSTRAINT constraint_27 CHECK ((("time" >= '2020-06-25 00:00:00+00'::timestamp with time zone) AND ("time" < '2020-07-02 00:00:00+00'::timestamp with time zone)))
)
INHERITS (app_public.readings);


--
-- Name: _hyper_1_28_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: -
--

CREATE TABLE _timescaledb_internal._hyper_1_28_chunk (
    CONSTRAINT constraint_28 CHECK ((("time" >= '2020-07-02 00:00:00+00'::timestamp with time zone) AND ("time" < '2020-07-09 00:00:00+00'::timestamp with time zone)))
)
INHERITS (app_public.readings);


--
-- Name: _hyper_1_29_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: -
--

CREATE TABLE _timescaledb_internal._hyper_1_29_chunk (
    CONSTRAINT constraint_29 CHECK ((("time" >= '2020-07-09 00:00:00+00'::timestamp with time zone) AND ("time" < '2020-07-16 00:00:00+00'::timestamp with time zone)))
)
INHERITS (app_public.readings);


--
-- Name: _hyper_1_2_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: -
--

CREATE TABLE _timescaledb_internal._hyper_1_2_chunk (
    CONSTRAINT constraint_2 CHECK ((("time" >= '2020-01-02 00:00:00+00'::timestamp with time zone) AND ("time" < '2020-01-09 00:00:00+00'::timestamp with time zone)))
)
INHERITS (app_public.readings);


--
-- Name: _hyper_1_30_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: -
--

CREATE TABLE _timescaledb_internal._hyper_1_30_chunk (
    CONSTRAINT constraint_30 CHECK ((("time" >= '2020-07-16 00:00:00+00'::timestamp with time zone) AND ("time" < '2020-07-23 00:00:00+00'::timestamp with time zone)))
)
INHERITS (app_public.readings);


--
-- Name: _hyper_1_31_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: -
--

CREATE TABLE _timescaledb_internal._hyper_1_31_chunk (
    CONSTRAINT constraint_31 CHECK ((("time" >= '2020-07-23 00:00:00+00'::timestamp with time zone) AND ("time" < '2020-07-30 00:00:00+00'::timestamp with time zone)))
)
INHERITS (app_public.readings);


--
-- Name: _hyper_1_32_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: -
--

CREATE TABLE _timescaledb_internal._hyper_1_32_chunk (
    CONSTRAINT constraint_32 CHECK ((("time" >= '2020-07-30 00:00:00+00'::timestamp with time zone) AND ("time" < '2020-08-06 00:00:00+00'::timestamp with time zone)))
)
INHERITS (app_public.readings);


--
-- Name: _hyper_1_33_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: -
--

CREATE TABLE _timescaledb_internal._hyper_1_33_chunk (
    CONSTRAINT constraint_33 CHECK ((("time" >= '2020-08-06 00:00:00+00'::timestamp with time zone) AND ("time" < '2020-08-13 00:00:00+00'::timestamp with time zone)))
)
INHERITS (app_public.readings);


--
-- Name: _hyper_1_34_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: -
--

CREATE TABLE _timescaledb_internal._hyper_1_34_chunk (
    CONSTRAINT constraint_34 CHECK ((("time" >= '2020-08-13 00:00:00+00'::timestamp with time zone) AND ("time" < '2020-08-20 00:00:00+00'::timestamp with time zone)))
)
INHERITS (app_public.readings);


--
-- Name: _hyper_1_35_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: -
--

CREATE TABLE _timescaledb_internal._hyper_1_35_chunk (
    CONSTRAINT constraint_35 CHECK ((("time" >= '2020-08-20 00:00:00+00'::timestamp with time zone) AND ("time" < '2020-08-27 00:00:00+00'::timestamp with time zone)))
)
INHERITS (app_public.readings);


--
-- Name: _hyper_1_36_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: -
--

CREATE TABLE _timescaledb_internal._hyper_1_36_chunk (
    CONSTRAINT constraint_36 CHECK ((("time" >= '2020-08-27 00:00:00+00'::timestamp with time zone) AND ("time" < '2020-09-03 00:00:00+00'::timestamp with time zone)))
)
INHERITS (app_public.readings);


--
-- Name: _hyper_1_37_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: -
--

CREATE TABLE _timescaledb_internal._hyper_1_37_chunk (
    CONSTRAINT constraint_37 CHECK ((("time" >= '2020-09-03 00:00:00+00'::timestamp with time zone) AND ("time" < '2020-09-10 00:00:00+00'::timestamp with time zone)))
)
INHERITS (app_public.readings);


--
-- Name: _hyper_1_38_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: -
--

CREATE TABLE _timescaledb_internal._hyper_1_38_chunk (
    CONSTRAINT constraint_38 CHECK ((("time" >= '2020-09-10 00:00:00+00'::timestamp with time zone) AND ("time" < '2020-09-17 00:00:00+00'::timestamp with time zone)))
)
INHERITS (app_public.readings);


--
-- Name: _hyper_1_39_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: -
--

CREATE TABLE _timescaledb_internal._hyper_1_39_chunk (
    CONSTRAINT constraint_39 CHECK ((("time" >= '2020-09-17 00:00:00+00'::timestamp with time zone) AND ("time" < '2020-09-24 00:00:00+00'::timestamp with time zone)))
)
INHERITS (app_public.readings);


--
-- Name: _hyper_1_3_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: -
--

CREATE TABLE _timescaledb_internal._hyper_1_3_chunk (
    CONSTRAINT constraint_3 CHECK ((("time" >= '2020-01-09 00:00:00+00'::timestamp with time zone) AND ("time" < '2020-01-16 00:00:00+00'::timestamp with time zone)))
)
INHERITS (app_public.readings);


--
-- Name: _hyper_1_40_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: -
--

CREATE TABLE _timescaledb_internal._hyper_1_40_chunk (
    CONSTRAINT constraint_40 CHECK ((("time" >= '2020-09-24 00:00:00+00'::timestamp with time zone) AND ("time" < '2020-10-01 00:00:00+00'::timestamp with time zone)))
)
INHERITS (app_public.readings);


--
-- Name: _hyper_1_41_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: -
--

CREATE TABLE _timescaledb_internal._hyper_1_41_chunk (
    CONSTRAINT constraint_41 CHECK ((("time" >= '2020-10-01 00:00:00+00'::timestamp with time zone) AND ("time" < '2020-10-08 00:00:00+00'::timestamp with time zone)))
)
INHERITS (app_public.readings);


--
-- Name: _hyper_1_42_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: -
--

CREATE TABLE _timescaledb_internal._hyper_1_42_chunk (
    CONSTRAINT constraint_42 CHECK ((("time" >= '2020-10-08 00:00:00+00'::timestamp with time zone) AND ("time" < '2020-10-15 00:00:00+00'::timestamp with time zone)))
)
INHERITS (app_public.readings);


--
-- Name: _hyper_1_43_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: -
--

CREATE TABLE _timescaledb_internal._hyper_1_43_chunk (
    CONSTRAINT constraint_43 CHECK ((("time" >= '2020-10-15 00:00:00+00'::timestamp with time zone) AND ("time" < '2020-10-22 00:00:00+00'::timestamp with time zone)))
)
INHERITS (app_public.readings);


--
-- Name: _hyper_1_44_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: -
--

CREATE TABLE _timescaledb_internal._hyper_1_44_chunk (
    CONSTRAINT constraint_44 CHECK ((("time" >= '2020-10-22 00:00:00+00'::timestamp with time zone) AND ("time" < '2020-10-29 00:00:00+00'::timestamp with time zone)))
)
INHERITS (app_public.readings);


--
-- Name: _hyper_1_45_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: -
--

CREATE TABLE _timescaledb_internal._hyper_1_45_chunk (
    CONSTRAINT constraint_45 CHECK ((("time" >= '2020-10-29 00:00:00+00'::timestamp with time zone) AND ("time" < '2020-11-05 00:00:00+00'::timestamp with time zone)))
)
INHERITS (app_public.readings);


--
-- Name: _hyper_1_46_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: -
--

CREATE TABLE _timescaledb_internal._hyper_1_46_chunk (
    CONSTRAINT constraint_46 CHECK ((("time" >= '2020-11-05 00:00:00+00'::timestamp with time zone) AND ("time" < '2020-11-12 00:00:00+00'::timestamp with time zone)))
)
INHERITS (app_public.readings);


--
-- Name: _hyper_1_47_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: -
--

CREATE TABLE _timescaledb_internal._hyper_1_47_chunk (
    CONSTRAINT constraint_47 CHECK ((("time" >= '2020-11-12 00:00:00+00'::timestamp with time zone) AND ("time" < '2020-11-19 00:00:00+00'::timestamp with time zone)))
)
INHERITS (app_public.readings);


--
-- Name: _hyper_1_48_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: -
--

CREATE TABLE _timescaledb_internal._hyper_1_48_chunk (
    CONSTRAINT constraint_48 CHECK ((("time" >= '2020-11-19 00:00:00+00'::timestamp with time zone) AND ("time" < '2020-11-26 00:00:00+00'::timestamp with time zone)))
)
INHERITS (app_public.readings);


--
-- Name: _hyper_1_49_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: -
--

CREATE TABLE _timescaledb_internal._hyper_1_49_chunk (
    CONSTRAINT constraint_49 CHECK ((("time" >= '2020-11-26 00:00:00+00'::timestamp with time zone) AND ("time" < '2020-12-03 00:00:00+00'::timestamp with time zone)))
)
INHERITS (app_public.readings);


--
-- Name: _hyper_1_4_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: -
--

CREATE TABLE _timescaledb_internal._hyper_1_4_chunk (
    CONSTRAINT constraint_4 CHECK ((("time" >= '2020-01-16 00:00:00+00'::timestamp with time zone) AND ("time" < '2020-01-23 00:00:00+00'::timestamp with time zone)))
)
INHERITS (app_public.readings);


--
-- Name: _hyper_1_50_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: -
--

CREATE TABLE _timescaledb_internal._hyper_1_50_chunk (
    CONSTRAINT constraint_50 CHECK ((("time" >= '2020-12-03 00:00:00+00'::timestamp with time zone) AND ("time" < '2020-12-10 00:00:00+00'::timestamp with time zone)))
)
INHERITS (app_public.readings);


--
-- Name: _hyper_1_51_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: -
--

CREATE TABLE _timescaledb_internal._hyper_1_51_chunk (
    CONSTRAINT constraint_51 CHECK ((("time" >= '2020-12-10 00:00:00+00'::timestamp with time zone) AND ("time" < '2020-12-17 00:00:00+00'::timestamp with time zone)))
)
INHERITS (app_public.readings);


--
-- Name: _hyper_1_52_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: -
--

CREATE TABLE _timescaledb_internal._hyper_1_52_chunk (
    CONSTRAINT constraint_52 CHECK ((("time" >= '2020-12-17 00:00:00+00'::timestamp with time zone) AND ("time" < '2020-12-24 00:00:00+00'::timestamp with time zone)))
)
INHERITS (app_public.readings);


--
-- Name: _hyper_1_53_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: -
--

CREATE TABLE _timescaledb_internal._hyper_1_53_chunk (
    CONSTRAINT constraint_53 CHECK ((("time" >= '2020-12-24 00:00:00+00'::timestamp with time zone) AND ("time" < '2020-12-31 00:00:00+00'::timestamp with time zone)))
)
INHERITS (app_public.readings);


--
-- Name: _hyper_1_54_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: -
--

CREATE TABLE _timescaledb_internal._hyper_1_54_chunk (
    CONSTRAINT constraint_54 CHECK ((("time" >= '2020-12-31 00:00:00+00'::timestamp with time zone) AND ("time" < '2021-01-07 00:00:00+00'::timestamp with time zone)))
)
INHERITS (app_public.readings);


--
-- Name: _hyper_1_55_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: -
--

CREATE TABLE _timescaledb_internal._hyper_1_55_chunk (
    CONSTRAINT constraint_55 CHECK ((("time" >= '2021-01-07 00:00:00+00'::timestamp with time zone) AND ("time" < '2021-01-14 00:00:00+00'::timestamp with time zone)))
)
INHERITS (app_public.readings);


--
-- Name: _hyper_1_56_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: -
--

CREATE TABLE _timescaledb_internal._hyper_1_56_chunk (
    CONSTRAINT constraint_56 CHECK ((("time" >= '2021-01-14 00:00:00+00'::timestamp with time zone) AND ("time" < '2021-01-21 00:00:00+00'::timestamp with time zone)))
)
INHERITS (app_public.readings);


--
-- Name: _hyper_1_57_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: -
--

CREATE TABLE _timescaledb_internal._hyper_1_57_chunk (
    CONSTRAINT constraint_57 CHECK ((("time" >= '2021-01-21 00:00:00+00'::timestamp with time zone) AND ("time" < '2021-01-28 00:00:00+00'::timestamp with time zone)))
)
INHERITS (app_public.readings);


--
-- Name: _hyper_1_58_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: -
--

CREATE TABLE _timescaledb_internal._hyper_1_58_chunk (
    CONSTRAINT constraint_58 CHECK ((("time" >= '2021-01-28 00:00:00+00'::timestamp with time zone) AND ("time" < '2021-02-04 00:00:00+00'::timestamp with time zone)))
)
INHERITS (app_public.readings);


--
-- Name: _hyper_1_59_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: -
--

CREATE TABLE _timescaledb_internal._hyper_1_59_chunk (
    CONSTRAINT constraint_59 CHECK ((("time" >= '2021-02-04 00:00:00+00'::timestamp with time zone) AND ("time" < '2021-02-11 00:00:00+00'::timestamp with time zone)))
)
INHERITS (app_public.readings);


--
-- Name: _hyper_1_5_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: -
--

CREATE TABLE _timescaledb_internal._hyper_1_5_chunk (
    CONSTRAINT constraint_5 CHECK ((("time" >= '2020-01-23 00:00:00+00'::timestamp with time zone) AND ("time" < '2020-01-30 00:00:00+00'::timestamp with time zone)))
)
INHERITS (app_public.readings);


--
-- Name: _hyper_1_60_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: -
--

CREATE TABLE _timescaledb_internal._hyper_1_60_chunk (
    CONSTRAINT constraint_60 CHECK ((("time" >= '2021-02-11 00:00:00+00'::timestamp with time zone) AND ("time" < '2021-02-18 00:00:00+00'::timestamp with time zone)))
)
INHERITS (app_public.readings);


--
-- Name: _hyper_1_61_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: -
--

CREATE TABLE _timescaledb_internal._hyper_1_61_chunk (
    CONSTRAINT constraint_61 CHECK ((("time" >= '2021-02-18 00:00:00+00'::timestamp with time zone) AND ("time" < '2021-02-25 00:00:00+00'::timestamp with time zone)))
)
INHERITS (app_public.readings);


--
-- Name: _hyper_1_62_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: -
--

CREATE TABLE _timescaledb_internal._hyper_1_62_chunk (
    CONSTRAINT constraint_62 CHECK ((("time" >= '2021-02-25 00:00:00+00'::timestamp with time zone) AND ("time" < '2021-03-04 00:00:00+00'::timestamp with time zone)))
)
INHERITS (app_public.readings);


--
-- Name: _hyper_1_63_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: -
--

CREATE TABLE _timescaledb_internal._hyper_1_63_chunk (
    CONSTRAINT constraint_63 CHECK ((("time" >= '2021-03-04 00:00:00+00'::timestamp with time zone) AND ("time" < '2021-03-11 00:00:00+00'::timestamp with time zone)))
)
INHERITS (app_public.readings);


--
-- Name: _hyper_1_64_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: -
--

CREATE TABLE _timescaledb_internal._hyper_1_64_chunk (
    CONSTRAINT constraint_64 CHECK ((("time" >= '2021-03-11 00:00:00+00'::timestamp with time zone) AND ("time" < '2021-03-18 00:00:00+00'::timestamp with time zone)))
)
INHERITS (app_public.readings);


--
-- Name: _hyper_1_65_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: -
--

CREATE TABLE _timescaledb_internal._hyper_1_65_chunk (
    CONSTRAINT constraint_65 CHECK ((("time" >= '2021-03-18 00:00:00+00'::timestamp with time zone) AND ("time" < '2021-03-25 00:00:00+00'::timestamp with time zone)))
)
INHERITS (app_public.readings);


--
-- Name: _hyper_1_66_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: -
--

CREATE TABLE _timescaledb_internal._hyper_1_66_chunk (
    CONSTRAINT constraint_66 CHECK ((("time" >= '2021-03-25 00:00:00+00'::timestamp with time zone) AND ("time" < '2021-04-01 00:00:00+00'::timestamp with time zone)))
)
INHERITS (app_public.readings);


--
-- Name: _hyper_1_67_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: -
--

CREATE TABLE _timescaledb_internal._hyper_1_67_chunk (
    CONSTRAINT constraint_67 CHECK ((("time" >= '2021-04-01 00:00:00+00'::timestamp with time zone) AND ("time" < '2021-04-08 00:00:00+00'::timestamp with time zone)))
)
INHERITS (app_public.readings);


--
-- Name: _hyper_1_68_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: -
--

CREATE TABLE _timescaledb_internal._hyper_1_68_chunk (
    CONSTRAINT constraint_68 CHECK ((("time" >= '2021-04-08 00:00:00+00'::timestamp with time zone) AND ("time" < '2021-04-15 00:00:00+00'::timestamp with time zone)))
)
INHERITS (app_public.readings);


--
-- Name: _hyper_1_69_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: -
--

CREATE TABLE _timescaledb_internal._hyper_1_69_chunk (
    CONSTRAINT constraint_69 CHECK ((("time" >= '2021-04-15 00:00:00+00'::timestamp with time zone) AND ("time" < '2021-04-22 00:00:00+00'::timestamp with time zone)))
)
INHERITS (app_public.readings);


--
-- Name: _hyper_1_6_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: -
--

CREATE TABLE _timescaledb_internal._hyper_1_6_chunk (
    CONSTRAINT constraint_6 CHECK ((("time" >= '2020-01-30 00:00:00+00'::timestamp with time zone) AND ("time" < '2020-02-06 00:00:00+00'::timestamp with time zone)))
)
INHERITS (app_public.readings);


--
-- Name: _hyper_1_70_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: -
--

CREATE TABLE _timescaledb_internal._hyper_1_70_chunk (
    CONSTRAINT constraint_70 CHECK ((("time" >= '2021-04-22 00:00:00+00'::timestamp with time zone) AND ("time" < '2021-04-29 00:00:00+00'::timestamp with time zone)))
)
INHERITS (app_public.readings);


--
-- Name: _hyper_1_71_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: -
--

CREATE TABLE _timescaledb_internal._hyper_1_71_chunk (
    CONSTRAINT constraint_71 CHECK ((("time" >= '2021-04-29 00:00:00+00'::timestamp with time zone) AND ("time" < '2021-05-06 00:00:00+00'::timestamp with time zone)))
)
INHERITS (app_public.readings);


--
-- Name: _hyper_1_72_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: -
--

CREATE TABLE _timescaledb_internal._hyper_1_72_chunk (
    CONSTRAINT constraint_72 CHECK ((("time" >= '2021-05-06 00:00:00+00'::timestamp with time zone) AND ("time" < '2021-05-13 00:00:00+00'::timestamp with time zone)))
)
INHERITS (app_public.readings);


--
-- Name: _hyper_1_73_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: -
--

CREATE TABLE _timescaledb_internal._hyper_1_73_chunk (
    CONSTRAINT constraint_73 CHECK ((("time" >= '2021-05-13 00:00:00+00'::timestamp with time zone) AND ("time" < '2021-05-20 00:00:00+00'::timestamp with time zone)))
)
INHERITS (app_public.readings);


--
-- Name: _hyper_1_7_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: -
--

CREATE TABLE _timescaledb_internal._hyper_1_7_chunk (
    CONSTRAINT constraint_7 CHECK ((("time" >= '2020-02-06 00:00:00+00'::timestamp with time zone) AND ("time" < '2020-02-13 00:00:00+00'::timestamp with time zone)))
)
INHERITS (app_public.readings);


--
-- Name: _hyper_1_8_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: -
--

CREATE TABLE _timescaledb_internal._hyper_1_8_chunk (
    CONSTRAINT constraint_8 CHECK ((("time" >= '2020-02-13 00:00:00+00'::timestamp with time zone) AND ("time" < '2020-02-20 00:00:00+00'::timestamp with time zone)))
)
INHERITS (app_public.readings);


--
-- Name: _hyper_1_9_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: -
--

CREATE TABLE _timescaledb_internal._hyper_1_9_chunk (
    CONSTRAINT constraint_9 CHECK ((("time" >= '2020-02-20 00:00:00+00'::timestamp with time zone) AND ("time" < '2020-02-27 00:00:00+00'::timestamp with time zone)))
)
INHERITS (app_public.readings);


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
    query character varying NOT NULL,
    description text,
    units text
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
-- Name: COLUMN metric_definitions.description; Type: COMMENT; Schema: app_public; Owner: -
--

COMMENT ON COLUMN app_public.metric_definitions.description IS 'The description of the metric definition.';


--
-- Name: COLUMN metric_definitions.units; Type: COMMENT; Schema: app_public; Owner: -
--

COMMENT ON COLUMN app_public.metric_definitions.units IS 'The facility’s tags.';


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
-- Name: _hyper_1_10_chunk metadata; Type: DEFAULT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_10_chunk ALTER COLUMN metadata SET DEFAULT '{}'::jsonb;


--
-- Name: _hyper_1_11_chunk metadata; Type: DEFAULT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_11_chunk ALTER COLUMN metadata SET DEFAULT '{}'::jsonb;


--
-- Name: _hyper_1_12_chunk metadata; Type: DEFAULT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_12_chunk ALTER COLUMN metadata SET DEFAULT '{}'::jsonb;


--
-- Name: _hyper_1_13_chunk metadata; Type: DEFAULT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_13_chunk ALTER COLUMN metadata SET DEFAULT '{}'::jsonb;


--
-- Name: _hyper_1_14_chunk metadata; Type: DEFAULT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_14_chunk ALTER COLUMN metadata SET DEFAULT '{}'::jsonb;


--
-- Name: _hyper_1_15_chunk metadata; Type: DEFAULT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_15_chunk ALTER COLUMN metadata SET DEFAULT '{}'::jsonb;


--
-- Name: _hyper_1_16_chunk metadata; Type: DEFAULT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_16_chunk ALTER COLUMN metadata SET DEFAULT '{}'::jsonb;


--
-- Name: _hyper_1_17_chunk metadata; Type: DEFAULT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_17_chunk ALTER COLUMN metadata SET DEFAULT '{}'::jsonb;


--
-- Name: _hyper_1_18_chunk metadata; Type: DEFAULT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_18_chunk ALTER COLUMN metadata SET DEFAULT '{}'::jsonb;


--
-- Name: _hyper_1_19_chunk metadata; Type: DEFAULT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_19_chunk ALTER COLUMN metadata SET DEFAULT '{}'::jsonb;


--
-- Name: _hyper_1_1_chunk metadata; Type: DEFAULT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_1_chunk ALTER COLUMN metadata SET DEFAULT '{}'::jsonb;


--
-- Name: _hyper_1_20_chunk metadata; Type: DEFAULT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_20_chunk ALTER COLUMN metadata SET DEFAULT '{}'::jsonb;


--
-- Name: _hyper_1_21_chunk metadata; Type: DEFAULT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_21_chunk ALTER COLUMN metadata SET DEFAULT '{}'::jsonb;


--
-- Name: _hyper_1_22_chunk metadata; Type: DEFAULT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_22_chunk ALTER COLUMN metadata SET DEFAULT '{}'::jsonb;


--
-- Name: _hyper_1_23_chunk metadata; Type: DEFAULT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_23_chunk ALTER COLUMN metadata SET DEFAULT '{}'::jsonb;


--
-- Name: _hyper_1_24_chunk metadata; Type: DEFAULT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_24_chunk ALTER COLUMN metadata SET DEFAULT '{}'::jsonb;


--
-- Name: _hyper_1_25_chunk metadata; Type: DEFAULT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_25_chunk ALTER COLUMN metadata SET DEFAULT '{}'::jsonb;


--
-- Name: _hyper_1_26_chunk metadata; Type: DEFAULT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_26_chunk ALTER COLUMN metadata SET DEFAULT '{}'::jsonb;


--
-- Name: _hyper_1_27_chunk metadata; Type: DEFAULT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_27_chunk ALTER COLUMN metadata SET DEFAULT '{}'::jsonb;


--
-- Name: _hyper_1_28_chunk metadata; Type: DEFAULT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_28_chunk ALTER COLUMN metadata SET DEFAULT '{}'::jsonb;


--
-- Name: _hyper_1_29_chunk metadata; Type: DEFAULT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_29_chunk ALTER COLUMN metadata SET DEFAULT '{}'::jsonb;


--
-- Name: _hyper_1_2_chunk metadata; Type: DEFAULT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_2_chunk ALTER COLUMN metadata SET DEFAULT '{}'::jsonb;


--
-- Name: _hyper_1_30_chunk metadata; Type: DEFAULT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_30_chunk ALTER COLUMN metadata SET DEFAULT '{}'::jsonb;


--
-- Name: _hyper_1_31_chunk metadata; Type: DEFAULT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_31_chunk ALTER COLUMN metadata SET DEFAULT '{}'::jsonb;


--
-- Name: _hyper_1_32_chunk metadata; Type: DEFAULT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_32_chunk ALTER COLUMN metadata SET DEFAULT '{}'::jsonb;


--
-- Name: _hyper_1_33_chunk metadata; Type: DEFAULT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_33_chunk ALTER COLUMN metadata SET DEFAULT '{}'::jsonb;


--
-- Name: _hyper_1_34_chunk metadata; Type: DEFAULT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_34_chunk ALTER COLUMN metadata SET DEFAULT '{}'::jsonb;


--
-- Name: _hyper_1_35_chunk metadata; Type: DEFAULT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_35_chunk ALTER COLUMN metadata SET DEFAULT '{}'::jsonb;


--
-- Name: _hyper_1_36_chunk metadata; Type: DEFAULT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_36_chunk ALTER COLUMN metadata SET DEFAULT '{}'::jsonb;


--
-- Name: _hyper_1_37_chunk metadata; Type: DEFAULT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_37_chunk ALTER COLUMN metadata SET DEFAULT '{}'::jsonb;


--
-- Name: _hyper_1_38_chunk metadata; Type: DEFAULT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_38_chunk ALTER COLUMN metadata SET DEFAULT '{}'::jsonb;


--
-- Name: _hyper_1_39_chunk metadata; Type: DEFAULT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_39_chunk ALTER COLUMN metadata SET DEFAULT '{}'::jsonb;


--
-- Name: _hyper_1_3_chunk metadata; Type: DEFAULT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_3_chunk ALTER COLUMN metadata SET DEFAULT '{}'::jsonb;


--
-- Name: _hyper_1_40_chunk metadata; Type: DEFAULT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_40_chunk ALTER COLUMN metadata SET DEFAULT '{}'::jsonb;


--
-- Name: _hyper_1_41_chunk metadata; Type: DEFAULT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_41_chunk ALTER COLUMN metadata SET DEFAULT '{}'::jsonb;


--
-- Name: _hyper_1_42_chunk metadata; Type: DEFAULT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_42_chunk ALTER COLUMN metadata SET DEFAULT '{}'::jsonb;


--
-- Name: _hyper_1_43_chunk metadata; Type: DEFAULT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_43_chunk ALTER COLUMN metadata SET DEFAULT '{}'::jsonb;


--
-- Name: _hyper_1_44_chunk metadata; Type: DEFAULT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_44_chunk ALTER COLUMN metadata SET DEFAULT '{}'::jsonb;


--
-- Name: _hyper_1_45_chunk metadata; Type: DEFAULT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_45_chunk ALTER COLUMN metadata SET DEFAULT '{}'::jsonb;


--
-- Name: _hyper_1_46_chunk metadata; Type: DEFAULT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_46_chunk ALTER COLUMN metadata SET DEFAULT '{}'::jsonb;


--
-- Name: _hyper_1_47_chunk metadata; Type: DEFAULT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_47_chunk ALTER COLUMN metadata SET DEFAULT '{}'::jsonb;


--
-- Name: _hyper_1_48_chunk metadata; Type: DEFAULT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_48_chunk ALTER COLUMN metadata SET DEFAULT '{}'::jsonb;


--
-- Name: _hyper_1_49_chunk metadata; Type: DEFAULT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_49_chunk ALTER COLUMN metadata SET DEFAULT '{}'::jsonb;


--
-- Name: _hyper_1_4_chunk metadata; Type: DEFAULT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_4_chunk ALTER COLUMN metadata SET DEFAULT '{}'::jsonb;


--
-- Name: _hyper_1_50_chunk metadata; Type: DEFAULT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_50_chunk ALTER COLUMN metadata SET DEFAULT '{}'::jsonb;


--
-- Name: _hyper_1_51_chunk metadata; Type: DEFAULT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_51_chunk ALTER COLUMN metadata SET DEFAULT '{}'::jsonb;


--
-- Name: _hyper_1_52_chunk metadata; Type: DEFAULT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_52_chunk ALTER COLUMN metadata SET DEFAULT '{}'::jsonb;


--
-- Name: _hyper_1_53_chunk metadata; Type: DEFAULT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_53_chunk ALTER COLUMN metadata SET DEFAULT '{}'::jsonb;


--
-- Name: _hyper_1_54_chunk metadata; Type: DEFAULT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_54_chunk ALTER COLUMN metadata SET DEFAULT '{}'::jsonb;


--
-- Name: _hyper_1_55_chunk metadata; Type: DEFAULT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_55_chunk ALTER COLUMN metadata SET DEFAULT '{}'::jsonb;


--
-- Name: _hyper_1_56_chunk metadata; Type: DEFAULT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_56_chunk ALTER COLUMN metadata SET DEFAULT '{}'::jsonb;


--
-- Name: _hyper_1_57_chunk metadata; Type: DEFAULT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_57_chunk ALTER COLUMN metadata SET DEFAULT '{}'::jsonb;


--
-- Name: _hyper_1_58_chunk metadata; Type: DEFAULT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_58_chunk ALTER COLUMN metadata SET DEFAULT '{}'::jsonb;


--
-- Name: _hyper_1_59_chunk metadata; Type: DEFAULT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_59_chunk ALTER COLUMN metadata SET DEFAULT '{}'::jsonb;


--
-- Name: _hyper_1_5_chunk metadata; Type: DEFAULT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_5_chunk ALTER COLUMN metadata SET DEFAULT '{}'::jsonb;


--
-- Name: _hyper_1_60_chunk metadata; Type: DEFAULT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_60_chunk ALTER COLUMN metadata SET DEFAULT '{}'::jsonb;


--
-- Name: _hyper_1_61_chunk metadata; Type: DEFAULT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_61_chunk ALTER COLUMN metadata SET DEFAULT '{}'::jsonb;


--
-- Name: _hyper_1_62_chunk metadata; Type: DEFAULT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_62_chunk ALTER COLUMN metadata SET DEFAULT '{}'::jsonb;


--
-- Name: _hyper_1_63_chunk metadata; Type: DEFAULT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_63_chunk ALTER COLUMN metadata SET DEFAULT '{}'::jsonb;


--
-- Name: _hyper_1_64_chunk metadata; Type: DEFAULT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_64_chunk ALTER COLUMN metadata SET DEFAULT '{}'::jsonb;


--
-- Name: _hyper_1_65_chunk metadata; Type: DEFAULT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_65_chunk ALTER COLUMN metadata SET DEFAULT '{}'::jsonb;


--
-- Name: _hyper_1_66_chunk metadata; Type: DEFAULT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_66_chunk ALTER COLUMN metadata SET DEFAULT '{}'::jsonb;


--
-- Name: _hyper_1_67_chunk metadata; Type: DEFAULT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_67_chunk ALTER COLUMN metadata SET DEFAULT '{}'::jsonb;


--
-- Name: _hyper_1_68_chunk metadata; Type: DEFAULT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_68_chunk ALTER COLUMN metadata SET DEFAULT '{}'::jsonb;


--
-- Name: _hyper_1_69_chunk metadata; Type: DEFAULT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_69_chunk ALTER COLUMN metadata SET DEFAULT '{}'::jsonb;


--
-- Name: _hyper_1_6_chunk metadata; Type: DEFAULT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_6_chunk ALTER COLUMN metadata SET DEFAULT '{}'::jsonb;


--
-- Name: _hyper_1_70_chunk metadata; Type: DEFAULT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_70_chunk ALTER COLUMN metadata SET DEFAULT '{}'::jsonb;


--
-- Name: _hyper_1_71_chunk metadata; Type: DEFAULT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_71_chunk ALTER COLUMN metadata SET DEFAULT '{}'::jsonb;


--
-- Name: _hyper_1_72_chunk metadata; Type: DEFAULT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_72_chunk ALTER COLUMN metadata SET DEFAULT '{}'::jsonb;


--
-- Name: _hyper_1_73_chunk metadata; Type: DEFAULT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_73_chunk ALTER COLUMN metadata SET DEFAULT '{}'::jsonb;


--
-- Name: _hyper_1_7_chunk metadata; Type: DEFAULT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_7_chunk ALTER COLUMN metadata SET DEFAULT '{}'::jsonb;


--
-- Name: _hyper_1_8_chunk metadata; Type: DEFAULT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_8_chunk ALTER COLUMN metadata SET DEFAULT '{}'::jsonb;


--
-- Name: _hyper_1_9_chunk metadata; Type: DEFAULT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_9_chunk ALTER COLUMN metadata SET DEFAULT '{}'::jsonb;


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
-- Name: _hyper_1_10_chunk_readings_data_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_10_chunk_readings_data_idx ON _timescaledb_internal._hyper_1_10_chunk USING gin (data);


--
-- Name: _hyper_1_10_chunk_readings_device_label_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE UNIQUE INDEX _hyper_1_10_chunk_readings_device_label_time_idx ON _timescaledb_internal._hyper_1_10_chunk USING btree (device_id, label, "time" DESC);


--
-- Name: _hyper_1_10_chunk_readings_device_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_10_chunk_readings_device_time_idx ON _timescaledb_internal._hyper_1_10_chunk USING btree (device_id, "time" DESC);


--
-- Name: _hyper_1_10_chunk_readings_metadata_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_10_chunk_readings_metadata_idx ON _timescaledb_internal._hyper_1_10_chunk USING gin (metadata);


--
-- Name: _hyper_1_10_chunk_readings_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_10_chunk_readings_time_idx ON _timescaledb_internal._hyper_1_10_chunk USING btree ("time" DESC);


--
-- Name: _hyper_1_11_chunk_readings_data_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_11_chunk_readings_data_idx ON _timescaledb_internal._hyper_1_11_chunk USING gin (data);


--
-- Name: _hyper_1_11_chunk_readings_device_label_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE UNIQUE INDEX _hyper_1_11_chunk_readings_device_label_time_idx ON _timescaledb_internal._hyper_1_11_chunk USING btree (device_id, label, "time" DESC);


--
-- Name: _hyper_1_11_chunk_readings_device_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_11_chunk_readings_device_time_idx ON _timescaledb_internal._hyper_1_11_chunk USING btree (device_id, "time" DESC);


--
-- Name: _hyper_1_11_chunk_readings_metadata_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_11_chunk_readings_metadata_idx ON _timescaledb_internal._hyper_1_11_chunk USING gin (metadata);


--
-- Name: _hyper_1_11_chunk_readings_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_11_chunk_readings_time_idx ON _timescaledb_internal._hyper_1_11_chunk USING btree ("time" DESC);


--
-- Name: _hyper_1_12_chunk_readings_data_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_12_chunk_readings_data_idx ON _timescaledb_internal._hyper_1_12_chunk USING gin (data);


--
-- Name: _hyper_1_12_chunk_readings_device_label_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE UNIQUE INDEX _hyper_1_12_chunk_readings_device_label_time_idx ON _timescaledb_internal._hyper_1_12_chunk USING btree (device_id, label, "time" DESC);


--
-- Name: _hyper_1_12_chunk_readings_device_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_12_chunk_readings_device_time_idx ON _timescaledb_internal._hyper_1_12_chunk USING btree (device_id, "time" DESC);


--
-- Name: _hyper_1_12_chunk_readings_metadata_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_12_chunk_readings_metadata_idx ON _timescaledb_internal._hyper_1_12_chunk USING gin (metadata);


--
-- Name: _hyper_1_12_chunk_readings_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_12_chunk_readings_time_idx ON _timescaledb_internal._hyper_1_12_chunk USING btree ("time" DESC);


--
-- Name: _hyper_1_13_chunk_readings_data_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_13_chunk_readings_data_idx ON _timescaledb_internal._hyper_1_13_chunk USING gin (data);


--
-- Name: _hyper_1_13_chunk_readings_device_label_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE UNIQUE INDEX _hyper_1_13_chunk_readings_device_label_time_idx ON _timescaledb_internal._hyper_1_13_chunk USING btree (device_id, label, "time" DESC);


--
-- Name: _hyper_1_13_chunk_readings_device_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_13_chunk_readings_device_time_idx ON _timescaledb_internal._hyper_1_13_chunk USING btree (device_id, "time" DESC);


--
-- Name: _hyper_1_13_chunk_readings_metadata_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_13_chunk_readings_metadata_idx ON _timescaledb_internal._hyper_1_13_chunk USING gin (metadata);


--
-- Name: _hyper_1_13_chunk_readings_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_13_chunk_readings_time_idx ON _timescaledb_internal._hyper_1_13_chunk USING btree ("time" DESC);


--
-- Name: _hyper_1_14_chunk_readings_data_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_14_chunk_readings_data_idx ON _timescaledb_internal._hyper_1_14_chunk USING gin (data);


--
-- Name: _hyper_1_14_chunk_readings_device_label_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE UNIQUE INDEX _hyper_1_14_chunk_readings_device_label_time_idx ON _timescaledb_internal._hyper_1_14_chunk USING btree (device_id, label, "time" DESC);


--
-- Name: _hyper_1_14_chunk_readings_device_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_14_chunk_readings_device_time_idx ON _timescaledb_internal._hyper_1_14_chunk USING btree (device_id, "time" DESC);


--
-- Name: _hyper_1_14_chunk_readings_metadata_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_14_chunk_readings_metadata_idx ON _timescaledb_internal._hyper_1_14_chunk USING gin (metadata);


--
-- Name: _hyper_1_14_chunk_readings_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_14_chunk_readings_time_idx ON _timescaledb_internal._hyper_1_14_chunk USING btree ("time" DESC);


--
-- Name: _hyper_1_15_chunk_readings_data_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_15_chunk_readings_data_idx ON _timescaledb_internal._hyper_1_15_chunk USING gin (data);


--
-- Name: _hyper_1_15_chunk_readings_device_label_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE UNIQUE INDEX _hyper_1_15_chunk_readings_device_label_time_idx ON _timescaledb_internal._hyper_1_15_chunk USING btree (device_id, label, "time" DESC);


--
-- Name: _hyper_1_15_chunk_readings_device_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_15_chunk_readings_device_time_idx ON _timescaledb_internal._hyper_1_15_chunk USING btree (device_id, "time" DESC);


--
-- Name: _hyper_1_15_chunk_readings_metadata_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_15_chunk_readings_metadata_idx ON _timescaledb_internal._hyper_1_15_chunk USING gin (metadata);


--
-- Name: _hyper_1_15_chunk_readings_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_15_chunk_readings_time_idx ON _timescaledb_internal._hyper_1_15_chunk USING btree ("time" DESC);


--
-- Name: _hyper_1_16_chunk_readings_data_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_16_chunk_readings_data_idx ON _timescaledb_internal._hyper_1_16_chunk USING gin (data);


--
-- Name: _hyper_1_16_chunk_readings_device_label_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE UNIQUE INDEX _hyper_1_16_chunk_readings_device_label_time_idx ON _timescaledb_internal._hyper_1_16_chunk USING btree (device_id, label, "time" DESC);


--
-- Name: _hyper_1_16_chunk_readings_device_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_16_chunk_readings_device_time_idx ON _timescaledb_internal._hyper_1_16_chunk USING btree (device_id, "time" DESC);


--
-- Name: _hyper_1_16_chunk_readings_metadata_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_16_chunk_readings_metadata_idx ON _timescaledb_internal._hyper_1_16_chunk USING gin (metadata);


--
-- Name: _hyper_1_16_chunk_readings_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_16_chunk_readings_time_idx ON _timescaledb_internal._hyper_1_16_chunk USING btree ("time" DESC);


--
-- Name: _hyper_1_17_chunk_readings_data_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_17_chunk_readings_data_idx ON _timescaledb_internal._hyper_1_17_chunk USING gin (data);


--
-- Name: _hyper_1_17_chunk_readings_device_label_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE UNIQUE INDEX _hyper_1_17_chunk_readings_device_label_time_idx ON _timescaledb_internal._hyper_1_17_chunk USING btree (device_id, label, "time" DESC);


--
-- Name: _hyper_1_17_chunk_readings_device_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_17_chunk_readings_device_time_idx ON _timescaledb_internal._hyper_1_17_chunk USING btree (device_id, "time" DESC);


--
-- Name: _hyper_1_17_chunk_readings_metadata_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_17_chunk_readings_metadata_idx ON _timescaledb_internal._hyper_1_17_chunk USING gin (metadata);


--
-- Name: _hyper_1_17_chunk_readings_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_17_chunk_readings_time_idx ON _timescaledb_internal._hyper_1_17_chunk USING btree ("time" DESC);


--
-- Name: _hyper_1_18_chunk_readings_data_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_18_chunk_readings_data_idx ON _timescaledb_internal._hyper_1_18_chunk USING gin (data);


--
-- Name: _hyper_1_18_chunk_readings_device_label_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE UNIQUE INDEX _hyper_1_18_chunk_readings_device_label_time_idx ON _timescaledb_internal._hyper_1_18_chunk USING btree (device_id, label, "time" DESC);


--
-- Name: _hyper_1_18_chunk_readings_device_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_18_chunk_readings_device_time_idx ON _timescaledb_internal._hyper_1_18_chunk USING btree (device_id, "time" DESC);


--
-- Name: _hyper_1_18_chunk_readings_metadata_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_18_chunk_readings_metadata_idx ON _timescaledb_internal._hyper_1_18_chunk USING gin (metadata);


--
-- Name: _hyper_1_18_chunk_readings_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_18_chunk_readings_time_idx ON _timescaledb_internal._hyper_1_18_chunk USING btree ("time" DESC);


--
-- Name: _hyper_1_19_chunk_readings_data_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_19_chunk_readings_data_idx ON _timescaledb_internal._hyper_1_19_chunk USING gin (data);


--
-- Name: _hyper_1_19_chunk_readings_device_label_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE UNIQUE INDEX _hyper_1_19_chunk_readings_device_label_time_idx ON _timescaledb_internal._hyper_1_19_chunk USING btree (device_id, label, "time" DESC);


--
-- Name: _hyper_1_19_chunk_readings_device_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_19_chunk_readings_device_time_idx ON _timescaledb_internal._hyper_1_19_chunk USING btree (device_id, "time" DESC);


--
-- Name: _hyper_1_19_chunk_readings_metadata_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_19_chunk_readings_metadata_idx ON _timescaledb_internal._hyper_1_19_chunk USING gin (metadata);


--
-- Name: _hyper_1_19_chunk_readings_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_19_chunk_readings_time_idx ON _timescaledb_internal._hyper_1_19_chunk USING btree ("time" DESC);


--
-- Name: _hyper_1_1_chunk_readings_data_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_1_chunk_readings_data_idx ON _timescaledb_internal._hyper_1_1_chunk USING gin (data);


--
-- Name: _hyper_1_1_chunk_readings_device_label_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE UNIQUE INDEX _hyper_1_1_chunk_readings_device_label_time_idx ON _timescaledb_internal._hyper_1_1_chunk USING btree (device_id, label, "time" DESC);


--
-- Name: _hyper_1_1_chunk_readings_device_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_1_chunk_readings_device_time_idx ON _timescaledb_internal._hyper_1_1_chunk USING btree (device_id, "time" DESC);


--
-- Name: _hyper_1_1_chunk_readings_metadata_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_1_chunk_readings_metadata_idx ON _timescaledb_internal._hyper_1_1_chunk USING gin (metadata);


--
-- Name: _hyper_1_1_chunk_readings_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_1_chunk_readings_time_idx ON _timescaledb_internal._hyper_1_1_chunk USING btree ("time" DESC);


--
-- Name: _hyper_1_20_chunk_readings_data_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_20_chunk_readings_data_idx ON _timescaledb_internal._hyper_1_20_chunk USING gin (data);


--
-- Name: _hyper_1_20_chunk_readings_device_label_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE UNIQUE INDEX _hyper_1_20_chunk_readings_device_label_time_idx ON _timescaledb_internal._hyper_1_20_chunk USING btree (device_id, label, "time" DESC);


--
-- Name: _hyper_1_20_chunk_readings_device_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_20_chunk_readings_device_time_idx ON _timescaledb_internal._hyper_1_20_chunk USING btree (device_id, "time" DESC);


--
-- Name: _hyper_1_20_chunk_readings_metadata_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_20_chunk_readings_metadata_idx ON _timescaledb_internal._hyper_1_20_chunk USING gin (metadata);


--
-- Name: _hyper_1_20_chunk_readings_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_20_chunk_readings_time_idx ON _timescaledb_internal._hyper_1_20_chunk USING btree ("time" DESC);


--
-- Name: _hyper_1_21_chunk_readings_data_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_21_chunk_readings_data_idx ON _timescaledb_internal._hyper_1_21_chunk USING gin (data);


--
-- Name: _hyper_1_21_chunk_readings_device_label_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE UNIQUE INDEX _hyper_1_21_chunk_readings_device_label_time_idx ON _timescaledb_internal._hyper_1_21_chunk USING btree (device_id, label, "time" DESC);


--
-- Name: _hyper_1_21_chunk_readings_device_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_21_chunk_readings_device_time_idx ON _timescaledb_internal._hyper_1_21_chunk USING btree (device_id, "time" DESC);


--
-- Name: _hyper_1_21_chunk_readings_metadata_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_21_chunk_readings_metadata_idx ON _timescaledb_internal._hyper_1_21_chunk USING gin (metadata);


--
-- Name: _hyper_1_21_chunk_readings_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_21_chunk_readings_time_idx ON _timescaledb_internal._hyper_1_21_chunk USING btree ("time" DESC);


--
-- Name: _hyper_1_22_chunk_readings_data_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_22_chunk_readings_data_idx ON _timescaledb_internal._hyper_1_22_chunk USING gin (data);


--
-- Name: _hyper_1_22_chunk_readings_device_label_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE UNIQUE INDEX _hyper_1_22_chunk_readings_device_label_time_idx ON _timescaledb_internal._hyper_1_22_chunk USING btree (device_id, label, "time" DESC);


--
-- Name: _hyper_1_22_chunk_readings_device_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_22_chunk_readings_device_time_idx ON _timescaledb_internal._hyper_1_22_chunk USING btree (device_id, "time" DESC);


--
-- Name: _hyper_1_22_chunk_readings_metadata_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_22_chunk_readings_metadata_idx ON _timescaledb_internal._hyper_1_22_chunk USING gin (metadata);


--
-- Name: _hyper_1_22_chunk_readings_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_22_chunk_readings_time_idx ON _timescaledb_internal._hyper_1_22_chunk USING btree ("time" DESC);


--
-- Name: _hyper_1_23_chunk_readings_data_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_23_chunk_readings_data_idx ON _timescaledb_internal._hyper_1_23_chunk USING gin (data);


--
-- Name: _hyper_1_23_chunk_readings_device_label_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE UNIQUE INDEX _hyper_1_23_chunk_readings_device_label_time_idx ON _timescaledb_internal._hyper_1_23_chunk USING btree (device_id, label, "time" DESC);


--
-- Name: _hyper_1_23_chunk_readings_device_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_23_chunk_readings_device_time_idx ON _timescaledb_internal._hyper_1_23_chunk USING btree (device_id, "time" DESC);


--
-- Name: _hyper_1_23_chunk_readings_metadata_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_23_chunk_readings_metadata_idx ON _timescaledb_internal._hyper_1_23_chunk USING gin (metadata);


--
-- Name: _hyper_1_23_chunk_readings_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_23_chunk_readings_time_idx ON _timescaledb_internal._hyper_1_23_chunk USING btree ("time" DESC);


--
-- Name: _hyper_1_24_chunk_readings_data_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_24_chunk_readings_data_idx ON _timescaledb_internal._hyper_1_24_chunk USING gin (data);


--
-- Name: _hyper_1_24_chunk_readings_device_label_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE UNIQUE INDEX _hyper_1_24_chunk_readings_device_label_time_idx ON _timescaledb_internal._hyper_1_24_chunk USING btree (device_id, label, "time" DESC);


--
-- Name: _hyper_1_24_chunk_readings_device_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_24_chunk_readings_device_time_idx ON _timescaledb_internal._hyper_1_24_chunk USING btree (device_id, "time" DESC);


--
-- Name: _hyper_1_24_chunk_readings_metadata_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_24_chunk_readings_metadata_idx ON _timescaledb_internal._hyper_1_24_chunk USING gin (metadata);


--
-- Name: _hyper_1_24_chunk_readings_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_24_chunk_readings_time_idx ON _timescaledb_internal._hyper_1_24_chunk USING btree ("time" DESC);


--
-- Name: _hyper_1_25_chunk_readings_data_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_25_chunk_readings_data_idx ON _timescaledb_internal._hyper_1_25_chunk USING gin (data);


--
-- Name: _hyper_1_25_chunk_readings_device_label_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE UNIQUE INDEX _hyper_1_25_chunk_readings_device_label_time_idx ON _timescaledb_internal._hyper_1_25_chunk USING btree (device_id, label, "time" DESC);


--
-- Name: _hyper_1_25_chunk_readings_device_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_25_chunk_readings_device_time_idx ON _timescaledb_internal._hyper_1_25_chunk USING btree (device_id, "time" DESC);


--
-- Name: _hyper_1_25_chunk_readings_metadata_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_25_chunk_readings_metadata_idx ON _timescaledb_internal._hyper_1_25_chunk USING gin (metadata);


--
-- Name: _hyper_1_25_chunk_readings_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_25_chunk_readings_time_idx ON _timescaledb_internal._hyper_1_25_chunk USING btree ("time" DESC);


--
-- Name: _hyper_1_26_chunk_readings_data_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_26_chunk_readings_data_idx ON _timescaledb_internal._hyper_1_26_chunk USING gin (data);


--
-- Name: _hyper_1_26_chunk_readings_device_label_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE UNIQUE INDEX _hyper_1_26_chunk_readings_device_label_time_idx ON _timescaledb_internal._hyper_1_26_chunk USING btree (device_id, label, "time" DESC);


--
-- Name: _hyper_1_26_chunk_readings_device_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_26_chunk_readings_device_time_idx ON _timescaledb_internal._hyper_1_26_chunk USING btree (device_id, "time" DESC);


--
-- Name: _hyper_1_26_chunk_readings_metadata_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_26_chunk_readings_metadata_idx ON _timescaledb_internal._hyper_1_26_chunk USING gin (metadata);


--
-- Name: _hyper_1_26_chunk_readings_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_26_chunk_readings_time_idx ON _timescaledb_internal._hyper_1_26_chunk USING btree ("time" DESC);


--
-- Name: _hyper_1_27_chunk_readings_data_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_27_chunk_readings_data_idx ON _timescaledb_internal._hyper_1_27_chunk USING gin (data);


--
-- Name: _hyper_1_27_chunk_readings_device_label_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE UNIQUE INDEX _hyper_1_27_chunk_readings_device_label_time_idx ON _timescaledb_internal._hyper_1_27_chunk USING btree (device_id, label, "time" DESC);


--
-- Name: _hyper_1_27_chunk_readings_device_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_27_chunk_readings_device_time_idx ON _timescaledb_internal._hyper_1_27_chunk USING btree (device_id, "time" DESC);


--
-- Name: _hyper_1_27_chunk_readings_metadata_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_27_chunk_readings_metadata_idx ON _timescaledb_internal._hyper_1_27_chunk USING gin (metadata);


--
-- Name: _hyper_1_27_chunk_readings_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_27_chunk_readings_time_idx ON _timescaledb_internal._hyper_1_27_chunk USING btree ("time" DESC);


--
-- Name: _hyper_1_28_chunk_readings_data_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_28_chunk_readings_data_idx ON _timescaledb_internal._hyper_1_28_chunk USING gin (data);


--
-- Name: _hyper_1_28_chunk_readings_device_label_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE UNIQUE INDEX _hyper_1_28_chunk_readings_device_label_time_idx ON _timescaledb_internal._hyper_1_28_chunk USING btree (device_id, label, "time" DESC);


--
-- Name: _hyper_1_28_chunk_readings_device_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_28_chunk_readings_device_time_idx ON _timescaledb_internal._hyper_1_28_chunk USING btree (device_id, "time" DESC);


--
-- Name: _hyper_1_28_chunk_readings_metadata_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_28_chunk_readings_metadata_idx ON _timescaledb_internal._hyper_1_28_chunk USING gin (metadata);


--
-- Name: _hyper_1_28_chunk_readings_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_28_chunk_readings_time_idx ON _timescaledb_internal._hyper_1_28_chunk USING btree ("time" DESC);


--
-- Name: _hyper_1_29_chunk_readings_data_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_29_chunk_readings_data_idx ON _timescaledb_internal._hyper_1_29_chunk USING gin (data);


--
-- Name: _hyper_1_29_chunk_readings_device_label_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE UNIQUE INDEX _hyper_1_29_chunk_readings_device_label_time_idx ON _timescaledb_internal._hyper_1_29_chunk USING btree (device_id, label, "time" DESC);


--
-- Name: _hyper_1_29_chunk_readings_device_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_29_chunk_readings_device_time_idx ON _timescaledb_internal._hyper_1_29_chunk USING btree (device_id, "time" DESC);


--
-- Name: _hyper_1_29_chunk_readings_metadata_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_29_chunk_readings_metadata_idx ON _timescaledb_internal._hyper_1_29_chunk USING gin (metadata);


--
-- Name: _hyper_1_29_chunk_readings_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_29_chunk_readings_time_idx ON _timescaledb_internal._hyper_1_29_chunk USING btree ("time" DESC);


--
-- Name: _hyper_1_2_chunk_readings_data_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_2_chunk_readings_data_idx ON _timescaledb_internal._hyper_1_2_chunk USING gin (data);


--
-- Name: _hyper_1_2_chunk_readings_device_label_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE UNIQUE INDEX _hyper_1_2_chunk_readings_device_label_time_idx ON _timescaledb_internal._hyper_1_2_chunk USING btree (device_id, label, "time" DESC);


--
-- Name: _hyper_1_2_chunk_readings_device_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_2_chunk_readings_device_time_idx ON _timescaledb_internal._hyper_1_2_chunk USING btree (device_id, "time" DESC);


--
-- Name: _hyper_1_2_chunk_readings_metadata_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_2_chunk_readings_metadata_idx ON _timescaledb_internal._hyper_1_2_chunk USING gin (metadata);


--
-- Name: _hyper_1_2_chunk_readings_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_2_chunk_readings_time_idx ON _timescaledb_internal._hyper_1_2_chunk USING btree ("time" DESC);


--
-- Name: _hyper_1_30_chunk_readings_data_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_30_chunk_readings_data_idx ON _timescaledb_internal._hyper_1_30_chunk USING gin (data);


--
-- Name: _hyper_1_30_chunk_readings_device_label_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE UNIQUE INDEX _hyper_1_30_chunk_readings_device_label_time_idx ON _timescaledb_internal._hyper_1_30_chunk USING btree (device_id, label, "time" DESC);


--
-- Name: _hyper_1_30_chunk_readings_device_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_30_chunk_readings_device_time_idx ON _timescaledb_internal._hyper_1_30_chunk USING btree (device_id, "time" DESC);


--
-- Name: _hyper_1_30_chunk_readings_metadata_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_30_chunk_readings_metadata_idx ON _timescaledb_internal._hyper_1_30_chunk USING gin (metadata);


--
-- Name: _hyper_1_30_chunk_readings_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_30_chunk_readings_time_idx ON _timescaledb_internal._hyper_1_30_chunk USING btree ("time" DESC);


--
-- Name: _hyper_1_31_chunk_readings_data_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_31_chunk_readings_data_idx ON _timescaledb_internal._hyper_1_31_chunk USING gin (data);


--
-- Name: _hyper_1_31_chunk_readings_device_label_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE UNIQUE INDEX _hyper_1_31_chunk_readings_device_label_time_idx ON _timescaledb_internal._hyper_1_31_chunk USING btree (device_id, label, "time" DESC);


--
-- Name: _hyper_1_31_chunk_readings_device_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_31_chunk_readings_device_time_idx ON _timescaledb_internal._hyper_1_31_chunk USING btree (device_id, "time" DESC);


--
-- Name: _hyper_1_31_chunk_readings_metadata_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_31_chunk_readings_metadata_idx ON _timescaledb_internal._hyper_1_31_chunk USING gin (metadata);


--
-- Name: _hyper_1_31_chunk_readings_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_31_chunk_readings_time_idx ON _timescaledb_internal._hyper_1_31_chunk USING btree ("time" DESC);


--
-- Name: _hyper_1_32_chunk_readings_data_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_32_chunk_readings_data_idx ON _timescaledb_internal._hyper_1_32_chunk USING gin (data);


--
-- Name: _hyper_1_32_chunk_readings_device_label_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE UNIQUE INDEX _hyper_1_32_chunk_readings_device_label_time_idx ON _timescaledb_internal._hyper_1_32_chunk USING btree (device_id, label, "time" DESC);


--
-- Name: _hyper_1_32_chunk_readings_device_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_32_chunk_readings_device_time_idx ON _timescaledb_internal._hyper_1_32_chunk USING btree (device_id, "time" DESC);


--
-- Name: _hyper_1_32_chunk_readings_metadata_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_32_chunk_readings_metadata_idx ON _timescaledb_internal._hyper_1_32_chunk USING gin (metadata);


--
-- Name: _hyper_1_32_chunk_readings_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_32_chunk_readings_time_idx ON _timescaledb_internal._hyper_1_32_chunk USING btree ("time" DESC);


--
-- Name: _hyper_1_33_chunk_readings_data_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_33_chunk_readings_data_idx ON _timescaledb_internal._hyper_1_33_chunk USING gin (data);


--
-- Name: _hyper_1_33_chunk_readings_device_label_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE UNIQUE INDEX _hyper_1_33_chunk_readings_device_label_time_idx ON _timescaledb_internal._hyper_1_33_chunk USING btree (device_id, label, "time" DESC);


--
-- Name: _hyper_1_33_chunk_readings_device_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_33_chunk_readings_device_time_idx ON _timescaledb_internal._hyper_1_33_chunk USING btree (device_id, "time" DESC);


--
-- Name: _hyper_1_33_chunk_readings_metadata_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_33_chunk_readings_metadata_idx ON _timescaledb_internal._hyper_1_33_chunk USING gin (metadata);


--
-- Name: _hyper_1_33_chunk_readings_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_33_chunk_readings_time_idx ON _timescaledb_internal._hyper_1_33_chunk USING btree ("time" DESC);


--
-- Name: _hyper_1_34_chunk_readings_data_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_34_chunk_readings_data_idx ON _timescaledb_internal._hyper_1_34_chunk USING gin (data);


--
-- Name: _hyper_1_34_chunk_readings_device_label_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE UNIQUE INDEX _hyper_1_34_chunk_readings_device_label_time_idx ON _timescaledb_internal._hyper_1_34_chunk USING btree (device_id, label, "time" DESC);


--
-- Name: _hyper_1_34_chunk_readings_device_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_34_chunk_readings_device_time_idx ON _timescaledb_internal._hyper_1_34_chunk USING btree (device_id, "time" DESC);


--
-- Name: _hyper_1_34_chunk_readings_metadata_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_34_chunk_readings_metadata_idx ON _timescaledb_internal._hyper_1_34_chunk USING gin (metadata);


--
-- Name: _hyper_1_34_chunk_readings_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_34_chunk_readings_time_idx ON _timescaledb_internal._hyper_1_34_chunk USING btree ("time" DESC);


--
-- Name: _hyper_1_35_chunk_readings_data_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_35_chunk_readings_data_idx ON _timescaledb_internal._hyper_1_35_chunk USING gin (data);


--
-- Name: _hyper_1_35_chunk_readings_device_label_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE UNIQUE INDEX _hyper_1_35_chunk_readings_device_label_time_idx ON _timescaledb_internal._hyper_1_35_chunk USING btree (device_id, label, "time" DESC);


--
-- Name: _hyper_1_35_chunk_readings_device_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_35_chunk_readings_device_time_idx ON _timescaledb_internal._hyper_1_35_chunk USING btree (device_id, "time" DESC);


--
-- Name: _hyper_1_35_chunk_readings_metadata_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_35_chunk_readings_metadata_idx ON _timescaledb_internal._hyper_1_35_chunk USING gin (metadata);


--
-- Name: _hyper_1_35_chunk_readings_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_35_chunk_readings_time_idx ON _timescaledb_internal._hyper_1_35_chunk USING btree ("time" DESC);


--
-- Name: _hyper_1_36_chunk_readings_data_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_36_chunk_readings_data_idx ON _timescaledb_internal._hyper_1_36_chunk USING gin (data);


--
-- Name: _hyper_1_36_chunk_readings_device_label_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE UNIQUE INDEX _hyper_1_36_chunk_readings_device_label_time_idx ON _timescaledb_internal._hyper_1_36_chunk USING btree (device_id, label, "time" DESC);


--
-- Name: _hyper_1_36_chunk_readings_device_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_36_chunk_readings_device_time_idx ON _timescaledb_internal._hyper_1_36_chunk USING btree (device_id, "time" DESC);


--
-- Name: _hyper_1_36_chunk_readings_metadata_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_36_chunk_readings_metadata_idx ON _timescaledb_internal._hyper_1_36_chunk USING gin (metadata);


--
-- Name: _hyper_1_36_chunk_readings_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_36_chunk_readings_time_idx ON _timescaledb_internal._hyper_1_36_chunk USING btree ("time" DESC);


--
-- Name: _hyper_1_37_chunk_readings_data_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_37_chunk_readings_data_idx ON _timescaledb_internal._hyper_1_37_chunk USING gin (data);


--
-- Name: _hyper_1_37_chunk_readings_device_label_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE UNIQUE INDEX _hyper_1_37_chunk_readings_device_label_time_idx ON _timescaledb_internal._hyper_1_37_chunk USING btree (device_id, label, "time" DESC);


--
-- Name: _hyper_1_37_chunk_readings_device_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_37_chunk_readings_device_time_idx ON _timescaledb_internal._hyper_1_37_chunk USING btree (device_id, "time" DESC);


--
-- Name: _hyper_1_37_chunk_readings_metadata_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_37_chunk_readings_metadata_idx ON _timescaledb_internal._hyper_1_37_chunk USING gin (metadata);


--
-- Name: _hyper_1_37_chunk_readings_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_37_chunk_readings_time_idx ON _timescaledb_internal._hyper_1_37_chunk USING btree ("time" DESC);


--
-- Name: _hyper_1_38_chunk_readings_data_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_38_chunk_readings_data_idx ON _timescaledb_internal._hyper_1_38_chunk USING gin (data);


--
-- Name: _hyper_1_38_chunk_readings_device_label_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE UNIQUE INDEX _hyper_1_38_chunk_readings_device_label_time_idx ON _timescaledb_internal._hyper_1_38_chunk USING btree (device_id, label, "time" DESC);


--
-- Name: _hyper_1_38_chunk_readings_device_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_38_chunk_readings_device_time_idx ON _timescaledb_internal._hyper_1_38_chunk USING btree (device_id, "time" DESC);


--
-- Name: _hyper_1_38_chunk_readings_metadata_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_38_chunk_readings_metadata_idx ON _timescaledb_internal._hyper_1_38_chunk USING gin (metadata);


--
-- Name: _hyper_1_38_chunk_readings_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_38_chunk_readings_time_idx ON _timescaledb_internal._hyper_1_38_chunk USING btree ("time" DESC);


--
-- Name: _hyper_1_39_chunk_readings_data_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_39_chunk_readings_data_idx ON _timescaledb_internal._hyper_1_39_chunk USING gin (data);


--
-- Name: _hyper_1_39_chunk_readings_device_label_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE UNIQUE INDEX _hyper_1_39_chunk_readings_device_label_time_idx ON _timescaledb_internal._hyper_1_39_chunk USING btree (device_id, label, "time" DESC);


--
-- Name: _hyper_1_39_chunk_readings_device_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_39_chunk_readings_device_time_idx ON _timescaledb_internal._hyper_1_39_chunk USING btree (device_id, "time" DESC);


--
-- Name: _hyper_1_39_chunk_readings_metadata_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_39_chunk_readings_metadata_idx ON _timescaledb_internal._hyper_1_39_chunk USING gin (metadata);


--
-- Name: _hyper_1_39_chunk_readings_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_39_chunk_readings_time_idx ON _timescaledb_internal._hyper_1_39_chunk USING btree ("time" DESC);


--
-- Name: _hyper_1_3_chunk_readings_data_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_3_chunk_readings_data_idx ON _timescaledb_internal._hyper_1_3_chunk USING gin (data);


--
-- Name: _hyper_1_3_chunk_readings_device_label_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE UNIQUE INDEX _hyper_1_3_chunk_readings_device_label_time_idx ON _timescaledb_internal._hyper_1_3_chunk USING btree (device_id, label, "time" DESC);


--
-- Name: _hyper_1_3_chunk_readings_device_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_3_chunk_readings_device_time_idx ON _timescaledb_internal._hyper_1_3_chunk USING btree (device_id, "time" DESC);


--
-- Name: _hyper_1_3_chunk_readings_metadata_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_3_chunk_readings_metadata_idx ON _timescaledb_internal._hyper_1_3_chunk USING gin (metadata);


--
-- Name: _hyper_1_3_chunk_readings_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_3_chunk_readings_time_idx ON _timescaledb_internal._hyper_1_3_chunk USING btree ("time" DESC);


--
-- Name: _hyper_1_40_chunk_readings_data_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_40_chunk_readings_data_idx ON _timescaledb_internal._hyper_1_40_chunk USING gin (data);


--
-- Name: _hyper_1_40_chunk_readings_device_label_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE UNIQUE INDEX _hyper_1_40_chunk_readings_device_label_time_idx ON _timescaledb_internal._hyper_1_40_chunk USING btree (device_id, label, "time" DESC);


--
-- Name: _hyper_1_40_chunk_readings_device_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_40_chunk_readings_device_time_idx ON _timescaledb_internal._hyper_1_40_chunk USING btree (device_id, "time" DESC);


--
-- Name: _hyper_1_40_chunk_readings_metadata_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_40_chunk_readings_metadata_idx ON _timescaledb_internal._hyper_1_40_chunk USING gin (metadata);


--
-- Name: _hyper_1_40_chunk_readings_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_40_chunk_readings_time_idx ON _timescaledb_internal._hyper_1_40_chunk USING btree ("time" DESC);


--
-- Name: _hyper_1_41_chunk_readings_data_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_41_chunk_readings_data_idx ON _timescaledb_internal._hyper_1_41_chunk USING gin (data);


--
-- Name: _hyper_1_41_chunk_readings_device_label_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE UNIQUE INDEX _hyper_1_41_chunk_readings_device_label_time_idx ON _timescaledb_internal._hyper_1_41_chunk USING btree (device_id, label, "time" DESC);


--
-- Name: _hyper_1_41_chunk_readings_device_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_41_chunk_readings_device_time_idx ON _timescaledb_internal._hyper_1_41_chunk USING btree (device_id, "time" DESC);


--
-- Name: _hyper_1_41_chunk_readings_metadata_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_41_chunk_readings_metadata_idx ON _timescaledb_internal._hyper_1_41_chunk USING gin (metadata);


--
-- Name: _hyper_1_41_chunk_readings_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_41_chunk_readings_time_idx ON _timescaledb_internal._hyper_1_41_chunk USING btree ("time" DESC);


--
-- Name: _hyper_1_42_chunk_readings_data_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_42_chunk_readings_data_idx ON _timescaledb_internal._hyper_1_42_chunk USING gin (data);


--
-- Name: _hyper_1_42_chunk_readings_device_label_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE UNIQUE INDEX _hyper_1_42_chunk_readings_device_label_time_idx ON _timescaledb_internal._hyper_1_42_chunk USING btree (device_id, label, "time" DESC);


--
-- Name: _hyper_1_42_chunk_readings_device_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_42_chunk_readings_device_time_idx ON _timescaledb_internal._hyper_1_42_chunk USING btree (device_id, "time" DESC);


--
-- Name: _hyper_1_42_chunk_readings_metadata_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_42_chunk_readings_metadata_idx ON _timescaledb_internal._hyper_1_42_chunk USING gin (metadata);


--
-- Name: _hyper_1_42_chunk_readings_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_42_chunk_readings_time_idx ON _timescaledb_internal._hyper_1_42_chunk USING btree ("time" DESC);


--
-- Name: _hyper_1_43_chunk_readings_data_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_43_chunk_readings_data_idx ON _timescaledb_internal._hyper_1_43_chunk USING gin (data);


--
-- Name: _hyper_1_43_chunk_readings_device_label_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE UNIQUE INDEX _hyper_1_43_chunk_readings_device_label_time_idx ON _timescaledb_internal._hyper_1_43_chunk USING btree (device_id, label, "time" DESC);


--
-- Name: _hyper_1_43_chunk_readings_device_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_43_chunk_readings_device_time_idx ON _timescaledb_internal._hyper_1_43_chunk USING btree (device_id, "time" DESC);


--
-- Name: _hyper_1_43_chunk_readings_metadata_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_43_chunk_readings_metadata_idx ON _timescaledb_internal._hyper_1_43_chunk USING gin (metadata);


--
-- Name: _hyper_1_43_chunk_readings_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_43_chunk_readings_time_idx ON _timescaledb_internal._hyper_1_43_chunk USING btree ("time" DESC);


--
-- Name: _hyper_1_44_chunk_readings_data_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_44_chunk_readings_data_idx ON _timescaledb_internal._hyper_1_44_chunk USING gin (data);


--
-- Name: _hyper_1_44_chunk_readings_device_label_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE UNIQUE INDEX _hyper_1_44_chunk_readings_device_label_time_idx ON _timescaledb_internal._hyper_1_44_chunk USING btree (device_id, label, "time" DESC);


--
-- Name: _hyper_1_44_chunk_readings_device_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_44_chunk_readings_device_time_idx ON _timescaledb_internal._hyper_1_44_chunk USING btree (device_id, "time" DESC);


--
-- Name: _hyper_1_44_chunk_readings_metadata_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_44_chunk_readings_metadata_idx ON _timescaledb_internal._hyper_1_44_chunk USING gin (metadata);


--
-- Name: _hyper_1_44_chunk_readings_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_44_chunk_readings_time_idx ON _timescaledb_internal._hyper_1_44_chunk USING btree ("time" DESC);


--
-- Name: _hyper_1_45_chunk_readings_data_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_45_chunk_readings_data_idx ON _timescaledb_internal._hyper_1_45_chunk USING gin (data);


--
-- Name: _hyper_1_45_chunk_readings_device_label_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE UNIQUE INDEX _hyper_1_45_chunk_readings_device_label_time_idx ON _timescaledb_internal._hyper_1_45_chunk USING btree (device_id, label, "time" DESC);


--
-- Name: _hyper_1_45_chunk_readings_device_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_45_chunk_readings_device_time_idx ON _timescaledb_internal._hyper_1_45_chunk USING btree (device_id, "time" DESC);


--
-- Name: _hyper_1_45_chunk_readings_metadata_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_45_chunk_readings_metadata_idx ON _timescaledb_internal._hyper_1_45_chunk USING gin (metadata);


--
-- Name: _hyper_1_45_chunk_readings_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_45_chunk_readings_time_idx ON _timescaledb_internal._hyper_1_45_chunk USING btree ("time" DESC);


--
-- Name: _hyper_1_46_chunk_readings_data_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_46_chunk_readings_data_idx ON _timescaledb_internal._hyper_1_46_chunk USING gin (data);


--
-- Name: _hyper_1_46_chunk_readings_device_label_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE UNIQUE INDEX _hyper_1_46_chunk_readings_device_label_time_idx ON _timescaledb_internal._hyper_1_46_chunk USING btree (device_id, label, "time" DESC);


--
-- Name: _hyper_1_46_chunk_readings_device_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_46_chunk_readings_device_time_idx ON _timescaledb_internal._hyper_1_46_chunk USING btree (device_id, "time" DESC);


--
-- Name: _hyper_1_46_chunk_readings_metadata_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_46_chunk_readings_metadata_idx ON _timescaledb_internal._hyper_1_46_chunk USING gin (metadata);


--
-- Name: _hyper_1_46_chunk_readings_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_46_chunk_readings_time_idx ON _timescaledb_internal._hyper_1_46_chunk USING btree ("time" DESC);


--
-- Name: _hyper_1_47_chunk_readings_data_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_47_chunk_readings_data_idx ON _timescaledb_internal._hyper_1_47_chunk USING gin (data);


--
-- Name: _hyper_1_47_chunk_readings_device_label_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE UNIQUE INDEX _hyper_1_47_chunk_readings_device_label_time_idx ON _timescaledb_internal._hyper_1_47_chunk USING btree (device_id, label, "time" DESC);


--
-- Name: _hyper_1_47_chunk_readings_device_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_47_chunk_readings_device_time_idx ON _timescaledb_internal._hyper_1_47_chunk USING btree (device_id, "time" DESC);


--
-- Name: _hyper_1_47_chunk_readings_metadata_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_47_chunk_readings_metadata_idx ON _timescaledb_internal._hyper_1_47_chunk USING gin (metadata);


--
-- Name: _hyper_1_47_chunk_readings_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_47_chunk_readings_time_idx ON _timescaledb_internal._hyper_1_47_chunk USING btree ("time" DESC);


--
-- Name: _hyper_1_48_chunk_readings_data_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_48_chunk_readings_data_idx ON _timescaledb_internal._hyper_1_48_chunk USING gin (data);


--
-- Name: _hyper_1_48_chunk_readings_device_label_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE UNIQUE INDEX _hyper_1_48_chunk_readings_device_label_time_idx ON _timescaledb_internal._hyper_1_48_chunk USING btree (device_id, label, "time" DESC);


--
-- Name: _hyper_1_48_chunk_readings_device_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_48_chunk_readings_device_time_idx ON _timescaledb_internal._hyper_1_48_chunk USING btree (device_id, "time" DESC);


--
-- Name: _hyper_1_48_chunk_readings_metadata_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_48_chunk_readings_metadata_idx ON _timescaledb_internal._hyper_1_48_chunk USING gin (metadata);


--
-- Name: _hyper_1_48_chunk_readings_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_48_chunk_readings_time_idx ON _timescaledb_internal._hyper_1_48_chunk USING btree ("time" DESC);


--
-- Name: _hyper_1_49_chunk_readings_data_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_49_chunk_readings_data_idx ON _timescaledb_internal._hyper_1_49_chunk USING gin (data);


--
-- Name: _hyper_1_49_chunk_readings_device_label_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE UNIQUE INDEX _hyper_1_49_chunk_readings_device_label_time_idx ON _timescaledb_internal._hyper_1_49_chunk USING btree (device_id, label, "time" DESC);


--
-- Name: _hyper_1_49_chunk_readings_device_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_49_chunk_readings_device_time_idx ON _timescaledb_internal._hyper_1_49_chunk USING btree (device_id, "time" DESC);


--
-- Name: _hyper_1_49_chunk_readings_metadata_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_49_chunk_readings_metadata_idx ON _timescaledb_internal._hyper_1_49_chunk USING gin (metadata);


--
-- Name: _hyper_1_49_chunk_readings_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_49_chunk_readings_time_idx ON _timescaledb_internal._hyper_1_49_chunk USING btree ("time" DESC);


--
-- Name: _hyper_1_4_chunk_readings_data_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_4_chunk_readings_data_idx ON _timescaledb_internal._hyper_1_4_chunk USING gin (data);


--
-- Name: _hyper_1_4_chunk_readings_device_label_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE UNIQUE INDEX _hyper_1_4_chunk_readings_device_label_time_idx ON _timescaledb_internal._hyper_1_4_chunk USING btree (device_id, label, "time" DESC);


--
-- Name: _hyper_1_4_chunk_readings_device_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_4_chunk_readings_device_time_idx ON _timescaledb_internal._hyper_1_4_chunk USING btree (device_id, "time" DESC);


--
-- Name: _hyper_1_4_chunk_readings_metadata_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_4_chunk_readings_metadata_idx ON _timescaledb_internal._hyper_1_4_chunk USING gin (metadata);


--
-- Name: _hyper_1_4_chunk_readings_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_4_chunk_readings_time_idx ON _timescaledb_internal._hyper_1_4_chunk USING btree ("time" DESC);


--
-- Name: _hyper_1_50_chunk_readings_data_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_50_chunk_readings_data_idx ON _timescaledb_internal._hyper_1_50_chunk USING gin (data);


--
-- Name: _hyper_1_50_chunk_readings_device_label_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE UNIQUE INDEX _hyper_1_50_chunk_readings_device_label_time_idx ON _timescaledb_internal._hyper_1_50_chunk USING btree (device_id, label, "time" DESC);


--
-- Name: _hyper_1_50_chunk_readings_device_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_50_chunk_readings_device_time_idx ON _timescaledb_internal._hyper_1_50_chunk USING btree (device_id, "time" DESC);


--
-- Name: _hyper_1_50_chunk_readings_metadata_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_50_chunk_readings_metadata_idx ON _timescaledb_internal._hyper_1_50_chunk USING gin (metadata);


--
-- Name: _hyper_1_50_chunk_readings_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_50_chunk_readings_time_idx ON _timescaledb_internal._hyper_1_50_chunk USING btree ("time" DESC);


--
-- Name: _hyper_1_51_chunk_readings_data_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_51_chunk_readings_data_idx ON _timescaledb_internal._hyper_1_51_chunk USING gin (data);


--
-- Name: _hyper_1_51_chunk_readings_device_label_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE UNIQUE INDEX _hyper_1_51_chunk_readings_device_label_time_idx ON _timescaledb_internal._hyper_1_51_chunk USING btree (device_id, label, "time" DESC);


--
-- Name: _hyper_1_51_chunk_readings_device_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_51_chunk_readings_device_time_idx ON _timescaledb_internal._hyper_1_51_chunk USING btree (device_id, "time" DESC);


--
-- Name: _hyper_1_51_chunk_readings_metadata_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_51_chunk_readings_metadata_idx ON _timescaledb_internal._hyper_1_51_chunk USING gin (metadata);


--
-- Name: _hyper_1_51_chunk_readings_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_51_chunk_readings_time_idx ON _timescaledb_internal._hyper_1_51_chunk USING btree ("time" DESC);


--
-- Name: _hyper_1_52_chunk_readings_data_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_52_chunk_readings_data_idx ON _timescaledb_internal._hyper_1_52_chunk USING gin (data);


--
-- Name: _hyper_1_52_chunk_readings_device_label_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE UNIQUE INDEX _hyper_1_52_chunk_readings_device_label_time_idx ON _timescaledb_internal._hyper_1_52_chunk USING btree (device_id, label, "time" DESC);


--
-- Name: _hyper_1_52_chunk_readings_device_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_52_chunk_readings_device_time_idx ON _timescaledb_internal._hyper_1_52_chunk USING btree (device_id, "time" DESC);


--
-- Name: _hyper_1_52_chunk_readings_metadata_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_52_chunk_readings_metadata_idx ON _timescaledb_internal._hyper_1_52_chunk USING gin (metadata);


--
-- Name: _hyper_1_52_chunk_readings_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_52_chunk_readings_time_idx ON _timescaledb_internal._hyper_1_52_chunk USING btree ("time" DESC);


--
-- Name: _hyper_1_53_chunk_readings_data_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_53_chunk_readings_data_idx ON _timescaledb_internal._hyper_1_53_chunk USING gin (data);


--
-- Name: _hyper_1_53_chunk_readings_device_label_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE UNIQUE INDEX _hyper_1_53_chunk_readings_device_label_time_idx ON _timescaledb_internal._hyper_1_53_chunk USING btree (device_id, label, "time" DESC);


--
-- Name: _hyper_1_53_chunk_readings_device_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_53_chunk_readings_device_time_idx ON _timescaledb_internal._hyper_1_53_chunk USING btree (device_id, "time" DESC);


--
-- Name: _hyper_1_53_chunk_readings_metadata_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_53_chunk_readings_metadata_idx ON _timescaledb_internal._hyper_1_53_chunk USING gin (metadata);


--
-- Name: _hyper_1_53_chunk_readings_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_53_chunk_readings_time_idx ON _timescaledb_internal._hyper_1_53_chunk USING btree ("time" DESC);


--
-- Name: _hyper_1_54_chunk_readings_data_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_54_chunk_readings_data_idx ON _timescaledb_internal._hyper_1_54_chunk USING gin (data);


--
-- Name: _hyper_1_54_chunk_readings_device_label_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE UNIQUE INDEX _hyper_1_54_chunk_readings_device_label_time_idx ON _timescaledb_internal._hyper_1_54_chunk USING btree (device_id, label, "time" DESC);


--
-- Name: _hyper_1_54_chunk_readings_device_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_54_chunk_readings_device_time_idx ON _timescaledb_internal._hyper_1_54_chunk USING btree (device_id, "time" DESC);


--
-- Name: _hyper_1_54_chunk_readings_metadata_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_54_chunk_readings_metadata_idx ON _timescaledb_internal._hyper_1_54_chunk USING gin (metadata);


--
-- Name: _hyper_1_54_chunk_readings_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_54_chunk_readings_time_idx ON _timescaledb_internal._hyper_1_54_chunk USING btree ("time" DESC);


--
-- Name: _hyper_1_55_chunk_readings_data_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_55_chunk_readings_data_idx ON _timescaledb_internal._hyper_1_55_chunk USING gin (data);


--
-- Name: _hyper_1_55_chunk_readings_device_label_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE UNIQUE INDEX _hyper_1_55_chunk_readings_device_label_time_idx ON _timescaledb_internal._hyper_1_55_chunk USING btree (device_id, label, "time" DESC);


--
-- Name: _hyper_1_55_chunk_readings_device_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_55_chunk_readings_device_time_idx ON _timescaledb_internal._hyper_1_55_chunk USING btree (device_id, "time" DESC);


--
-- Name: _hyper_1_55_chunk_readings_metadata_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_55_chunk_readings_metadata_idx ON _timescaledb_internal._hyper_1_55_chunk USING gin (metadata);


--
-- Name: _hyper_1_55_chunk_readings_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_55_chunk_readings_time_idx ON _timescaledb_internal._hyper_1_55_chunk USING btree ("time" DESC);


--
-- Name: _hyper_1_56_chunk_readings_data_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_56_chunk_readings_data_idx ON _timescaledb_internal._hyper_1_56_chunk USING gin (data);


--
-- Name: _hyper_1_56_chunk_readings_device_label_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE UNIQUE INDEX _hyper_1_56_chunk_readings_device_label_time_idx ON _timescaledb_internal._hyper_1_56_chunk USING btree (device_id, label, "time" DESC);


--
-- Name: _hyper_1_56_chunk_readings_device_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_56_chunk_readings_device_time_idx ON _timescaledb_internal._hyper_1_56_chunk USING btree (device_id, "time" DESC);


--
-- Name: _hyper_1_56_chunk_readings_metadata_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_56_chunk_readings_metadata_idx ON _timescaledb_internal._hyper_1_56_chunk USING gin (metadata);


--
-- Name: _hyper_1_56_chunk_readings_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_56_chunk_readings_time_idx ON _timescaledb_internal._hyper_1_56_chunk USING btree ("time" DESC);


--
-- Name: _hyper_1_57_chunk_readings_data_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_57_chunk_readings_data_idx ON _timescaledb_internal._hyper_1_57_chunk USING gin (data);


--
-- Name: _hyper_1_57_chunk_readings_device_label_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE UNIQUE INDEX _hyper_1_57_chunk_readings_device_label_time_idx ON _timescaledb_internal._hyper_1_57_chunk USING btree (device_id, label, "time" DESC);


--
-- Name: _hyper_1_57_chunk_readings_device_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_57_chunk_readings_device_time_idx ON _timescaledb_internal._hyper_1_57_chunk USING btree (device_id, "time" DESC);


--
-- Name: _hyper_1_57_chunk_readings_metadata_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_57_chunk_readings_metadata_idx ON _timescaledb_internal._hyper_1_57_chunk USING gin (metadata);


--
-- Name: _hyper_1_57_chunk_readings_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_57_chunk_readings_time_idx ON _timescaledb_internal._hyper_1_57_chunk USING btree ("time" DESC);


--
-- Name: _hyper_1_58_chunk_readings_data_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_58_chunk_readings_data_idx ON _timescaledb_internal._hyper_1_58_chunk USING gin (data);


--
-- Name: _hyper_1_58_chunk_readings_device_label_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE UNIQUE INDEX _hyper_1_58_chunk_readings_device_label_time_idx ON _timescaledb_internal._hyper_1_58_chunk USING btree (device_id, label, "time" DESC);


--
-- Name: _hyper_1_58_chunk_readings_device_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_58_chunk_readings_device_time_idx ON _timescaledb_internal._hyper_1_58_chunk USING btree (device_id, "time" DESC);


--
-- Name: _hyper_1_58_chunk_readings_metadata_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_58_chunk_readings_metadata_idx ON _timescaledb_internal._hyper_1_58_chunk USING gin (metadata);


--
-- Name: _hyper_1_58_chunk_readings_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_58_chunk_readings_time_idx ON _timescaledb_internal._hyper_1_58_chunk USING btree ("time" DESC);


--
-- Name: _hyper_1_59_chunk_readings_data_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_59_chunk_readings_data_idx ON _timescaledb_internal._hyper_1_59_chunk USING gin (data);


--
-- Name: _hyper_1_59_chunk_readings_device_label_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE UNIQUE INDEX _hyper_1_59_chunk_readings_device_label_time_idx ON _timescaledb_internal._hyper_1_59_chunk USING btree (device_id, label, "time" DESC);


--
-- Name: _hyper_1_59_chunk_readings_device_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_59_chunk_readings_device_time_idx ON _timescaledb_internal._hyper_1_59_chunk USING btree (device_id, "time" DESC);


--
-- Name: _hyper_1_59_chunk_readings_metadata_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_59_chunk_readings_metadata_idx ON _timescaledb_internal._hyper_1_59_chunk USING gin (metadata);


--
-- Name: _hyper_1_59_chunk_readings_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_59_chunk_readings_time_idx ON _timescaledb_internal._hyper_1_59_chunk USING btree ("time" DESC);


--
-- Name: _hyper_1_5_chunk_readings_data_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_5_chunk_readings_data_idx ON _timescaledb_internal._hyper_1_5_chunk USING gin (data);


--
-- Name: _hyper_1_5_chunk_readings_device_label_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE UNIQUE INDEX _hyper_1_5_chunk_readings_device_label_time_idx ON _timescaledb_internal._hyper_1_5_chunk USING btree (device_id, label, "time" DESC);


--
-- Name: _hyper_1_5_chunk_readings_device_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_5_chunk_readings_device_time_idx ON _timescaledb_internal._hyper_1_5_chunk USING btree (device_id, "time" DESC);


--
-- Name: _hyper_1_5_chunk_readings_metadata_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_5_chunk_readings_metadata_idx ON _timescaledb_internal._hyper_1_5_chunk USING gin (metadata);


--
-- Name: _hyper_1_5_chunk_readings_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_5_chunk_readings_time_idx ON _timescaledb_internal._hyper_1_5_chunk USING btree ("time" DESC);


--
-- Name: _hyper_1_60_chunk_readings_data_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_60_chunk_readings_data_idx ON _timescaledb_internal._hyper_1_60_chunk USING gin (data);


--
-- Name: _hyper_1_60_chunk_readings_device_label_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE UNIQUE INDEX _hyper_1_60_chunk_readings_device_label_time_idx ON _timescaledb_internal._hyper_1_60_chunk USING btree (device_id, label, "time" DESC);


--
-- Name: _hyper_1_60_chunk_readings_device_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_60_chunk_readings_device_time_idx ON _timescaledb_internal._hyper_1_60_chunk USING btree (device_id, "time" DESC);


--
-- Name: _hyper_1_60_chunk_readings_metadata_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_60_chunk_readings_metadata_idx ON _timescaledb_internal._hyper_1_60_chunk USING gin (metadata);


--
-- Name: _hyper_1_60_chunk_readings_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_60_chunk_readings_time_idx ON _timescaledb_internal._hyper_1_60_chunk USING btree ("time" DESC);


--
-- Name: _hyper_1_61_chunk_readings_data_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_61_chunk_readings_data_idx ON _timescaledb_internal._hyper_1_61_chunk USING gin (data);


--
-- Name: _hyper_1_61_chunk_readings_device_label_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE UNIQUE INDEX _hyper_1_61_chunk_readings_device_label_time_idx ON _timescaledb_internal._hyper_1_61_chunk USING btree (device_id, label, "time" DESC);


--
-- Name: _hyper_1_61_chunk_readings_device_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_61_chunk_readings_device_time_idx ON _timescaledb_internal._hyper_1_61_chunk USING btree (device_id, "time" DESC);


--
-- Name: _hyper_1_61_chunk_readings_metadata_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_61_chunk_readings_metadata_idx ON _timescaledb_internal._hyper_1_61_chunk USING gin (metadata);


--
-- Name: _hyper_1_61_chunk_readings_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_61_chunk_readings_time_idx ON _timescaledb_internal._hyper_1_61_chunk USING btree ("time" DESC);


--
-- Name: _hyper_1_62_chunk_readings_data_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_62_chunk_readings_data_idx ON _timescaledb_internal._hyper_1_62_chunk USING gin (data);


--
-- Name: _hyper_1_62_chunk_readings_device_label_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE UNIQUE INDEX _hyper_1_62_chunk_readings_device_label_time_idx ON _timescaledb_internal._hyper_1_62_chunk USING btree (device_id, label, "time" DESC);


--
-- Name: _hyper_1_62_chunk_readings_device_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_62_chunk_readings_device_time_idx ON _timescaledb_internal._hyper_1_62_chunk USING btree (device_id, "time" DESC);


--
-- Name: _hyper_1_62_chunk_readings_metadata_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_62_chunk_readings_metadata_idx ON _timescaledb_internal._hyper_1_62_chunk USING gin (metadata);


--
-- Name: _hyper_1_62_chunk_readings_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_62_chunk_readings_time_idx ON _timescaledb_internal._hyper_1_62_chunk USING btree ("time" DESC);


--
-- Name: _hyper_1_63_chunk_readings_data_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_63_chunk_readings_data_idx ON _timescaledb_internal._hyper_1_63_chunk USING gin (data);


--
-- Name: _hyper_1_63_chunk_readings_device_label_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE UNIQUE INDEX _hyper_1_63_chunk_readings_device_label_time_idx ON _timescaledb_internal._hyper_1_63_chunk USING btree (device_id, label, "time" DESC);


--
-- Name: _hyper_1_63_chunk_readings_device_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_63_chunk_readings_device_time_idx ON _timescaledb_internal._hyper_1_63_chunk USING btree (device_id, "time" DESC);


--
-- Name: _hyper_1_63_chunk_readings_metadata_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_63_chunk_readings_metadata_idx ON _timescaledb_internal._hyper_1_63_chunk USING gin (metadata);


--
-- Name: _hyper_1_63_chunk_readings_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_63_chunk_readings_time_idx ON _timescaledb_internal._hyper_1_63_chunk USING btree ("time" DESC);


--
-- Name: _hyper_1_64_chunk_readings_data_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_64_chunk_readings_data_idx ON _timescaledb_internal._hyper_1_64_chunk USING gin (data);


--
-- Name: _hyper_1_64_chunk_readings_device_label_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE UNIQUE INDEX _hyper_1_64_chunk_readings_device_label_time_idx ON _timescaledb_internal._hyper_1_64_chunk USING btree (device_id, label, "time" DESC);


--
-- Name: _hyper_1_64_chunk_readings_device_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_64_chunk_readings_device_time_idx ON _timescaledb_internal._hyper_1_64_chunk USING btree (device_id, "time" DESC);


--
-- Name: _hyper_1_64_chunk_readings_metadata_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_64_chunk_readings_metadata_idx ON _timescaledb_internal._hyper_1_64_chunk USING gin (metadata);


--
-- Name: _hyper_1_64_chunk_readings_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_64_chunk_readings_time_idx ON _timescaledb_internal._hyper_1_64_chunk USING btree ("time" DESC);


--
-- Name: _hyper_1_65_chunk_readings_data_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_65_chunk_readings_data_idx ON _timescaledb_internal._hyper_1_65_chunk USING gin (data);


--
-- Name: _hyper_1_65_chunk_readings_device_label_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE UNIQUE INDEX _hyper_1_65_chunk_readings_device_label_time_idx ON _timescaledb_internal._hyper_1_65_chunk USING btree (device_id, label, "time" DESC);


--
-- Name: _hyper_1_65_chunk_readings_device_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_65_chunk_readings_device_time_idx ON _timescaledb_internal._hyper_1_65_chunk USING btree (device_id, "time" DESC);


--
-- Name: _hyper_1_65_chunk_readings_metadata_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_65_chunk_readings_metadata_idx ON _timescaledb_internal._hyper_1_65_chunk USING gin (metadata);


--
-- Name: _hyper_1_65_chunk_readings_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_65_chunk_readings_time_idx ON _timescaledb_internal._hyper_1_65_chunk USING btree ("time" DESC);


--
-- Name: _hyper_1_66_chunk_readings_data_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_66_chunk_readings_data_idx ON _timescaledb_internal._hyper_1_66_chunk USING gin (data);


--
-- Name: _hyper_1_66_chunk_readings_device_label_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE UNIQUE INDEX _hyper_1_66_chunk_readings_device_label_time_idx ON _timescaledb_internal._hyper_1_66_chunk USING btree (device_id, label, "time" DESC);


--
-- Name: _hyper_1_66_chunk_readings_device_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_66_chunk_readings_device_time_idx ON _timescaledb_internal._hyper_1_66_chunk USING btree (device_id, "time" DESC);


--
-- Name: _hyper_1_66_chunk_readings_metadata_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_66_chunk_readings_metadata_idx ON _timescaledb_internal._hyper_1_66_chunk USING gin (metadata);


--
-- Name: _hyper_1_66_chunk_readings_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_66_chunk_readings_time_idx ON _timescaledb_internal._hyper_1_66_chunk USING btree ("time" DESC);


--
-- Name: _hyper_1_67_chunk_readings_data_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_67_chunk_readings_data_idx ON _timescaledb_internal._hyper_1_67_chunk USING gin (data);


--
-- Name: _hyper_1_67_chunk_readings_device_label_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE UNIQUE INDEX _hyper_1_67_chunk_readings_device_label_time_idx ON _timescaledb_internal._hyper_1_67_chunk USING btree (device_id, label, "time" DESC);


--
-- Name: _hyper_1_67_chunk_readings_device_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_67_chunk_readings_device_time_idx ON _timescaledb_internal._hyper_1_67_chunk USING btree (device_id, "time" DESC);


--
-- Name: _hyper_1_67_chunk_readings_metadata_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_67_chunk_readings_metadata_idx ON _timescaledb_internal._hyper_1_67_chunk USING gin (metadata);


--
-- Name: _hyper_1_67_chunk_readings_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_67_chunk_readings_time_idx ON _timescaledb_internal._hyper_1_67_chunk USING btree ("time" DESC);


--
-- Name: _hyper_1_68_chunk_readings_data_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_68_chunk_readings_data_idx ON _timescaledb_internal._hyper_1_68_chunk USING gin (data);


--
-- Name: _hyper_1_68_chunk_readings_device_label_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE UNIQUE INDEX _hyper_1_68_chunk_readings_device_label_time_idx ON _timescaledb_internal._hyper_1_68_chunk USING btree (device_id, label, "time" DESC);


--
-- Name: _hyper_1_68_chunk_readings_device_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_68_chunk_readings_device_time_idx ON _timescaledb_internal._hyper_1_68_chunk USING btree (device_id, "time" DESC);


--
-- Name: _hyper_1_68_chunk_readings_metadata_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_68_chunk_readings_metadata_idx ON _timescaledb_internal._hyper_1_68_chunk USING gin (metadata);


--
-- Name: _hyper_1_68_chunk_readings_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_68_chunk_readings_time_idx ON _timescaledb_internal._hyper_1_68_chunk USING btree ("time" DESC);


--
-- Name: _hyper_1_69_chunk_readings_data_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_69_chunk_readings_data_idx ON _timescaledb_internal._hyper_1_69_chunk USING gin (data);


--
-- Name: _hyper_1_69_chunk_readings_device_label_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE UNIQUE INDEX _hyper_1_69_chunk_readings_device_label_time_idx ON _timescaledb_internal._hyper_1_69_chunk USING btree (device_id, label, "time" DESC);


--
-- Name: _hyper_1_69_chunk_readings_device_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_69_chunk_readings_device_time_idx ON _timescaledb_internal._hyper_1_69_chunk USING btree (device_id, "time" DESC);


--
-- Name: _hyper_1_69_chunk_readings_metadata_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_69_chunk_readings_metadata_idx ON _timescaledb_internal._hyper_1_69_chunk USING gin (metadata);


--
-- Name: _hyper_1_69_chunk_readings_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_69_chunk_readings_time_idx ON _timescaledb_internal._hyper_1_69_chunk USING btree ("time" DESC);


--
-- Name: _hyper_1_6_chunk_readings_data_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_6_chunk_readings_data_idx ON _timescaledb_internal._hyper_1_6_chunk USING gin (data);


--
-- Name: _hyper_1_6_chunk_readings_device_label_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE UNIQUE INDEX _hyper_1_6_chunk_readings_device_label_time_idx ON _timescaledb_internal._hyper_1_6_chunk USING btree (device_id, label, "time" DESC);


--
-- Name: _hyper_1_6_chunk_readings_device_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_6_chunk_readings_device_time_idx ON _timescaledb_internal._hyper_1_6_chunk USING btree (device_id, "time" DESC);


--
-- Name: _hyper_1_6_chunk_readings_metadata_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_6_chunk_readings_metadata_idx ON _timescaledb_internal._hyper_1_6_chunk USING gin (metadata);


--
-- Name: _hyper_1_6_chunk_readings_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_6_chunk_readings_time_idx ON _timescaledb_internal._hyper_1_6_chunk USING btree ("time" DESC);


--
-- Name: _hyper_1_70_chunk_readings_data_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_70_chunk_readings_data_idx ON _timescaledb_internal._hyper_1_70_chunk USING gin (data);


--
-- Name: _hyper_1_70_chunk_readings_device_label_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE UNIQUE INDEX _hyper_1_70_chunk_readings_device_label_time_idx ON _timescaledb_internal._hyper_1_70_chunk USING btree (device_id, label, "time" DESC);


--
-- Name: _hyper_1_70_chunk_readings_device_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_70_chunk_readings_device_time_idx ON _timescaledb_internal._hyper_1_70_chunk USING btree (device_id, "time" DESC);


--
-- Name: _hyper_1_70_chunk_readings_metadata_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_70_chunk_readings_metadata_idx ON _timescaledb_internal._hyper_1_70_chunk USING gin (metadata);


--
-- Name: _hyper_1_70_chunk_readings_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_70_chunk_readings_time_idx ON _timescaledb_internal._hyper_1_70_chunk USING btree ("time" DESC);


--
-- Name: _hyper_1_71_chunk_readings_data_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_71_chunk_readings_data_idx ON _timescaledb_internal._hyper_1_71_chunk USING gin (data);


--
-- Name: _hyper_1_71_chunk_readings_device_label_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE UNIQUE INDEX _hyper_1_71_chunk_readings_device_label_time_idx ON _timescaledb_internal._hyper_1_71_chunk USING btree (device_id, label, "time" DESC);


--
-- Name: _hyper_1_71_chunk_readings_device_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_71_chunk_readings_device_time_idx ON _timescaledb_internal._hyper_1_71_chunk USING btree (device_id, "time" DESC);


--
-- Name: _hyper_1_71_chunk_readings_metadata_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_71_chunk_readings_metadata_idx ON _timescaledb_internal._hyper_1_71_chunk USING gin (metadata);


--
-- Name: _hyper_1_71_chunk_readings_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_71_chunk_readings_time_idx ON _timescaledb_internal._hyper_1_71_chunk USING btree ("time" DESC);


--
-- Name: _hyper_1_72_chunk_readings_data_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_72_chunk_readings_data_idx ON _timescaledb_internal._hyper_1_72_chunk USING gin (data);


--
-- Name: _hyper_1_72_chunk_readings_device_label_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE UNIQUE INDEX _hyper_1_72_chunk_readings_device_label_time_idx ON _timescaledb_internal._hyper_1_72_chunk USING btree (device_id, label, "time" DESC);


--
-- Name: _hyper_1_72_chunk_readings_device_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_72_chunk_readings_device_time_idx ON _timescaledb_internal._hyper_1_72_chunk USING btree (device_id, "time" DESC);


--
-- Name: _hyper_1_72_chunk_readings_metadata_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_72_chunk_readings_metadata_idx ON _timescaledb_internal._hyper_1_72_chunk USING gin (metadata);


--
-- Name: _hyper_1_72_chunk_readings_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_72_chunk_readings_time_idx ON _timescaledb_internal._hyper_1_72_chunk USING btree ("time" DESC);


--
-- Name: _hyper_1_73_chunk_readings_data_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_73_chunk_readings_data_idx ON _timescaledb_internal._hyper_1_73_chunk USING gin (data);


--
-- Name: _hyper_1_73_chunk_readings_device_label_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE UNIQUE INDEX _hyper_1_73_chunk_readings_device_label_time_idx ON _timescaledb_internal._hyper_1_73_chunk USING btree (device_id, label, "time" DESC);


--
-- Name: _hyper_1_73_chunk_readings_device_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_73_chunk_readings_device_time_idx ON _timescaledb_internal._hyper_1_73_chunk USING btree (device_id, "time" DESC);


--
-- Name: _hyper_1_73_chunk_readings_metadata_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_73_chunk_readings_metadata_idx ON _timescaledb_internal._hyper_1_73_chunk USING gin (metadata);


--
-- Name: _hyper_1_73_chunk_readings_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_73_chunk_readings_time_idx ON _timescaledb_internal._hyper_1_73_chunk USING btree ("time" DESC);


--
-- Name: _hyper_1_7_chunk_readings_data_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_7_chunk_readings_data_idx ON _timescaledb_internal._hyper_1_7_chunk USING gin (data);


--
-- Name: _hyper_1_7_chunk_readings_device_label_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE UNIQUE INDEX _hyper_1_7_chunk_readings_device_label_time_idx ON _timescaledb_internal._hyper_1_7_chunk USING btree (device_id, label, "time" DESC);


--
-- Name: _hyper_1_7_chunk_readings_device_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_7_chunk_readings_device_time_idx ON _timescaledb_internal._hyper_1_7_chunk USING btree (device_id, "time" DESC);


--
-- Name: _hyper_1_7_chunk_readings_metadata_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_7_chunk_readings_metadata_idx ON _timescaledb_internal._hyper_1_7_chunk USING gin (metadata);


--
-- Name: _hyper_1_7_chunk_readings_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_7_chunk_readings_time_idx ON _timescaledb_internal._hyper_1_7_chunk USING btree ("time" DESC);


--
-- Name: _hyper_1_8_chunk_readings_data_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_8_chunk_readings_data_idx ON _timescaledb_internal._hyper_1_8_chunk USING gin (data);


--
-- Name: _hyper_1_8_chunk_readings_device_label_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE UNIQUE INDEX _hyper_1_8_chunk_readings_device_label_time_idx ON _timescaledb_internal._hyper_1_8_chunk USING btree (device_id, label, "time" DESC);


--
-- Name: _hyper_1_8_chunk_readings_device_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_8_chunk_readings_device_time_idx ON _timescaledb_internal._hyper_1_8_chunk USING btree (device_id, "time" DESC);


--
-- Name: _hyper_1_8_chunk_readings_metadata_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_8_chunk_readings_metadata_idx ON _timescaledb_internal._hyper_1_8_chunk USING gin (metadata);


--
-- Name: _hyper_1_8_chunk_readings_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_8_chunk_readings_time_idx ON _timescaledb_internal._hyper_1_8_chunk USING btree ("time" DESC);


--
-- Name: _hyper_1_9_chunk_readings_data_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_9_chunk_readings_data_idx ON _timescaledb_internal._hyper_1_9_chunk USING gin (data);


--
-- Name: _hyper_1_9_chunk_readings_device_label_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE UNIQUE INDEX _hyper_1_9_chunk_readings_device_label_time_idx ON _timescaledb_internal._hyper_1_9_chunk USING btree (device_id, label, "time" DESC);


--
-- Name: _hyper_1_9_chunk_readings_device_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_9_chunk_readings_device_time_idx ON _timescaledb_internal._hyper_1_9_chunk USING btree (device_id, "time" DESC);


--
-- Name: _hyper_1_9_chunk_readings_metadata_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_9_chunk_readings_metadata_idx ON _timescaledb_internal._hyper_1_9_chunk USING gin (metadata);


--
-- Name: _hyper_1_9_chunk_readings_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_9_chunk_readings_time_idx ON _timescaledb_internal._hyper_1_9_chunk USING btree ("time" DESC);


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
-- Name: _hyper_1_10_chunk 10_10_readings_device_id_fkey; Type: FK CONSTRAINT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_10_chunk
    ADD CONSTRAINT "10_10_readings_device_id_fkey" FOREIGN KEY (device_id) REFERENCES app_public.devices(id);


--
-- Name: _hyper_1_11_chunk 11_11_readings_device_id_fkey; Type: FK CONSTRAINT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_11_chunk
    ADD CONSTRAINT "11_11_readings_device_id_fkey" FOREIGN KEY (device_id) REFERENCES app_public.devices(id);


--
-- Name: _hyper_1_12_chunk 12_12_readings_device_id_fkey; Type: FK CONSTRAINT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_12_chunk
    ADD CONSTRAINT "12_12_readings_device_id_fkey" FOREIGN KEY (device_id) REFERENCES app_public.devices(id);


--
-- Name: _hyper_1_13_chunk 13_13_readings_device_id_fkey; Type: FK CONSTRAINT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_13_chunk
    ADD CONSTRAINT "13_13_readings_device_id_fkey" FOREIGN KEY (device_id) REFERENCES app_public.devices(id);


--
-- Name: _hyper_1_14_chunk 14_14_readings_device_id_fkey; Type: FK CONSTRAINT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_14_chunk
    ADD CONSTRAINT "14_14_readings_device_id_fkey" FOREIGN KEY (device_id) REFERENCES app_public.devices(id);


--
-- Name: _hyper_1_15_chunk 15_15_readings_device_id_fkey; Type: FK CONSTRAINT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_15_chunk
    ADD CONSTRAINT "15_15_readings_device_id_fkey" FOREIGN KEY (device_id) REFERENCES app_public.devices(id);


--
-- Name: _hyper_1_16_chunk 16_16_readings_device_id_fkey; Type: FK CONSTRAINT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_16_chunk
    ADD CONSTRAINT "16_16_readings_device_id_fkey" FOREIGN KEY (device_id) REFERENCES app_public.devices(id);


--
-- Name: _hyper_1_17_chunk 17_17_readings_device_id_fkey; Type: FK CONSTRAINT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_17_chunk
    ADD CONSTRAINT "17_17_readings_device_id_fkey" FOREIGN KEY (device_id) REFERENCES app_public.devices(id);


--
-- Name: _hyper_1_18_chunk 18_18_readings_device_id_fkey; Type: FK CONSTRAINT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_18_chunk
    ADD CONSTRAINT "18_18_readings_device_id_fkey" FOREIGN KEY (device_id) REFERENCES app_public.devices(id);


--
-- Name: _hyper_1_19_chunk 19_19_readings_device_id_fkey; Type: FK CONSTRAINT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_19_chunk
    ADD CONSTRAINT "19_19_readings_device_id_fkey" FOREIGN KEY (device_id) REFERENCES app_public.devices(id);


--
-- Name: _hyper_1_1_chunk 1_1_readings_device_id_fkey; Type: FK CONSTRAINT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_1_chunk
    ADD CONSTRAINT "1_1_readings_device_id_fkey" FOREIGN KEY (device_id) REFERENCES app_public.devices(id);


--
-- Name: _hyper_1_20_chunk 20_20_readings_device_id_fkey; Type: FK CONSTRAINT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_20_chunk
    ADD CONSTRAINT "20_20_readings_device_id_fkey" FOREIGN KEY (device_id) REFERENCES app_public.devices(id);


--
-- Name: _hyper_1_21_chunk 21_21_readings_device_id_fkey; Type: FK CONSTRAINT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_21_chunk
    ADD CONSTRAINT "21_21_readings_device_id_fkey" FOREIGN KEY (device_id) REFERENCES app_public.devices(id);


--
-- Name: _hyper_1_22_chunk 22_22_readings_device_id_fkey; Type: FK CONSTRAINT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_22_chunk
    ADD CONSTRAINT "22_22_readings_device_id_fkey" FOREIGN KEY (device_id) REFERENCES app_public.devices(id);


--
-- Name: _hyper_1_23_chunk 23_23_readings_device_id_fkey; Type: FK CONSTRAINT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_23_chunk
    ADD CONSTRAINT "23_23_readings_device_id_fkey" FOREIGN KEY (device_id) REFERENCES app_public.devices(id);


--
-- Name: _hyper_1_24_chunk 24_24_readings_device_id_fkey; Type: FK CONSTRAINT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_24_chunk
    ADD CONSTRAINT "24_24_readings_device_id_fkey" FOREIGN KEY (device_id) REFERENCES app_public.devices(id);


--
-- Name: _hyper_1_25_chunk 25_25_readings_device_id_fkey; Type: FK CONSTRAINT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_25_chunk
    ADD CONSTRAINT "25_25_readings_device_id_fkey" FOREIGN KEY (device_id) REFERENCES app_public.devices(id);


--
-- Name: _hyper_1_26_chunk 26_26_readings_device_id_fkey; Type: FK CONSTRAINT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_26_chunk
    ADD CONSTRAINT "26_26_readings_device_id_fkey" FOREIGN KEY (device_id) REFERENCES app_public.devices(id);


--
-- Name: _hyper_1_27_chunk 27_27_readings_device_id_fkey; Type: FK CONSTRAINT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_27_chunk
    ADD CONSTRAINT "27_27_readings_device_id_fkey" FOREIGN KEY (device_id) REFERENCES app_public.devices(id);


--
-- Name: _hyper_1_28_chunk 28_28_readings_device_id_fkey; Type: FK CONSTRAINT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_28_chunk
    ADD CONSTRAINT "28_28_readings_device_id_fkey" FOREIGN KEY (device_id) REFERENCES app_public.devices(id);


--
-- Name: _hyper_1_29_chunk 29_29_readings_device_id_fkey; Type: FK CONSTRAINT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_29_chunk
    ADD CONSTRAINT "29_29_readings_device_id_fkey" FOREIGN KEY (device_id) REFERENCES app_public.devices(id);


--
-- Name: _hyper_1_2_chunk 2_2_readings_device_id_fkey; Type: FK CONSTRAINT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_2_chunk
    ADD CONSTRAINT "2_2_readings_device_id_fkey" FOREIGN KEY (device_id) REFERENCES app_public.devices(id);


--
-- Name: _hyper_1_30_chunk 30_30_readings_device_id_fkey; Type: FK CONSTRAINT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_30_chunk
    ADD CONSTRAINT "30_30_readings_device_id_fkey" FOREIGN KEY (device_id) REFERENCES app_public.devices(id);


--
-- Name: _hyper_1_31_chunk 31_31_readings_device_id_fkey; Type: FK CONSTRAINT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_31_chunk
    ADD CONSTRAINT "31_31_readings_device_id_fkey" FOREIGN KEY (device_id) REFERENCES app_public.devices(id);


--
-- Name: _hyper_1_32_chunk 32_32_readings_device_id_fkey; Type: FK CONSTRAINT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_32_chunk
    ADD CONSTRAINT "32_32_readings_device_id_fkey" FOREIGN KEY (device_id) REFERENCES app_public.devices(id);


--
-- Name: _hyper_1_33_chunk 33_33_readings_device_id_fkey; Type: FK CONSTRAINT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_33_chunk
    ADD CONSTRAINT "33_33_readings_device_id_fkey" FOREIGN KEY (device_id) REFERENCES app_public.devices(id);


--
-- Name: _hyper_1_34_chunk 34_34_readings_device_id_fkey; Type: FK CONSTRAINT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_34_chunk
    ADD CONSTRAINT "34_34_readings_device_id_fkey" FOREIGN KEY (device_id) REFERENCES app_public.devices(id);


--
-- Name: _hyper_1_35_chunk 35_35_readings_device_id_fkey; Type: FK CONSTRAINT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_35_chunk
    ADD CONSTRAINT "35_35_readings_device_id_fkey" FOREIGN KEY (device_id) REFERENCES app_public.devices(id);


--
-- Name: _hyper_1_36_chunk 36_36_readings_device_id_fkey; Type: FK CONSTRAINT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_36_chunk
    ADD CONSTRAINT "36_36_readings_device_id_fkey" FOREIGN KEY (device_id) REFERENCES app_public.devices(id);


--
-- Name: _hyper_1_37_chunk 37_37_readings_device_id_fkey; Type: FK CONSTRAINT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_37_chunk
    ADD CONSTRAINT "37_37_readings_device_id_fkey" FOREIGN KEY (device_id) REFERENCES app_public.devices(id);


--
-- Name: _hyper_1_38_chunk 38_38_readings_device_id_fkey; Type: FK CONSTRAINT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_38_chunk
    ADD CONSTRAINT "38_38_readings_device_id_fkey" FOREIGN KEY (device_id) REFERENCES app_public.devices(id);


--
-- Name: _hyper_1_39_chunk 39_39_readings_device_id_fkey; Type: FK CONSTRAINT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_39_chunk
    ADD CONSTRAINT "39_39_readings_device_id_fkey" FOREIGN KEY (device_id) REFERENCES app_public.devices(id);


--
-- Name: _hyper_1_3_chunk 3_3_readings_device_id_fkey; Type: FK CONSTRAINT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_3_chunk
    ADD CONSTRAINT "3_3_readings_device_id_fkey" FOREIGN KEY (device_id) REFERENCES app_public.devices(id);


--
-- Name: _hyper_1_40_chunk 40_40_readings_device_id_fkey; Type: FK CONSTRAINT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_40_chunk
    ADD CONSTRAINT "40_40_readings_device_id_fkey" FOREIGN KEY (device_id) REFERENCES app_public.devices(id);


--
-- Name: _hyper_1_41_chunk 41_41_readings_device_id_fkey; Type: FK CONSTRAINT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_41_chunk
    ADD CONSTRAINT "41_41_readings_device_id_fkey" FOREIGN KEY (device_id) REFERENCES app_public.devices(id);


--
-- Name: _hyper_1_42_chunk 42_42_readings_device_id_fkey; Type: FK CONSTRAINT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_42_chunk
    ADD CONSTRAINT "42_42_readings_device_id_fkey" FOREIGN KEY (device_id) REFERENCES app_public.devices(id);


--
-- Name: _hyper_1_43_chunk 43_43_readings_device_id_fkey; Type: FK CONSTRAINT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_43_chunk
    ADD CONSTRAINT "43_43_readings_device_id_fkey" FOREIGN KEY (device_id) REFERENCES app_public.devices(id);


--
-- Name: _hyper_1_44_chunk 44_44_readings_device_id_fkey; Type: FK CONSTRAINT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_44_chunk
    ADD CONSTRAINT "44_44_readings_device_id_fkey" FOREIGN KEY (device_id) REFERENCES app_public.devices(id);


--
-- Name: _hyper_1_45_chunk 45_45_readings_device_id_fkey; Type: FK CONSTRAINT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_45_chunk
    ADD CONSTRAINT "45_45_readings_device_id_fkey" FOREIGN KEY (device_id) REFERENCES app_public.devices(id);


--
-- Name: _hyper_1_46_chunk 46_46_readings_device_id_fkey; Type: FK CONSTRAINT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_46_chunk
    ADD CONSTRAINT "46_46_readings_device_id_fkey" FOREIGN KEY (device_id) REFERENCES app_public.devices(id);


--
-- Name: _hyper_1_47_chunk 47_47_readings_device_id_fkey; Type: FK CONSTRAINT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_47_chunk
    ADD CONSTRAINT "47_47_readings_device_id_fkey" FOREIGN KEY (device_id) REFERENCES app_public.devices(id);


--
-- Name: _hyper_1_48_chunk 48_48_readings_device_id_fkey; Type: FK CONSTRAINT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_48_chunk
    ADD CONSTRAINT "48_48_readings_device_id_fkey" FOREIGN KEY (device_id) REFERENCES app_public.devices(id);


--
-- Name: _hyper_1_49_chunk 49_49_readings_device_id_fkey; Type: FK CONSTRAINT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_49_chunk
    ADD CONSTRAINT "49_49_readings_device_id_fkey" FOREIGN KEY (device_id) REFERENCES app_public.devices(id);


--
-- Name: _hyper_1_4_chunk 4_4_readings_device_id_fkey; Type: FK CONSTRAINT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_4_chunk
    ADD CONSTRAINT "4_4_readings_device_id_fkey" FOREIGN KEY (device_id) REFERENCES app_public.devices(id);


--
-- Name: _hyper_1_50_chunk 50_50_readings_device_id_fkey; Type: FK CONSTRAINT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_50_chunk
    ADD CONSTRAINT "50_50_readings_device_id_fkey" FOREIGN KEY (device_id) REFERENCES app_public.devices(id);


--
-- Name: _hyper_1_51_chunk 51_51_readings_device_id_fkey; Type: FK CONSTRAINT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_51_chunk
    ADD CONSTRAINT "51_51_readings_device_id_fkey" FOREIGN KEY (device_id) REFERENCES app_public.devices(id);


--
-- Name: _hyper_1_52_chunk 52_52_readings_device_id_fkey; Type: FK CONSTRAINT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_52_chunk
    ADD CONSTRAINT "52_52_readings_device_id_fkey" FOREIGN KEY (device_id) REFERENCES app_public.devices(id);


--
-- Name: _hyper_1_53_chunk 53_53_readings_device_id_fkey; Type: FK CONSTRAINT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_53_chunk
    ADD CONSTRAINT "53_53_readings_device_id_fkey" FOREIGN KEY (device_id) REFERENCES app_public.devices(id);


--
-- Name: _hyper_1_54_chunk 54_54_readings_device_id_fkey; Type: FK CONSTRAINT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_54_chunk
    ADD CONSTRAINT "54_54_readings_device_id_fkey" FOREIGN KEY (device_id) REFERENCES app_public.devices(id);


--
-- Name: _hyper_1_55_chunk 55_55_readings_device_id_fkey; Type: FK CONSTRAINT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_55_chunk
    ADD CONSTRAINT "55_55_readings_device_id_fkey" FOREIGN KEY (device_id) REFERENCES app_public.devices(id);


--
-- Name: _hyper_1_56_chunk 56_56_readings_device_id_fkey; Type: FK CONSTRAINT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_56_chunk
    ADD CONSTRAINT "56_56_readings_device_id_fkey" FOREIGN KEY (device_id) REFERENCES app_public.devices(id);


--
-- Name: _hyper_1_57_chunk 57_57_readings_device_id_fkey; Type: FK CONSTRAINT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_57_chunk
    ADD CONSTRAINT "57_57_readings_device_id_fkey" FOREIGN KEY (device_id) REFERENCES app_public.devices(id);


--
-- Name: _hyper_1_58_chunk 58_58_readings_device_id_fkey; Type: FK CONSTRAINT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_58_chunk
    ADD CONSTRAINT "58_58_readings_device_id_fkey" FOREIGN KEY (device_id) REFERENCES app_public.devices(id);


--
-- Name: _hyper_1_59_chunk 59_59_readings_device_id_fkey; Type: FK CONSTRAINT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_59_chunk
    ADD CONSTRAINT "59_59_readings_device_id_fkey" FOREIGN KEY (device_id) REFERENCES app_public.devices(id);


--
-- Name: _hyper_1_5_chunk 5_5_readings_device_id_fkey; Type: FK CONSTRAINT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_5_chunk
    ADD CONSTRAINT "5_5_readings_device_id_fkey" FOREIGN KEY (device_id) REFERENCES app_public.devices(id);


--
-- Name: _hyper_1_60_chunk 60_60_readings_device_id_fkey; Type: FK CONSTRAINT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_60_chunk
    ADD CONSTRAINT "60_60_readings_device_id_fkey" FOREIGN KEY (device_id) REFERENCES app_public.devices(id);


--
-- Name: _hyper_1_61_chunk 61_61_readings_device_id_fkey; Type: FK CONSTRAINT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_61_chunk
    ADD CONSTRAINT "61_61_readings_device_id_fkey" FOREIGN KEY (device_id) REFERENCES app_public.devices(id);


--
-- Name: _hyper_1_62_chunk 62_62_readings_device_id_fkey; Type: FK CONSTRAINT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_62_chunk
    ADD CONSTRAINT "62_62_readings_device_id_fkey" FOREIGN KEY (device_id) REFERENCES app_public.devices(id);


--
-- Name: _hyper_1_63_chunk 63_63_readings_device_id_fkey; Type: FK CONSTRAINT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_63_chunk
    ADD CONSTRAINT "63_63_readings_device_id_fkey" FOREIGN KEY (device_id) REFERENCES app_public.devices(id);


--
-- Name: _hyper_1_64_chunk 64_64_readings_device_id_fkey; Type: FK CONSTRAINT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_64_chunk
    ADD CONSTRAINT "64_64_readings_device_id_fkey" FOREIGN KEY (device_id) REFERENCES app_public.devices(id);


--
-- Name: _hyper_1_65_chunk 65_65_readings_device_id_fkey; Type: FK CONSTRAINT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_65_chunk
    ADD CONSTRAINT "65_65_readings_device_id_fkey" FOREIGN KEY (device_id) REFERENCES app_public.devices(id);


--
-- Name: _hyper_1_66_chunk 66_66_readings_device_id_fkey; Type: FK CONSTRAINT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_66_chunk
    ADD CONSTRAINT "66_66_readings_device_id_fkey" FOREIGN KEY (device_id) REFERENCES app_public.devices(id);


--
-- Name: _hyper_1_67_chunk 67_67_readings_device_id_fkey; Type: FK CONSTRAINT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_67_chunk
    ADD CONSTRAINT "67_67_readings_device_id_fkey" FOREIGN KEY (device_id) REFERENCES app_public.devices(id);


--
-- Name: _hyper_1_68_chunk 68_68_readings_device_id_fkey; Type: FK CONSTRAINT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_68_chunk
    ADD CONSTRAINT "68_68_readings_device_id_fkey" FOREIGN KEY (device_id) REFERENCES app_public.devices(id);


--
-- Name: _hyper_1_69_chunk 69_69_readings_device_id_fkey; Type: FK CONSTRAINT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_69_chunk
    ADD CONSTRAINT "69_69_readings_device_id_fkey" FOREIGN KEY (device_id) REFERENCES app_public.devices(id);


--
-- Name: _hyper_1_6_chunk 6_6_readings_device_id_fkey; Type: FK CONSTRAINT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_6_chunk
    ADD CONSTRAINT "6_6_readings_device_id_fkey" FOREIGN KEY (device_id) REFERENCES app_public.devices(id);


--
-- Name: _hyper_1_70_chunk 70_70_readings_device_id_fkey; Type: FK CONSTRAINT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_70_chunk
    ADD CONSTRAINT "70_70_readings_device_id_fkey" FOREIGN KEY (device_id) REFERENCES app_public.devices(id);


--
-- Name: _hyper_1_71_chunk 71_71_readings_device_id_fkey; Type: FK CONSTRAINT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_71_chunk
    ADD CONSTRAINT "71_71_readings_device_id_fkey" FOREIGN KEY (device_id) REFERENCES app_public.devices(id);


--
-- Name: _hyper_1_72_chunk 72_72_readings_device_id_fkey; Type: FK CONSTRAINT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_72_chunk
    ADD CONSTRAINT "72_72_readings_device_id_fkey" FOREIGN KEY (device_id) REFERENCES app_public.devices(id);


--
-- Name: _hyper_1_73_chunk 73_73_readings_device_id_fkey; Type: FK CONSTRAINT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_73_chunk
    ADD CONSTRAINT "73_73_readings_device_id_fkey" FOREIGN KEY (device_id) REFERENCES app_public.devices(id);


--
-- Name: _hyper_1_7_chunk 7_7_readings_device_id_fkey; Type: FK CONSTRAINT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_7_chunk
    ADD CONSTRAINT "7_7_readings_device_id_fkey" FOREIGN KEY (device_id) REFERENCES app_public.devices(id);


--
-- Name: _hyper_1_8_chunk 8_8_readings_device_id_fkey; Type: FK CONSTRAINT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_8_chunk
    ADD CONSTRAINT "8_8_readings_device_id_fkey" FOREIGN KEY (device_id) REFERENCES app_public.devices(id);


--
-- Name: _hyper_1_9_chunk 9_9_readings_device_id_fkey; Type: FK CONSTRAINT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_9_chunk
    ADD CONSTRAINT "9_9_readings_device_id_fkey" FOREIGN KEY (device_id) REFERENCES app_public.devices(id);


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

GRANT ALL ON SCHEMA app_public TO visitor;


--
-- Name: TABLE facilities; Type: ACL; Schema: app_public; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE app_public.facilities TO visitor;


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
-- Name: FUNCTION facilities_metrics(facility app_public.facilities, name text, "interval" interval); Type: ACL; Schema: app_public; Owner: -
--

REVOKE ALL ON FUNCTION app_public.facilities_metrics(facility app_public.facilities, name text, "interval" interval) FROM PUBLIC;
GRANT ALL ON FUNCTION app_public.facilities_metrics(facility app_public.facilities, name text, "interval" interval) TO visitor;


--
-- Name: FUNCTION facility_distinct_tags(); Type: ACL; Schema: app_public; Owner: -
--

REVOKE ALL ON FUNCTION app_public.facility_distinct_tags() FROM PUBLIC;
GRANT ALL ON FUNCTION app_public.facility_distinct_tags() TO visitor;


--
-- Name: FUNCTION facility_rankings(metric text, tags text[], "interval" interval); Type: ACL; Schema: app_public; Owner: -
--

REVOKE ALL ON FUNCTION app_public.facility_rankings(metric text, tags text[], "interval" interval) FROM PUBLIC;
GRANT ALL ON FUNCTION app_public.facility_rankings(metric text, tags text[], "interval" interval) TO visitor;


--
-- Name: TABLE readings; Type: ACL; Schema: app_public; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE app_public.readings TO visitor;


--
-- Name: TABLE _hyper_1_10_chunk; Type: ACL; Schema: _timescaledb_internal; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE _timescaledb_internal._hyper_1_10_chunk TO visitor;


--
-- Name: TABLE _hyper_1_11_chunk; Type: ACL; Schema: _timescaledb_internal; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE _timescaledb_internal._hyper_1_11_chunk TO visitor;


--
-- Name: TABLE _hyper_1_12_chunk; Type: ACL; Schema: _timescaledb_internal; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE _timescaledb_internal._hyper_1_12_chunk TO visitor;


--
-- Name: TABLE _hyper_1_13_chunk; Type: ACL; Schema: _timescaledb_internal; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE _timescaledb_internal._hyper_1_13_chunk TO visitor;


--
-- Name: TABLE _hyper_1_14_chunk; Type: ACL; Schema: _timescaledb_internal; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE _timescaledb_internal._hyper_1_14_chunk TO visitor;


--
-- Name: TABLE _hyper_1_15_chunk; Type: ACL; Schema: _timescaledb_internal; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE _timescaledb_internal._hyper_1_15_chunk TO visitor;


--
-- Name: TABLE _hyper_1_16_chunk; Type: ACL; Schema: _timescaledb_internal; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE _timescaledb_internal._hyper_1_16_chunk TO visitor;


--
-- Name: TABLE _hyper_1_17_chunk; Type: ACL; Schema: _timescaledb_internal; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE _timescaledb_internal._hyper_1_17_chunk TO visitor;


--
-- Name: TABLE _hyper_1_18_chunk; Type: ACL; Schema: _timescaledb_internal; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE _timescaledb_internal._hyper_1_18_chunk TO visitor;


--
-- Name: TABLE _hyper_1_19_chunk; Type: ACL; Schema: _timescaledb_internal; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE _timescaledb_internal._hyper_1_19_chunk TO visitor;


--
-- Name: TABLE _hyper_1_1_chunk; Type: ACL; Schema: _timescaledb_internal; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE _timescaledb_internal._hyper_1_1_chunk TO visitor;


--
-- Name: TABLE _hyper_1_20_chunk; Type: ACL; Schema: _timescaledb_internal; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE _timescaledb_internal._hyper_1_20_chunk TO visitor;


--
-- Name: TABLE _hyper_1_21_chunk; Type: ACL; Schema: _timescaledb_internal; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE _timescaledb_internal._hyper_1_21_chunk TO visitor;


--
-- Name: TABLE _hyper_1_22_chunk; Type: ACL; Schema: _timescaledb_internal; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE _timescaledb_internal._hyper_1_22_chunk TO visitor;


--
-- Name: TABLE _hyper_1_23_chunk; Type: ACL; Schema: _timescaledb_internal; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE _timescaledb_internal._hyper_1_23_chunk TO visitor;


--
-- Name: TABLE _hyper_1_24_chunk; Type: ACL; Schema: _timescaledb_internal; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE _timescaledb_internal._hyper_1_24_chunk TO visitor;


--
-- Name: TABLE _hyper_1_25_chunk; Type: ACL; Schema: _timescaledb_internal; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE _timescaledb_internal._hyper_1_25_chunk TO visitor;


--
-- Name: TABLE _hyper_1_26_chunk; Type: ACL; Schema: _timescaledb_internal; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE _timescaledb_internal._hyper_1_26_chunk TO visitor;


--
-- Name: TABLE _hyper_1_27_chunk; Type: ACL; Schema: _timescaledb_internal; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE _timescaledb_internal._hyper_1_27_chunk TO visitor;


--
-- Name: TABLE _hyper_1_28_chunk; Type: ACL; Schema: _timescaledb_internal; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE _timescaledb_internal._hyper_1_28_chunk TO visitor;


--
-- Name: TABLE _hyper_1_29_chunk; Type: ACL; Schema: _timescaledb_internal; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE _timescaledb_internal._hyper_1_29_chunk TO visitor;


--
-- Name: TABLE _hyper_1_2_chunk; Type: ACL; Schema: _timescaledb_internal; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE _timescaledb_internal._hyper_1_2_chunk TO visitor;


--
-- Name: TABLE _hyper_1_30_chunk; Type: ACL; Schema: _timescaledb_internal; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE _timescaledb_internal._hyper_1_30_chunk TO visitor;


--
-- Name: TABLE _hyper_1_31_chunk; Type: ACL; Schema: _timescaledb_internal; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE _timescaledb_internal._hyper_1_31_chunk TO visitor;


--
-- Name: TABLE _hyper_1_32_chunk; Type: ACL; Schema: _timescaledb_internal; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE _timescaledb_internal._hyper_1_32_chunk TO visitor;


--
-- Name: TABLE _hyper_1_33_chunk; Type: ACL; Schema: _timescaledb_internal; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE _timescaledb_internal._hyper_1_33_chunk TO visitor;


--
-- Name: TABLE _hyper_1_34_chunk; Type: ACL; Schema: _timescaledb_internal; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE _timescaledb_internal._hyper_1_34_chunk TO visitor;


--
-- Name: TABLE _hyper_1_35_chunk; Type: ACL; Schema: _timescaledb_internal; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE _timescaledb_internal._hyper_1_35_chunk TO visitor;


--
-- Name: TABLE _hyper_1_36_chunk; Type: ACL; Schema: _timescaledb_internal; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE _timescaledb_internal._hyper_1_36_chunk TO visitor;


--
-- Name: TABLE _hyper_1_37_chunk; Type: ACL; Schema: _timescaledb_internal; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE _timescaledb_internal._hyper_1_37_chunk TO visitor;


--
-- Name: TABLE _hyper_1_38_chunk; Type: ACL; Schema: _timescaledb_internal; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE _timescaledb_internal._hyper_1_38_chunk TO visitor;


--
-- Name: TABLE _hyper_1_39_chunk; Type: ACL; Schema: _timescaledb_internal; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE _timescaledb_internal._hyper_1_39_chunk TO visitor;


--
-- Name: TABLE _hyper_1_3_chunk; Type: ACL; Schema: _timescaledb_internal; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE _timescaledb_internal._hyper_1_3_chunk TO visitor;


--
-- Name: TABLE _hyper_1_40_chunk; Type: ACL; Schema: _timescaledb_internal; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE _timescaledb_internal._hyper_1_40_chunk TO visitor;


--
-- Name: TABLE _hyper_1_41_chunk; Type: ACL; Schema: _timescaledb_internal; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE _timescaledb_internal._hyper_1_41_chunk TO visitor;


--
-- Name: TABLE _hyper_1_42_chunk; Type: ACL; Schema: _timescaledb_internal; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE _timescaledb_internal._hyper_1_42_chunk TO visitor;


--
-- Name: TABLE _hyper_1_43_chunk; Type: ACL; Schema: _timescaledb_internal; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE _timescaledb_internal._hyper_1_43_chunk TO visitor;


--
-- Name: TABLE _hyper_1_44_chunk; Type: ACL; Schema: _timescaledb_internal; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE _timescaledb_internal._hyper_1_44_chunk TO visitor;


--
-- Name: TABLE _hyper_1_45_chunk; Type: ACL; Schema: _timescaledb_internal; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE _timescaledb_internal._hyper_1_45_chunk TO visitor;


--
-- Name: TABLE _hyper_1_46_chunk; Type: ACL; Schema: _timescaledb_internal; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE _timescaledb_internal._hyper_1_46_chunk TO visitor;


--
-- Name: TABLE _hyper_1_47_chunk; Type: ACL; Schema: _timescaledb_internal; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE _timescaledb_internal._hyper_1_47_chunk TO visitor;


--
-- Name: TABLE _hyper_1_48_chunk; Type: ACL; Schema: _timescaledb_internal; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE _timescaledb_internal._hyper_1_48_chunk TO visitor;


--
-- Name: TABLE _hyper_1_49_chunk; Type: ACL; Schema: _timescaledb_internal; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE _timescaledb_internal._hyper_1_49_chunk TO visitor;


--
-- Name: TABLE _hyper_1_4_chunk; Type: ACL; Schema: _timescaledb_internal; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE _timescaledb_internal._hyper_1_4_chunk TO visitor;


--
-- Name: TABLE _hyper_1_50_chunk; Type: ACL; Schema: _timescaledb_internal; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE _timescaledb_internal._hyper_1_50_chunk TO visitor;


--
-- Name: TABLE _hyper_1_51_chunk; Type: ACL; Schema: _timescaledb_internal; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE _timescaledb_internal._hyper_1_51_chunk TO visitor;


--
-- Name: TABLE _hyper_1_52_chunk; Type: ACL; Schema: _timescaledb_internal; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE _timescaledb_internal._hyper_1_52_chunk TO visitor;


--
-- Name: TABLE _hyper_1_53_chunk; Type: ACL; Schema: _timescaledb_internal; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE _timescaledb_internal._hyper_1_53_chunk TO visitor;


--
-- Name: TABLE _hyper_1_54_chunk; Type: ACL; Schema: _timescaledb_internal; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE _timescaledb_internal._hyper_1_54_chunk TO visitor;


--
-- Name: TABLE _hyper_1_55_chunk; Type: ACL; Schema: _timescaledb_internal; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE _timescaledb_internal._hyper_1_55_chunk TO visitor;


--
-- Name: TABLE _hyper_1_56_chunk; Type: ACL; Schema: _timescaledb_internal; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE _timescaledb_internal._hyper_1_56_chunk TO visitor;


--
-- Name: TABLE _hyper_1_57_chunk; Type: ACL; Schema: _timescaledb_internal; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE _timescaledb_internal._hyper_1_57_chunk TO visitor;


--
-- Name: TABLE _hyper_1_58_chunk; Type: ACL; Schema: _timescaledb_internal; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE _timescaledb_internal._hyper_1_58_chunk TO visitor;


--
-- Name: TABLE _hyper_1_59_chunk; Type: ACL; Schema: _timescaledb_internal; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE _timescaledb_internal._hyper_1_59_chunk TO visitor;


--
-- Name: TABLE _hyper_1_5_chunk; Type: ACL; Schema: _timescaledb_internal; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE _timescaledb_internal._hyper_1_5_chunk TO visitor;


--
-- Name: TABLE _hyper_1_60_chunk; Type: ACL; Schema: _timescaledb_internal; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE _timescaledb_internal._hyper_1_60_chunk TO visitor;


--
-- Name: TABLE _hyper_1_61_chunk; Type: ACL; Schema: _timescaledb_internal; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE _timescaledb_internal._hyper_1_61_chunk TO visitor;


--
-- Name: TABLE _hyper_1_62_chunk; Type: ACL; Schema: _timescaledb_internal; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE _timescaledb_internal._hyper_1_62_chunk TO visitor;


--
-- Name: TABLE _hyper_1_63_chunk; Type: ACL; Schema: _timescaledb_internal; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE _timescaledb_internal._hyper_1_63_chunk TO visitor;


--
-- Name: TABLE _hyper_1_64_chunk; Type: ACL; Schema: _timescaledb_internal; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE _timescaledb_internal._hyper_1_64_chunk TO visitor;


--
-- Name: TABLE _hyper_1_65_chunk; Type: ACL; Schema: _timescaledb_internal; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE _timescaledb_internal._hyper_1_65_chunk TO visitor;


--
-- Name: TABLE _hyper_1_66_chunk; Type: ACL; Schema: _timescaledb_internal; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE _timescaledb_internal._hyper_1_66_chunk TO visitor;


--
-- Name: TABLE _hyper_1_67_chunk; Type: ACL; Schema: _timescaledb_internal; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE _timescaledb_internal._hyper_1_67_chunk TO visitor;


--
-- Name: TABLE _hyper_1_68_chunk; Type: ACL; Schema: _timescaledb_internal; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE _timescaledb_internal._hyper_1_68_chunk TO visitor;


--
-- Name: TABLE _hyper_1_69_chunk; Type: ACL; Schema: _timescaledb_internal; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE _timescaledb_internal._hyper_1_69_chunk TO visitor;


--
-- Name: TABLE _hyper_1_6_chunk; Type: ACL; Schema: _timescaledb_internal; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE _timescaledb_internal._hyper_1_6_chunk TO visitor;


--
-- Name: TABLE _hyper_1_70_chunk; Type: ACL; Schema: _timescaledb_internal; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE _timescaledb_internal._hyper_1_70_chunk TO visitor;


--
-- Name: TABLE _hyper_1_71_chunk; Type: ACL; Schema: _timescaledb_internal; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE _timescaledb_internal._hyper_1_71_chunk TO visitor;


--
-- Name: TABLE _hyper_1_72_chunk; Type: ACL; Schema: _timescaledb_internal; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE _timescaledb_internal._hyper_1_72_chunk TO visitor;


--
-- Name: TABLE _hyper_1_73_chunk; Type: ACL; Schema: _timescaledb_internal; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE _timescaledb_internal._hyper_1_73_chunk TO visitor;


--
-- Name: TABLE _hyper_1_7_chunk; Type: ACL; Schema: _timescaledb_internal; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE _timescaledb_internal._hyper_1_7_chunk TO visitor;


--
-- Name: TABLE _hyper_1_8_chunk; Type: ACL; Schema: _timescaledb_internal; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE _timescaledb_internal._hyper_1_8_chunk TO visitor;


--
-- Name: TABLE _hyper_1_9_chunk; Type: ACL; Schema: _timescaledb_internal; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE _timescaledb_internal._hyper_1_9_chunk TO visitor;


--
-- Name: TABLE devices; Type: ACL; Schema: app_public; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE app_public.devices TO visitor;


--
-- Name: SEQUENCE devices_id_seq; Type: ACL; Schema: app_public; Owner: -
--

GRANT SELECT,USAGE ON SEQUENCE app_public.devices_id_seq TO visitor;


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


--! Previous: -
--! Hash: sha1:121d1fa536a1a49dc1b1a10113d5e7b2fdfa0037

--- Schemas ---

-- Directly exposed
drop schema if exists app_public cascade;
create schema app_public;
comment on schema app_public is 'Core public interface and schema for GraphQL';

-- Indirectly exposed
drop schema if exists app_hidden cascade;
create schema app_hidden;
comment on schema app_hidden is 'User-accessible but private implementation details';

-- Not exposed
drop schema if exists app_private cascade;
create schema app_private;
comment on schema app_private is 'Private credentials accessible only to database owner';

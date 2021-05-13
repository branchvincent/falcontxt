--! Previous: sha1:121d1fa536a1a49dc1b1a10113d5e7b2fdfa0037
--! Hash: sha1:f93354162c9928415ff10c18efbb3ef715a09f14

--- RBAC ---

-- Revoke `public` role's default access, which all roles inherit
revoke all on schema public from public;
alter default privileges revoke all on sequences from public;
alter default privileges revoke all on functions from public;

-- Grant `owner` role full access
grant all on schema public to ":DATABASE_OWNER";

-- Grant `visitor` role access (insert and functions)
grant usage on schema public, app_public, app_hidden to ":DATABASE_VISITOR";
alter default privileges in schema public, app_public, app_hidden
    grant usage, select on sequences to ":DATABASE_VISITOR";
alter default privileges in schema public, app_public, app_hidden
    grant execute on functions to ":DATABASE_VISITOR";

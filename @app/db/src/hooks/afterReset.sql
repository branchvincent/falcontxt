begin;

-- Owner role
grant connect on database ":DATABASE_NAME" to ":DATABASE_OWNER";
grant all on database ":DATABASE_NAME" to ":DATABASE_OWNER";
alter schema public owner to ":DATABASE_OWNER";

-- Authenticator role
do $$ begin
   if not exists (select from pg_catalog.pg_roles where rolname = ':DATABASE_AUTHENTICATOR') then
      create role ":DATABASE_AUTHENTICATOR";
   end if;
end $$;
grant connect on database ":DATABASE_NAME" to ":DATABASE_AUTHENTICATOR";

-- Visitor role
do $$ begin
   if not exists (select from pg_catalog.pg_roles where rolname = ':DATABASE_VISITOR') then
      create role ":DATABASE_VISITOR";
   end if;
end $$;

-- Extensions
create extension if not exists pgcrypto with schema public;
create extension if not exists timescaledb with schema public;
create extension if not exists timescale_analytics with schema public;

commit;

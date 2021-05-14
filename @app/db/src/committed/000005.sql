--! Previous: sha1:2cf49657e3c79c24bf8a4e60d1f2c610811fd75e
--! Hash: sha1:5671012bde925eedaa3c1659151cb870cb35d4e0

drop type if exists app_public.metric cascade;
create type app_public.metric as (
  time timestamptz,
  count float,
  first float,
  last float,
  avg float,
  sum float,
  min float,
  max float
);

-- grant all on all functions in schema app_public to visitor;
grant create on schema app_public to ":DATABASE_VISITOR";

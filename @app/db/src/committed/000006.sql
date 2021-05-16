--! Previous: sha1:5671012bde925eedaa3c1659151cb870cb35d4e0
--! Hash: sha1:62dd22ec3ac716714894d84bf1fc1df970b8bbd8

ALTER TABLE app_public.metric_definitions
ADD description text;

comment on column app_public.metric_definitions.description is 'The description of the metric definition.';

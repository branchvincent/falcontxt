--! Previous: sha1:a74dc8ded75d5e7b7ceb325532c8000942aa32f7
--! Hash: sha1:77672d2ac143aefed94dc2517a137a0b0469471e

alter table app_public.facilities add column if not exists tags text ARRAY;
comment on column app_public.metric_definitions.units is 'The facility’s tags.';

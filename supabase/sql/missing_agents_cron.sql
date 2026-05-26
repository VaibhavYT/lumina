-- Run this after setting database config values for the project URL and a service role key.
-- Example:
-- alter database postgres set app.supabase_url = 'https://PROJECT_REF.supabase.co';
-- alter database postgres set app.service_role_key = 'SERVICE_ROLE_KEY';

select cron.unschedule('nightly-pattern-mining')
where exists (select 1 from cron.job where jobname = 'nightly-pattern-mining');

select cron.schedule(
  'nightly-pattern-mining',
  '0 18 * * *',
  $$
  select net.http_post(
    url := current_setting('app.supabase_url') || '/functions/v1/pattern-mining-agent',
    headers := ('{"Content-Type": "application/json", "Authorization": "Bearer ' || current_setting('app.service_role_key') || '"}')::jsonb,
    body := '{}'::jsonb
  ) as request_id;
  $$
);

select cron.unschedule('weekly-debrief-sunday')
where exists (select 1 from cron.job where jobname = 'weekly-debrief-sunday');

select cron.schedule(
  'weekly-debrief-sunday',
  '30 13 * * 0',
  $$
  select net.http_post(
    url := current_setting('app.supabase_url') || '/functions/v1/weekly-debrief-agent',
    headers := ('{"Content-Type": "application/json", "Authorization": "Bearer ' || current_setting('app.service_role_key') || '"}')::jsonb,
    body := '{}'::jsonb
  ) as request_id;
  $$
);

select cron.unschedule('morning-brief-daily')
where exists (select 1 from cron.job where jobname = 'morning-brief-daily');

select cron.schedule(
  'morning-brief-daily',
  '30 2 * * *',
  $$
  select net.http_post(
    url := current_setting('app.supabase_url') || '/functions/v1/morning-brief-agent',
    headers := ('{"Content-Type": "application/json", "Authorization": "Bearer ' || current_setting('app.service_role_key') || '"}')::jsonb,
    body := '{}'::jsonb
  ) as request_id;
  $$
);

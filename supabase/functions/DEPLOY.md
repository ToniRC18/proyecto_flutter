## Deploy

1. Install Supabase CLI if needed:
   `npm install -g supabase`
2. Login:
   `supabase login`
3. Link the local repo to the project:
   `supabase link --project-ref [PROJECT_REF]`
4. Deploy the Edge Function:
   `supabase functions deploy send-push-notification`
5. Verify the `FIREBASE_SERVICE_ACCOUNT` secret exists in the Supabase dashboard.
6. Run the trigger migration in Supabase SQL Editor:
   `supabase/migrations/202604220007_push_notification_triggers.sql`
7. For the cron job, run the `SELECT cron.schedule(...)` block from that migration in SQL Editor if you prefer to schedule it manually.

## Notes

- Never hardcode the Firebase private key in code. Keep it only in `FIREBASE_SERVICE_ACCOUNT`.
- If your project does not expose `app.settings.supabase_url` or `app.settings.service_role_key`, replace the fallback placeholders in the migration before executing it.

import { createClient, SupabaseClient } from "npm:@supabase/supabase-js@2";

export const supabase: SupabaseClient = createClient(
  "https://mbtegbgsvxbefyzyxlyr.supabase.co",
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1idGVnYmdzdnhiZWZ5enl4bHlyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MzA4NDg4NCwiZXhwIjoyMDY4NjYwODg0fQ.k3YwJV90ZzV_6WcB9_62x8AiFueTFzi3lR1dxPNEhZ0",
);

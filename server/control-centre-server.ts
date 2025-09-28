import { Context, Hono } from "hono";
import { cors } from "hono/cors";
import { createClient, SupabaseClient } from "npm:@supabase/supabase-js@2";
import { Utils } from "./utils.ts";
import { AppLogger } from "./core/app_logger.ts";

const app = new Hono();
app.use("/v1/*", cors());

const supabase: SupabaseClient = createClient(
  "https://mbtegbgsvxbefyzyxlyr.supabase.co",
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1idGVnYmdzdnhiZWZ5enl4bHlyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MzA4NDg4NCwiZXhwIjoyMDY4NjYwODg0fQ.k3YwJV90ZzV_6WcB9_62x8AiFueTFzi3lR1dxPNEhZ0",
);

const logger = new AppLogger("control-center-logs.log");
const utils = new Utils(supabase, logger);

app.get("/health", (context: Context) => {
  return context.json({ message: "Stable v1" });
});

app.post("/v1/view-password", async (context: Context) => {
  logger.log("Request received ...");
  const { id } = await context.req.json();
  try {
    const data = await utils.fetchUser(id);
    if (data === null) {
      return context.json({ messsage: "User is not registered" }, 200);
    }
    if (data?.password === null) {
      return context.json({ messsage: "No password has been set yet" }, 200);
    }
    return context.json({
      password: data?.password,
    }, 200);
  } catch (_) {
    return context.json({ message: `Internal Server error` }, 500);
  }
});

app.post("/v1/set-password", async (context: Context) => {
  const { id } = await context.req.json();
  try {
    const status = await utils.updateUser(id, {
      password: "115$104$111$112$64$49$50$51",
    });
    return context.json({
      message: status.toString(),
    }, 200);
  } catch (_) {
    return context.json({
      message: "Internal Server Error",
    }, 500);
  }
});

Deno.serve({
  port: 8001,
  // disable ssl for localhost
  // cert: Deno.readTextFileSync(
  //   "/etc/letsencrypt/live/apis.billingfast.com/fullchain.pem",
  // ),
  // key: Deno.readTextFileSync(
  //   "/etc/letsencrypt/live/apis.billingfast.com/privkey.pem",
  // ),
}, app.fetch);

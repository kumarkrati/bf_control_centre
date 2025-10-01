import { Hono } from "hono";
import { supabase } from "./core/supabase-client.ts";
import { DbOps } from "./core/db-ops.ts";
import { AppLogger } from "./core/app_logger.ts";
import { initV1 as initv1 } from "./v1/init.ts";

const app = new Hono();
const logger = new AppLogger("control-center-logs.log");
const dbops = new DbOps(supabase, logger);

// end-points initialization
initv1(app, logger, dbops);

// start serve at this point
Deno.serve({
  port: 8001,
  cert: Deno.readTextFileSync(
    "/etc/letsencrypt/live/apis.billingfast.com/fullchain.pem",
  ),
  key: Deno.readTextFileSync(
    "/etc/letsencrypt/live/apis.billingfast.com/privkey.pem",
  ),
}, app.fetch);

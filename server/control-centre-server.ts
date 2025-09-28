import { Hono } from "hono";
import { supabase } from "./core/supabase-client.ts";
import { DbOps } from "./core/db-ops.ts";
import { AppLogger } from "./core/app_logger.ts";
import { init } from "./v1/init.ts";
import { viewPassword } from "./v1/view-password.ts";
import { setPassword } from "./v1/set-password.ts";
import { reassignInvoiceNo } from "./v1/reassign-invoice-no.ts";
import { health } from "./v1/health.ts";
import { authorize } from "./v1/authorize.ts";

const app = new Hono();
const logger = new AppLogger("control-center-logs.log");
const dbops = new DbOps(supabase, logger);

// end-points initialization
init(app)
health(app)
viewPassword(app, logger, dbops)
setPassword(app, logger, dbops)
reassignInvoiceNo(app, logger, dbops)
authorize(app, logger, dbops)

// start serve at this point
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

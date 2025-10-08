import { cors } from "hono/cors";
import { Hono } from "hono";
import { AppLogger } from "../core/app_logger.ts";
import { DbOps } from "../core/db-ops.ts";
import { authorize } from "./authorize.ts";
import { health } from "./health.ts";
import { reassignInvoiceNo } from "./reassign-invoice-no.ts";
import { setPassword } from "./set-password.ts";
import { viewPassword } from "./view-password.ts";
import { restoreProduct } from "./restore-products.ts";
import { subscription } from "./subscription.ts";
import { createAccount } from "./create-account.ts";
import { downloadUsers } from "./download-users.ts";

export function initV1(app: Hono, logger: AppLogger, dbops: DbOps) {
  app.use("/v1/*", cors());
  health(app);
  viewPassword(app, logger, dbops);
  setPassword(app, logger, dbops);
  reassignInvoiceNo(app, logger, dbops);
  restoreProduct(app, logger, dbops);
  authorize(app, logger, dbops);
  subscription(app, logger, dbops);
  createAccount(app, logger, dbops);
  downloadUsers(app, logger, dbops);
}

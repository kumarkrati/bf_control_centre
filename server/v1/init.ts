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
import { liveNewUsers } from "./live_new_users.ts";
import { generateInvoice } from "./generate-invoice.ts";
import { fetchInvoices } from "./fetch-invoices.ts";
import { fetchPendingReceipts } from "./fetch-pending-receipts.ts";

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
  liveNewUsers(app, logger, dbops);
  generateInvoice(app, logger, dbops);
  fetchInvoices(app, logger, dbops);
  fetchPendingReceipts(app, logger, dbops);
}

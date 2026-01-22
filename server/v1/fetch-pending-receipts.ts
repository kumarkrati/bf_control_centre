// deno-lint-ignore-file no-explicit-any
import { Context, Hono } from "hono";
import { AppLogger } from "../core/app_logger.ts";
import { DbOps } from "../core/db-ops.ts";
import { encrypted } from "../encryption/encrypted-request.ts";

export function fetchPendingReceipts(app: Hono, logger: AppLogger, dbops: DbOps) {
  app.post(
    "/v1/fetch-pending-receipts",
    encrypted(async (json: any, context: Context) => {
      const { startDate, endDate } = json;
      logger.log(`Fetching pending receipts from ${startDate} to ${endDate}`);

      const result = await dbops.fetchPendingReceipts(startDate, endDate);

      if (result === null) {
        return context.json({ message: "failed" }, 500);
      }
      return context.json({ message: "success", users: result }, 200);
    }, logger),
  );
}

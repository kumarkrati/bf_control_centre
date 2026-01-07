// deno-lint-ignore-file no-explicit-any
import { Context, Hono } from "hono";
import { AppLogger } from "../core/app_logger.ts";
import { DbOps } from "../core/db-ops.ts";
import { encrypted } from "../encryption/encrypted-request.ts";

export function subscription(app: Hono, logger: AppLogger, dbops: DbOps) {
  app.post(
    "/v1/subscription",
    encrypted(async (json: any, context: Context) => {
      const { id, subDays, subPlan, updatedBy, subStartedDate } = json;
      logger.log("Updating subscription ...");
      const status = await dbops.updateSubscription(
        id,
        subDays,
        subPlan,
        updatedBy,
        subStartedDate,
      );
      if (status == 1) {
        return context.json({ message: status }, 401);
      } else if (status == 2) {
        return context.json({ message: status }, 404);
      }
      return context.json({ message: status }, 200);
    }, logger),
  );
}

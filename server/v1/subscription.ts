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
      return context.json({ message: status }, 200);
    }, logger),
  );
}

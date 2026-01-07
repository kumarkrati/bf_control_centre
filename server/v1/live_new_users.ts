// deno-lint-ignore-file
import { Context, Hono } from "hono";
import { AppLogger } from "../core/app_logger.ts";
import { DbOps } from "../core/db-ops.ts";
import { encrypted } from "../encryption/encrypted-request.ts";

export function liveNewUsers(app: Hono, logger: AppLogger, dbops: DbOps) {
  // Get today's new users
  app.post(
    "/v1/live-new-users",
    encrypted(async (json: any, context: Context) => {
      logger.log("Fetching today's new users ...");

      const users = await dbops.getTodaysNewUsers();

      return context.json({
        message: users,
      }, 200);
    }, logger),
  );

  // Assign or update a sales staff for a user
  app.post(
    "/v1/assign-sales-staff",
    encrypted(async (json: any, context: Context) => {
      const { userId, userName, userAddress, assignedTo, notes } = json;
      logger.log(`Assigning sales staff for user: ${userId}`);

      const result = await dbops.assignSalesStaff(userId, userName, userAddress, assignedTo, notes);

      if (result === 0) {
        return context.json({ message: "success" }, 200);
      }
      return context.json({ message: "failed" }, 500);
    }, logger),
  );
}

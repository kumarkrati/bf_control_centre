import { Context, Hono } from "hono";
import { AppLogger } from "../core/app_logger.ts";
import { DbOps } from "../core/db-ops.ts";
import { encrypted } from "../encryption/encrypted-request.ts";

export function createAccount(app: Hono, logger: AppLogger, dbops: DbOps) {
  app.post(
    "/v1/create-account",
    encrypted(async (json: any, context: Context) => {
      const { id, mobile } = json;
      logger.log("Updating account ...");
      const status = await dbops.createAccount(
        id,
        mobile,
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

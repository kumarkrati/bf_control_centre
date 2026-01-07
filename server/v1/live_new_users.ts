// deno-lint-ignore-file
import { Context, Hono } from "hono";
import { AppLogger } from "../core/app_logger.ts";
import { DbOps } from "../core/db-ops.ts";
import { encrypted } from "../encryption/encrypted-request.ts";

export function liveNewUsers(app: Hono, logger: AppLogger, dbops: DbOps) {
  app.post(
    "/v1/live-new-users",
    encrypted(async (json: any, context: Context) => {
      logger.log("Request received ...");
      const { id } = json;
      
      return context.json({
      }, 200);
    }, logger),
  );
}

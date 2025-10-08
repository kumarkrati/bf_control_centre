// deno-lint-ignore-file
import { Context, Hono } from "hono";
import { AppLogger } from "../core/app_logger.ts";
import { DbOps } from "../core/db-ops.ts";
import { encrypted } from "../encryption/encrypted-request.ts";

export function downloadUsers(app: Hono, logger: AppLogger, dbops: DbOps) {
  app.post(
    "/v1/download-users",
    encrypted(async (json: any, context: Context) => {
      const { start, end } = json;
      logger.log(`fetching downloaded users list ...`)
      const data = await dbops.getDownloadedUsers(start, end);
      logger.log(`fetched downloaded users list: ${data ? "yes" : "no"}`)
      if (!data) {
        logger.log('failed to fetch ...')
        return context.json({ message: "Internal error has occurred." }, 500);
      }
      logger.log(`sending list to client ...`)
      return context.json({ message: data }, 200);
    }, logger),
  );
}

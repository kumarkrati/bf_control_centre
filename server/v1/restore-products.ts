import { Hono } from "hono";
import { AppLogger } from "../core/app_logger.ts";
import { DbOps } from "../core/db-ops.ts";
import { encrypted } from "../encryption/encrypted-request.ts";
import { Context } from "node:vm";

export function restoreProduct(app: Hono, logger: AppLogger, dbops: DbOps) {
  app.post(
    "/v1/restore-product",
    // deno-lint-ignore no-explicit-any
    encrypted(async (json: any, context: Context) => {
      const { id } = json;
      logger.log(`restoring products ...`);
      const status = await dbops.restoreProduct(id);
      return context.json({ message: status }, 200);
    }, logger),
  );
}

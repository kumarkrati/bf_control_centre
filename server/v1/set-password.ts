// deno-lint-ignore-file
import { Context, Hono } from "hono";
import { AppLogger } from "../core/app_logger.ts";
import { DbOps } from "../core/db-ops.ts";
import { encrypted } from "../encryption/encrypted-request.ts";

export function setPassword(app: Hono, logger: AppLogger, dbops: DbOps) {
  app.post(
    "/v1/set-password",
    encrypted(async (json: any, context: Context) => {
      const { id } = json;
      const status = await dbops.updateUser(id, {
        "password": "115$104$111$112$64$49$50$51",
      });
      return context.json({
        message: status,
      }, 200);
    }, logger),
  );
}

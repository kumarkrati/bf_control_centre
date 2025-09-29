// deno-lint-ignore-file
import { Context, Hono } from "hono";
import { AppLogger } from "../core/app_logger.ts";
import { DbOps } from "../core/db-ops.ts";
import { encrypted } from "../encryption/encrypted-request.ts";

export function reassignInvoiceNo(app: Hono, logger: AppLogger, dbops: DbOps) {
  app.post(
    "/v1/reassing-invoice",
    encrypted(async (json: any, context: Context) => {
      const { id } = json;
      const { error } = await dbops.rpc("reassign_invoice_no", {
        p_userid: id,
      });
      if (error) {
        logger.log(`"Error occurred in setting invoice no.: ${error}`);
        return context.json({
          message: "Internal Server Error",
        }, 500);
      }
      return context.json({ message: "updated invoice number" }, 200);
    }, logger),
  );
}

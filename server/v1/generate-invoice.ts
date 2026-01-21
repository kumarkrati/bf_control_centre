// deno-lint-ignore-file no-explicit-any
import { Context, Hono } from "hono";
import { AppLogger } from "../core/app_logger.ts";
import { DbOps } from "../core/db-ops.ts";
import { encrypted } from "../encryption/encrypted-request.ts";

export function generateInvoice(app: Hono, logger: AppLogger, dbops: DbOps) {
  app.post(
    "/v1/generate-invoice",
    encrypted(async (json: any, context: Context) => {
      const { phone, planType, planDuration, invoiceDate, gstin, address, businessName, amount } = json;
      logger.log(`Generating invoice for phone: ${phone}, amount: ${amount}`);

      const result = await dbops.generateInvoice(
        phone,
        planType,
        planDuration,
        invoiceDate,
        gstin || null,
        address || null,
        businessName || null,
        amount,
      );

      if (result.status === 1) {
        return context.json({ message: "failed" }, 500);
      } else if (result.status === 2) {
        return context.json({ message: "noRef" }, 404);
      }
      return context.json({ message: "success", invoice: result.invoice }, 200);
    }, logger),
  );
}

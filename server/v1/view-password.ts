// deno-lint-ignore-file
import { Context, Hono } from "hono";
import { AppLogger } from "../core/app_logger.ts";
import { DbOps } from "../core/db-ops.ts";
import { encrypted } from "../encryption/encrypted-request.ts";

export function viewPassword(app: Hono, logger: AppLogger, dbops: DbOps) {
  app.post(
    "/v1/view-password",
    encrypted(async (json: any, context: Context) => {
      logger.log("Request received ...");
      const { id } = json;
      const data = await dbops.fetchUser(id);
      if (data === null) {
        logger.log("User is not registered");
        return context.json({ messsage: "User is not registered" }, 200);
      }
      if (!data?.password) {
        logger.log("No password has been set yet");
        return context.json(
          { messsage: "No password has been set yet" },
          200,
        );
      }
      logger.log("Sending encrypted password ...");
      return context.json({
        password: data?.password,
      }, 200);
    }, logger),
  );
}

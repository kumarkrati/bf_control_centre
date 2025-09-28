// deno-lint-ignore-file
import { Context, Handler } from "hono";
import * as KeyValidator from "./key_validator.ts";
import { AppLogger } from "../core/app_logger.ts";

export interface BaseRequestPayload {
  key: string; // request is coming from our app
  credentials: any; // request is coming from the authorized user
  id: string; // request on object
}

export function encrypted(
  handler: any,
  logger: AppLogger,
  tag: string = "stage-2-request",
): Handler {
  return async (context: Context) => {
    logger.log(`processing ${tag} request ...`);
    const json = await context.req.json();
    const request: BaseRequestPayload = json;
    if (!KeyValidator.validate(request.key, request.id, logger)) {
      return context.json({ messsage: "Invalid request" }, 401);
    }
    if (tag === "stage-2-request") {
      const username = request.credentials["username"];
      const token = request.credentials["token"];
      const tokens = JSON.parse(
        Deno.readTextFileSync("./.storage/tokens.json"),
      );
      if (tokens[username] !== token) {
        logger.error(`Invalid token ${token} by ${username}`);
        return context.json({ messsage: "Unauthorized" }, 401);
      }
      // TODO: Validate phone number [id]
    }
    try {
      return await handler(json, context);
    } catch (e) {
      logger.error(`Request ran into error: ${e} for payload: ${json}`);
      throw Error(`${e}`);
    }
  };
}

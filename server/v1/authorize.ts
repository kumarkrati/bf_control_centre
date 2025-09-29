// deno-lint-ignore-file
import { Context, Hono } from "hono";
import { AppLogger } from "../core/app_logger.ts";
import { DbOps } from "../core/db-ops.ts";
import { encrypted } from "../encryption/encrypted-request.ts";
import { randomUUID } from "node:crypto";

export function authorize(app: Hono, logger: AppLogger, _: DbOps) {
  app.post(
    "/v1/authorize",
    encrypted(
      (json: any, context: Context) => {
        const { username, password } = json;
        const users = JSON.parse(
          Deno.readTextFileSync("./.storage/users.json"),
        );
        let isCredentialCorrect: boolean = false;
        let name = "";
        let role = "";
        for (const user of users) {
          if (user["username"] === username) {
            if (user["password"] !== password) {
              break;
            } else {
              isCredentialCorrect = true;
              role = user['role'];
              name = user['name'];
              break;
            }
          }
        }
        if (!isCredentialCorrect) {
          logger.warning(`Invalid credentials: ${username} : ${password}`);
          return context.json({ "message": "Invalid credentials." }, 401);
        } else {
          // assign access token
          const token = randomUUID();
          const tokens = JSON.parse(
            Deno.readTextFileSync("./.storage/tokens.json"),
          );
          tokens[username] = token;
          Deno.writeTextFileSync(
            "./.storage/tokens.json",
            JSON.stringify(tokens),
          );
          logger.log(`Access Granted: ${username} : ${token}`);
          return context.json({ "token": token, "role": role, "name": name }, 200);
        }
      },
      logger,
      "stage-1-request",
    ),
  );
}

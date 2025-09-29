import { Hono, Context } from "hono";

export function health(app: Hono) {
  app.get("/v1/health", (context: Context) => {
    console.log(`sending health ...`);
    return context.json({ message: "Stable v1" });
  });
}

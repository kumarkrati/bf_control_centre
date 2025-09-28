import { Hono, Context } from "hono";

export function health(app: Hono) {
  app.get("/v1/health", (context: Context) => {
    return context.json({ message: "Stable v1" });
  });
}

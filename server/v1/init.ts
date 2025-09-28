import { cors } from "hono/cors";
import { Hono } from "hono";

export function init(app: Hono) {
    app.use("/v1/*", cors());
}

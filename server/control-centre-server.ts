import { Context, Hono } from "hono";
import { cors } from "hono/cors";
import { supabase } from "./core/supabase-client.ts";
import { Utils } from "./utils.ts";
import { AppLogger } from "./core/app_logger.ts";

const app = new Hono();
const logger = new AppLogger("control-center-logs.log");
const utils = new Utils(supabase, logger);

app.use("/v1/*", cors());
app.get("/v1/health", (context: Context) => {
  return context.json({ message: "Stable v1" });
});

app.post("/v1/view-password", async (context: Context) => {
  logger.log("Request received ...");
  const { id } = await context.req.json();
  try {
    const data = await utils.fetchUser(id);
    if (data === null) {
      return context.json({ messsage: "User is not registered" }, 200);
    }
    if (data?.password === null) {
      return context.json({ messsage: "No password has been set yet" }, 200);
    }
    return context.json({
      password: data?.password,
    }, 200);
  } catch (error) {
    logger.log(`"Error occurred at view-password: ${error}`);
    return context.json({ message: `Internal Server error` }, 500);
  }
});

app.post("/v1/set-password", async (context: Context) => {
  const { id } = await context.req.json();
  try {
    const status = await utils.updateUser(id, {
      "password": "115$104$111$112$64$49$50$51",
    });
    return context.json({
      message: status.toString(),
    }, 200);
  } catch (error) {
    logger.log(`"Error occurred at set-password: ${error}`);
    return context.json({
      message: "Internal Server Error",
    }, 500);
  }
});


app.post("/v1/reassing-invoice" , async (context: Context)=>{
  const {id} = await context.req.json();
  const {error} = await supabase.rpc("reassign_invoice_no" , {
    p_userid : id
  })
  if (error) {
    logger.log(`"Error occurred in setting invoice no.: ${error}`);
    return context.json({
      message: "Internal Server Error",
    }, 500);
  }

  return context.json({message:"updated invoice number"})
})


Deno.serve({
  port: 8001,
  // disable ssl for localhost
  // cert: Deno.readTextFileSync(
  //   "/etc/letsencrypt/live/apis.billingfast.com/fullchain.pem",
  // ),
  // key: Deno.readTextFileSync(
  //   "/etc/letsencrypt/live/apis.billingfast.com/privkey.pem",
  // ),
}, app.fetch);


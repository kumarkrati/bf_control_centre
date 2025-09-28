import { Hono } from "https://deno.land/x/hono@v3.12.11/mod.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.0";
const app = new Hono();

const KEY = "!hu3~1_!i:wt>nzQ^BPbQSZt;6.c-8";
const supabase = createClient(
  "https://mbtegbgsvxbefyzyxlyr.supabase.co",
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1idGVnYmdzdnhiZWZ5enl4bHlyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MzA4NDg4NCwiZXhwIjoyMDY4NjYwODg0fQ.k3YwJV90ZzV_6WcB9_62x8AiFueTFzi3lR1dxPNEhZ0",
  {
    global: {
      headers: {
        "Prefer": "statement-timeout=180000",
      },
    },
  },
);
app.get("/" , (context)=> context.json({message:"server started"}))
app.post("/v1/view-password" , async (context)=>{
    const {phoneNumer} = await context.req.json();
    try {
        const {data , error} = await supabase.from('users').select(`password`).eq('mobile', phoneNumer).single();
        if(error) {
            if (error.code === 'PGRST116') {
                return context.json({ message: "User not found" }, 404);
            }
        } 
        if(data['password'] == null){
            return context.json({messsage:"No password set"} , 200) 
        }
        return context.json({messsage:"password fetched successfully" , data:data} , 200) 
    } catch (error) {
        return context.json({message:`Server error ${error}`} , 500)
    }

})

app.post("/v1/set-password" , async (context)=>{
    const {phoneNumer} = await context.req.json();
    try {
        const {data , error} = await supabase.from('users').select("*").eq('id' , phoneNumer).single();
        if(error) {
            if (error.code === 'PGRST116') {
                return context.json({ message: "User not found" }, 404);
            }
        }

        if(data){
            const {data , error} = await supabase.from('users').update({password:"115$104$111$112$64$49$50$51"}).eq('id' , phoneNumer).select();
            if(error) {
            if (error) {
                return context.json({ message: "Error in updating" }, 404);
            }
            return context.json({ message:"Updated successfully", data: data });
            }
        }

    } catch (error) {
        console.log(`Error occurred: ${error}`);
        return context.json({ 
                message: "Database error", 
                error: error 
            }, 500);
    }


})


Deno.serve(app.fetch);
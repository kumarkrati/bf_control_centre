// deno-lint-ignore-file no-explicit-any

import { SupabaseClient } from "npm:@supabase/supabase-js@2";
import { AppLogger } from "./app_logger.ts";

export enum UpdateStatus {
  failed,
  noRef,
  success,
}

export enum RestoreProductStatus {
  RESTORED,
  FAILED,
}

export class DbOps {
  supabase: SupabaseClient;
  logger: AppLogger;

  constructor(supabase: SupabaseClient, logger: AppLogger) {
    this.supabase = supabase;
    this.logger = logger;
  }

  async fetchUser(id: string): Promise<Record<string, any> | null> {
    this.logger.log(`Fetching user: ${id}`);
    return (await this.supabase.from("users").select().eq("id", id)
      .maybeSingle())?.data;
  }

  async updateUser(id: string, data: any): Promise<UpdateStatus> {
    try {
      if (!(await this.fetchUser(id))) {
        this.logger.warning(`No user with id: ${id}`);
        return UpdateStatus.noRef;
      }
      const { error } = await this.supabase.from("users").update(data).eq(
        "id",
        id,
      );
      if (error) {
        this.logger.error(`Failed to update data for user: ${id}`);
        return UpdateStatus.failed;
      } else {
        this.logger.log(
          `Success updating user id=${id} with data=${JSON.stringify(data)}`,
        );
        return UpdateStatus.success;
      }
    } catch (error) {
      this.logger.error(`Exception updateUser(): ${error}`);
      return UpdateStatus.failed;
    }
  }

  async rpc(id: string, data: any): Promise<any> {
    return await this.supabase.rpc(id, data);
  }

  async restoreProduct(id: string): Promise<RestoreProductStatus> {
    try {
      if (!(await this.fetchUser(id))) {
        this.logger.warning(`No user with id: ${id}`);
        return RestoreProductStatus.FAILED;
      }

      const { error } = await this.supabase.from("inventory").update({
        status: "Unverified",
      }).eq("userid", id).eq("status", "Deleted");
      if (error) {
        return RestoreProductStatus.FAILED;
      }
      return RestoreProductStatus.RESTORED;
    } catch (error) {
      this.logger.error(`Exception restoreProduct(): ${error}`);
      return RestoreProductStatus.FAILED;
    }
  }
}

// deno-lint-ignore-file no-explicit-any

import { SupabaseClient } from "npm:@supabase/supabase-js@2";
import { AppLogger } from "./core/app_logger.ts";

export enum UpdateStatus {
  failed,
  noRef,
  success,
}

export class Utils {
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
        this.logger.log(`No user with id: ${id}`);
        return UpdateStatus.noRef;
      }
      const { error } = await this.supabase.from("users").update(data).eq(
        "id",
        id,
      );
      if (error) {
        this.logger.log(`Failed to update data for user: ${id}`);
        return UpdateStatus.failed;
      } else {
        return UpdateStatus.success;
      }
    } catch (error) {
      this.logger.error(`Exception updateUser(): ${error}`);
      return UpdateStatus.failed;
    }
  }
}

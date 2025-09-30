// deno-lint-ignore-file no-explicit-any

import { SupabaseClient } from "npm:@supabase/supabase-js@2";
import { AppLogger } from "./app_logger.ts";

export enum QueryExecutionStatus {
  failed,
  noRef,
  success,
}

export enum RestoreProductStatus {
  restored,
  failed,
  noRef,
}

export enum SubscriptionStatus {
  success,
  failed,
  noRef,
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

  async updateUser(id: string, data: any): Promise<QueryExecutionStatus> {
    try {
      if (!(await this.fetchUser(id))) {
        this.logger.warning(`No user with id: ${id}`);
        return QueryExecutionStatus.noRef;
      }
      const { error } = await this.supabase.from("users").update(data).eq(
        "id",
        id,
      );
      if (error) {
        this.logger.error(`Failed to update data for user: ${id}`);
        return QueryExecutionStatus.failed;
      } else {
        this.logger.log(
          `Success updating user id=${id} with data=${JSON.stringify(data)}`,
        );
        console.log(QueryExecutionStatus.failed.toString());
        return QueryExecutionStatus.success;
      }
    } catch (error) {
      this.logger.error(`Exception updateUser(): ${error}`);
      return QueryExecutionStatus.failed;
    }
  }

  async updateSubscription(
    id: string,
    subdays: number,
    subplan: string,
    updatedBy: string,
    subStartedDate: string,
  ): Promise<SubscriptionStatus> {
    try {
      if (!(await this.fetchUser(id))) {
        this.logger.warning(`No user with id: ${id}`);
        return SubscriptionStatus.noRef;
      }
      const { error } = await this.supabase.from("subscriptions").update({
        subdays: subdays,
        subplan: subplan === "LITE" ? "LITE" : "PREMIUM",
        isultra: subplan === "ULTRA",
        substartedat: subStartedDate,
        isontrail: false,
      }).eq("id", `${id}-subscriptions`);
      if (error) {
        this.logger.error(`Failed to update subscription for id: ${id}`);
        return SubscriptionStatus.failed;
      } else {
        this.logger.log(
          `Success updating subscription for id=${id} by ${updatedBy}`,
        );
        return SubscriptionStatus.success;
      }
    } catch (error) {
      this.logger.error(`Exception updateSubscription(): ${error}`);
      return SubscriptionStatus.failed;
    }
  }

  async rpc(id: string, data: any): Promise<any> {
    return await this.supabase.rpc(id, data);
  }

  async restoreProduct(id: string): Promise<RestoreProductStatus> {
    try {
      if (!(await this.fetchUser(id))) {
        this.logger.warning(`No user with id: ${id}`);
        return RestoreProductStatus.noRef;
      }

      const { error } = await this.supabase.from("inventory").update({
        status: "Unverified",
      }).eq("userid", id).eq("status", "Deleted");
      if (error) {
        return RestoreProductStatus.failed;
      }
      return RestoreProductStatus.restored;
    } catch (error) {
      this.logger.error(`Exception restoreProduct(): ${error}`);
      return RestoreProductStatus.failed;
    }
  }
}

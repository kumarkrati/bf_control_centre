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

export enum CreateAccountStatus {
  success,
  failed,
  alreadyRegistered,
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

  async createAccount(
    id: string,
    mobile: string,
  ): Promise<CreateAccountStatus> {
    try {
      if ((await this.fetchUser(id))) {
        this.logger.warning(`User already with id: ${id}`);
        return CreateAccountStatus.alreadyRegistered;
      }
      const { error } = await this.supabase.from("users").insert({
        id: id,
        mobile: mobile,
        active: 1,
        password: "115$104$111$112$64$49$50$51",
      });
      if (error) {
        this.logger.error(`Failed to create account: ${id}`);
        return CreateAccountStatus.failed;
      } else {
        this.logger.log(
          `Success creating user id=${id}`,
        );
        return CreateAccountStatus.success;
      }
    } catch (error) {
      this.logger.error(`Exception createAccount(): ${error}`);
      return CreateAccountStatus.failed;
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
        trailsheetshown: true,
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

  async getDownloadedUsers(start: string, end: string): Promise<any> {
    try {
      const timeGapInMs = Date.parse(end) - Date.parse(start);
      const timeGapInHours = ((timeGapInMs / 1000) / 60) / 60;
      const timeGapInDays = timeGapInHours / 24;
      this.logger.log(`Duration: ${timeGapInDays} days`);
      if (timeGapInDays >= 32) {
        this.logger.warning(
          `User attempted to download list of ${timeGapInDays} days, request denied.`,
        );
        return null;
      }
      this.logger.log(`timeline: ${start} - ${end}`);
      const { data, error } = await this.supabase.from("users").select(
        "mobile, name, shop",
      ).gte("created_at", start).lte("created_at", end);
      if (error) {
        this.logger.error(`${error}`);
        return null;
      }
      // filter duplicate [mobile]
      const seenMobiles: string[] = [];
      const distinctData: any[] = [];
      for (const doc of data) {
        if (seenMobiles.includes(doc["mobile"])) {
          continue;
        }
        distinctData.push(doc);
      }
      this.logger.log(`Got user count: ${distinctData.length}`);
      return distinctData;
    } catch (error) {
      this.logger.error(`Exception getDownloadedUsers(): ${error}`);
      return RestoreProductStatus.failed;
    }
  }
}

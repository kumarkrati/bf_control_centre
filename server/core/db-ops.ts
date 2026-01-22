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

  async getTodaysNewUsers(): Promise<any[]> {
    try {
      const date = new Date();
      const today = `${date.getFullYear()}-${
        String(date.getMonth() + 1).padStart(2, "0")
      }-${String(date.getDate()).padStart(2, "0")}`;

      this.logger.log(`Fetching users for date: ${today}`);

      // Get all users created today
      const { data: users, error } = await this.supabase
        .from("users")
        .select("id, mobile, name, shop, created_at")
        .gte("created_at", `${today} 00:00:00`)
        .lte("created_at", `${today} 23:59:59`);

      if (error) {
        this.logger.error(`Error fetching today's users: ${error.message}`);
        return [];
      }

      if (!users || users.length === 0) {
        return [];
      }

      // Filter duplicates by mobile
      const seenMobiles: string[] = [];
      const distinctUsers: any[] = [];
      for (const user of users) {
        if (seenMobiles.includes(user.mobile)) {
          continue;
        }
        seenMobiles.push(user.mobile);
        distinctUsers.push(user);
      }

      // Fetch assignment status for each user from billingfastsalesstaffassignies
      const usersWithAssignment = await Promise.all(
        distinctUsers.map(async (user) => {
          const { data: assignment } = await this.supabase
            .from("billingfastsalesstaffassignies")
            .select("*")
            .eq("id", user.id)
            .maybeSingle();

          return {
            ...user,
            assignedTo: assignment?.assignedto || null,
            notes: assignment?.notes || null,
            isAssigned: !!assignment,
          };
        }),
      );

      this.logger.log(`Found ${usersWithAssignment.length} new users today`);
      return usersWithAssignment;
    } catch (error) {
      this.logger.error(`Exception getTodaysNewUsers(): ${error}`);
      return [];
    }
  }

  async assignSalesStaff(
    userId: string,
    userName: string,
    userAddress: string,
    assignedTo: string,
    notes: string,
  ): Promise<number> {
    try {
      // Check if assignment already exists
      const { data: existing } = await this.supabase
        .from("billingfastsalesstaffassignies")
        .select("id")
        .eq("id", userId)
        .maybeSingle();

      if (existing) {
        // Update existing assignment
        const { error } = await this.supabase
          .from("billingfastsalesstaffassignies")
          .update({
            name: userName,
            address: userAddress,
            assignedto: assignedTo,
            notes: notes,
          })
          .eq("id", userId);

        if (error) {
          this.logger.error(`Error updating assignment: ${error.message}`);
          return 1;
        }
      } else {
        // Insert new assignment
        const { error } = await this.supabase
          .from("billingfastsalesstaffassignies")
          .insert({
            id: userId,
            name: userName,
            address: userAddress,
            assignedto: assignedTo,
            notes: notes,
          });

        if (error) {
          this.logger.error(`Error inserting assignment: ${error.message}`);
          return 1;
        }
      }

      this.logger.log(`Sales staff assigned for user: ${userId}`);
      return 0;
    } catch (error) {
      this.logger.error(`Exception assignSalesStaff(): ${error}`);
      return 1;
    }
  }

  async generateInvoice(
    phone: string,
    planType: string,
    planDuration: number,
    invoiceDate: string,
    gstin: string | null,
    address: string | null,
    businessName: string | null,
    amount: number, // Final amount in paisa
  ): Promise<{ status: number; invoice: any }> {
    try {
      // Check if user exists
      if (!(await this.fetchUser(phone))) {
        this.logger.warning(`No user with id: ${phone}`);
        return { status: 2, invoice: null };
      }

      // Check if phone is an Indian number (starts with +91 or is 10 digits)
      const isIndianNumber = phone.startsWith("+91") ||
        phone.startsWith("91") ||
        (phone.length === 10 && /^[6-9]\d{9}$/.test(phone));

      // Calculate base amount
      // For Indian numbers: baseAmount = amount / 1.18 (reverse 18% GST)
      // For non-Indian numbers: baseAmount = amount (no tax)
      let baseAmount: number;
      if (isIndianNumber) {
        // Reverse calculate base amount from final amount with 18% GST
        baseAmount = Math.round(amount / 1.18);
      } else {
        baseAmount = amount;
      }

      const durationKey = planDuration >= 365 ? "year" : "month";
      const subscriptionId = `${phone}-subscriptions`;

      // Fetch existing subscription to get current receipts
      const { data: subscription } = await this.supabase
        .from("subscriptions")
        .select("receipts")
        .eq("id", subscriptionId)
        .maybeSingle();

      // Get existing receipts or empty array
      const existingReceipts: any[] = Array.isArray(subscription?.receipts)
        ? subscription.receipts
        : [];

      // Read global invoice number from file
      const invoiceCountFilePath = Deno.env.get(
        "SUBSCRIPTION_RECEIPT_COUNT_FILE",
      );
      if (!invoiceCountFilePath) {
        this.logger.error("SUBSCRIPTION_RECEIPT_COUNT_FILE env var not set");
        return { status: 1, invoice: null };
      }

      let currentInvoiceNo = 0;
      try {
        const fileContent = await Deno.readTextFile(invoiceCountFilePath);
        const data = JSON.parse(fileContent);
        currentInvoiceNo = data.invoice || 0;
      } catch (e) {
        this.logger.warning(
          `Could not read invoice count file, starting from 0: ${e}`,
        );
      }

      const nextInvoiceNo = currentInvoiceNo + 1;

      // Update the invoice count file with the new number
      try {
        await Deno.writeTextFile(
          invoiceCountFilePath,
          JSON.stringify({ invoice: nextInvoiceNo }),
        );
      } catch (e) {
        this.logger.error(`Failed to update invoice count file: ${e}`);
        return { status: 1, invoice: null };
      }

      // Create invoice record
      const invoice = {
        id: `order_${Date.now()}`,
        key: `${amount / 100}_${durationKey}`,
        days: planDuration,
        plan: planType,
        time: invoiceDate,
        amount: amount,
        details: {
          gstin: gstin,
          address: address,
          businessName: businessName,
        },
        isUltra: planType === "ULTRA",
        currency: "INR",
        invoiceNo: nextInvoiceNo,
        baseAmount: baseAmount,
        phone: phone,
      };

      // Add new invoice to receipts array
      const updatedReceipts = [...existingReceipts, invoice];

      // Update the subscriptions table with the new receipts array
      const { error } = await this.supabase
        .from("subscriptions")
        .update({ receipts: updatedReceipts })
        .eq("id", subscriptionId);

      if (error) {
        this.logger.error(`Failed to generate invoice: ${error.message}`);
        return { status: 1, invoice: null };
      }

      this.logger.log(
        `Invoice generated for phone: ${phone}, invoiceNo: ${nextInvoiceNo}, isIndian: ${isIndianNumber}, baseAmount: ${baseAmount}, amount: ${amount}`,
      );
      return { status: 0, invoice: invoice };
    } catch (error) {
      this.logger.error(`Exception generateInvoice(): ${error}`);
      return { status: 1, invoice: null };
    }
  }

  async fetchInvoices(
    startDate: string,
    endDate: string,
  ): Promise<any[] | null> {
    try {
      this.logger.log(`Fetching invoices from ${startDate} to ${endDate}`);

      // Fetch all subscriptions with receipts
      const { data, error } = await this.supabase
        .from("subscriptions")
        .select("id, receipts");

      if (error) {
        this.logger.error(`Failed to fetch subscriptions: ${error.message}`);
        return null;
      }

      // Parse dates for comparison
      const startDateTime = new Date(startDate).getTime();
      const endDateTime = new Date(endDate).getTime();

      // Extract and filter receipts from all subscriptions
      const allInvoices: any[] = [];
      for (const subscription of data || []) {
        if (!subscription.receipts) continue;

        // receipts is a jsonb array
        const receipts = Array.isArray(subscription.receipts)
          ? subscription.receipts
          : [];

        for (const receipt of receipts) {
          if (!receipt.time) continue;

          const receiptTime = new Date(receipt.time).getTime();
          if (receiptTime >= startDateTime && receiptTime <= endDateTime) {
            // Extract phone from subscription id (format: phone-subscriptions)
            const phone = subscription.id.replace("-subscriptions", "");
            allInvoices.push({
              ...receipt,
              phone: receipt.phone || phone,
            });
          }
        }
      }

      // Sort by invoiceNo descending
      allInvoices.sort((a, b) => (b.invoiceNo || 0) - (a.invoiceNo || 0));

      this.logger.log(
        `Fetched ${allInvoices.length} invoices from subscriptions`,
      );
      return allInvoices;
    } catch (error) {
      this.logger.error(`Exception fetchInvoices(): ${error}`);
      return null;
    }
  }

  async fetchPendingReceipts(
    startDate: string,
    endDate: string,
  ): Promise<any[] | null> {
    try {
      this.logger.log(
        `Fetching pending receipts from ${startDate} to ${endDate}`,
      );

      // Parse dates for comparison
      const startDateTime = new Date(startDate);
      const endDateTime = new Date(endDate);

      // Fetch all subscriptions
      const { data: subscriptions, error } = await this.supabase
        .from("subscriptions")
        .select("id, subdays, subplan, isultra, substartedat, receipts");

      if (error) {
        this.logger.error(`Failed to fetch subscriptions: ${error.message}`);
        return null;
      }

      const pendingUsers: any[] = [];

      for (const subscription of subscriptions || []) {
        // Skip if no substartedat
        if (!subscription.substartedat) continue;

        // Parse subscription start date
        const subStartedAt = new Date(subscription.substartedat);

        // Check if substartedat is within the date range
        if (
          subStartedAt.getTime() < startDateTime.getTime() ||
          subStartedAt.getTime() > endDateTime.getTime()
        ) continue;

        // Check if subscription is active (substartedat + subdays > now)
        const subEndDate = new Date(subStartedAt);
        subEndDate.setDate(subEndDate.getDate() + (subscription.subdays || 0));
        if (
          subEndDate.getTime() < Date.now() || ((subscription.subdays || 0) <= 3)
        ) continue;

        // Extract phone from subscription id (format: phone-subscriptions)
        const phone = subscription.id.replace("-subscriptions", "");

        // Get substartedat date string for comparison
        const subStartedDateStr = `${subStartedAt.getFullYear()}-${
          String(subStartedAt.getMonth() + 1).padStart(2, "0")
        }-${String(subStartedAt.getDate()).padStart(2, "0")}`;

        // Check receipts - pending if null, empty, or no receipt matching substartedat date
        const receipts = Array.isArray(subscription.receipts)
          ? subscription.receipts
          : [];

        let hasMatchingReceipt = false;
        for (const receipt of receipts) {
          if (!receipt.time) continue;
          const receiptDate = new Date(receipt.time);
          const receiptDateStr = `${receiptDate.getFullYear()}-${
            String(receiptDate.getMonth() + 1).padStart(2, "0")
          }-${String(receiptDate.getDate()).padStart(2, "0")}`;
          if (receiptDateStr === subStartedDateStr) {
            hasMatchingReceipt = true;
            break;
          }
        }

        // If no matching receipt, add to pending list
        if (!hasMatchingReceipt) {
          // Fetch user details
          const user = await this.fetchUser(phone);

          pendingUsers.push({
            phone: phone,
            name: user?.name || "-",
            shop: user?.shop || "-",
            subplan: subscription.isultra ? "ULTRA" : subscription.subplan,
            subdays: subscription.subdays,
            substartedat: subscription.substartedat,
          });
        }
      }

      this.logger.log(
        `Found ${pendingUsers.length} users with pending receipts`,
      );
      return pendingUsers;
    } catch (error) {
      this.logger.error(`Exception fetchPendingReceipts(): ${error}`);
      return null;
    }
  }
}

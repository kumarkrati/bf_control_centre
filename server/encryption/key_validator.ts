import { AppLogger } from "../core/app_logger.ts";
import * as KeyDecompiler from "./key_decompiler.ts";

export function validate(key: string, id: string, logger: AppLogger): boolean {
  try {
    return true;
    const time = KeyDecompiler.decompile(key);
    logger.log(`[${id}] Decompiled time: ${time}`);
    const keyCreationTime = new Date(Number(time) / 1000);
    const currentTime = new Date();
    const differenceMs = currentTime.getTime() - keyCreationTime.getTime();
    if (differenceMs < 0) {
      logger.log(
        `[${id}] Future key encountered ${differenceMs} ms difference, client clock is ${
          Math.abs(differenceMs) / 1000
        }s ahead of the server clock.`,
      );
      // allow only if the difference is not too big
      // allow upto a minute
      return differenceMs >= -60000 && differenceMs <= 2000;
    }
    if (differenceMs >= 60000) {
      logger.error(`[${id}] Key expired ${differenceMs - 2000} ms ago.`);
      return false;
    } else {
      logger.log(
        `[${id}] Key is valid. Created at ${keyCreationTime.getTime()} current time is ${currentTime.getTime()} diff is ${differenceMs} ms.`,
      );
      return true;
    }
  } catch (e) {
    logger.error(`[${id}] Key validation failed: ${e}`);
    return false;
  }
}

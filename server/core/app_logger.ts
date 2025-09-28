import { formatDate, formatTime } from "../utils/date_time_utils.ts";
import { prepareLogStorage } from "../utils/storage_utils.ts";

export class AppLogger {
  private readonly logName: string;

  constructor(logName: string) {
    this.logName = `.logs/${logName}`;
    const date = Date.now();
    const day = formatDate(date);
    const time = formatTime(date);
    prepareLogStorage();
    Deno.writeTextFileSync(
      this.logName,
      `${logName} logger initialized on ${day} at ${time} (${date} mse)`,
    );
  }

  log(msg: string) {
    const date = Date.now();
    const day = formatDate(date);
    const time = formatTime(date);
    Deno.writeTextFileSync(
      this.logName,
      `\n[${day} (${time})] ${msg}`,
      { append: true },
    );
  }

  error(msg: string) {
    const date = Date.now();
    const day = formatDate(date);
    const time = formatTime(date);
    Deno.writeTextFileSync(
      this.logName,
      `\n(ERROR)[${day} (${time})] ${msg}`,
      { append: true },
    );
  }

  warning(msg: string) {
    const date = Date.now();
    const day = formatDate(date);
    const time = formatTime(date);
    Deno.writeTextFileSync(
      this.logName,
      `\n(WARNING)[${day} (${time})] ${msg}`,
      { append: true },
    );
  }

  fatal(msg: string) {
    const date = Date.now();
    const day = formatDate(date);
    const time = formatTime(date);
    Deno.writeTextFileSync(
      this.logName,
      `\n(FATAL)[${day} (${time})] ${msg}`,
      { append: true },
    );
  }
}

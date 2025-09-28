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
    msg = `[${day} (${time})] ${msg}`;
    Deno.writeTextFileSync(
      this.logName,
      `\n${msg}`,
      { append: true },
    );
    console.log(msg)
  }

  error(msg: string) {
    const date = Date.now();
    const day = formatDate(date);
    const time = formatTime(date);
    msg = `(ERROR)[${day} (${time})] ${msg}`;
    Deno.writeTextFileSync(
      this.logName,
      `\n${msg}`,
      { append: true },
    );
    console.error(msg)
  }

  warning(msg: string) {
    const date = Date.now();
    const day = formatDate(date);
    const time = formatTime(date);
    msg = `(WARNING)[${day} (${time})] ${msg}`;
    Deno.writeTextFileSync(
      this.logName,
      `\n${msg}`,
      { append: true },
    );
    console.warn(msg)
  }

  fatal(msg: string) {
    const date = Date.now();
    const day = formatDate(date);
    const time = formatTime(date);
    msg = `(FATAL)[${day} (${time})] ${msg}`;
    Deno.writeTextFileSync(
      this.logName,
      `\n${msg}`,
      { append: true },
    );
    console.error(msg)
  }
}

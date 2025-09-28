export function makeSureNotEmpty(value?: string | number, fallback = "-") {
  if (
    value === null || value === undefined || value === "null" || value === ""
  ) {
    return fallback;
  }
  return value;
}

export function getErrorMessage(error: unknown): string {
  if (error instanceof Error) return error.message;
  return String(error);
}
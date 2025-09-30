int convertToDays(int value, String unit) {
  switch (unit) {
    case "day":
      return value;
    case "month":
      return value * 30;
    case "year":
      return value * 365;
    case "days":
      return value;
    case "months":
      return value * 30;
    case "years":
      return value * 365;
    default:
      throw ArgumentError("Invalid unit: $unit");
  }
}

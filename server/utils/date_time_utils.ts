import {makeSureNotEmpty} from "./value_utils.ts";

export function dayToDate(day: number, endOfDay: boolean = false) {
  const date = new Date(day);
  if (endOfDay) {
    date.setHours(23, 59, 59, 999);
  } else {
    date.setHours(0, 0, 0, 0);
  }
  return date.getTime();
}

export function formatDate(value?: string | number) {
  if (makeSureNotEmpty(value) === '-') {
    return "-"
  }
  const date = new Date(value!)
  const yyyy = date.getFullYear();
  const mm = date.getMonth() + 1;
  const dd = date.getDate();
  return `${dd}/${mm}/${yyyy}`;
}

export function formatTime(value?: string | number) {
  if (!value || value === "null" || value === "") {
    return "-";
  }
  const date = new Date(value);
  const hh = date.getHours();
  const mm = date.getMinutes();
  const ss = date.getSeconds();

  return `${hh}:${mm}:${ss}`;
}
export enum LoginStatus {
  error,
  invalid,
  denied,
  success,
}

export enum InvoiceNumberStatus {
  success,
  fail,
  noRef,
}

export enum RestoreProdStatus {
  restored,
  failed,
  noRef,
}

export enum ViewPasswordStatus {
  success,
  noRef,
  noPasswordSet,
  failed,
}

export enum SetPasswordStatus {
  failed,
  noRef,
  success,
}
enum LoginStatus { error, invalid, denied, success }

enum InvoiceNumberStatus { success, fail, noRef, unauthorized }

enum RestoreProdStatus { restored, failed, noRef, unauthorized }

enum ViewPasswordStatus { success, noRef, noPasswordSet, failed, unauthorized }

enum SetPasswordStatus { failed, noRef, success, unauthorized }

enum UpdateSubscriptionStatus { success, failed, noRef, unauthorized }

enum CreateAccountStatus { success, failed, alreadyRegistered, unauthorized }

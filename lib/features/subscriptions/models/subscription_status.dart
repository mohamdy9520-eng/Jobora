import 'package:purchases_flutter/purchases_flutter.dart';

class SubscriptionStatus {
  final bool isActive;
  final String? productIdentifier;
  final DateTime? expirationDate;
  final bool willRenew;
  final String? managementUrl;

  const SubscriptionStatus({
    required this.isActive,
    this.productIdentifier,
    this.expirationDate,
    this.willRenew = false,
    this.managementUrl,
  });

  factory SubscriptionStatus.free() => const SubscriptionStatus(isActive: false);

  factory SubscriptionStatus.fromCustomerInfo(CustomerInfo info) {
    if (info.entitlements.active.isEmpty) {
      return SubscriptionStatus(isActive: false, managementUrl: info.managementURL);
    }
    final entitlement = info.entitlements.active.values.first;
    return SubscriptionStatus(
      isActive: true,
      productIdentifier: entitlement.productIdentifier,
      expirationDate:
      entitlement.expirationDate != null ? DateTime.tryParse(entitlement.expirationDate!) : null,
      willRenew: entitlement.willRenew,
      managementUrl: info.managementURL,
    );
  }
}
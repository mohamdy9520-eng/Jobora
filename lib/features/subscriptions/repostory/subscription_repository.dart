import 'dart:async';
import 'package:purchases_flutter/purchases_flutter.dart';

class SubscriptionRepository {
  Future<Offerings> fetchOfferings() => Purchases.getOfferings();

  Future<CustomerInfo> fetchCustomerInfo() => Purchases.getCustomerInfo();

  // purchasePackage returns CustomerInfo directly in this SDK version —
  // no wrapper object with a `.customerInfo` getter.
  Future<CustomerInfo> purchasePackage(Package package) async {
    final PurchaseResult result = await Purchases.purchasePackage(package);
    return result.customerInfo;
  }

  Future<CustomerInfo> restorePurchases() => Purchases.restorePurchases();

  // purchases_flutter exposes live updates via a callback listener, not
  // a Stream getter — wrap it into a broadcast Stream so the rest of
  // the app (SubscriptionProvider) can `listen` to it like any other
  // stream, same as customerInfoStream would have worked.
  Stream<CustomerInfo> customerInfoUpdates() {
    late final StreamController<CustomerInfo> controller;
    void listener(CustomerInfo info) => controller.add(info);
    controller = StreamController<CustomerInfo>.broadcast(
      onListen: () => Purchases.addCustomerInfoUpdateListener(listener),
      onCancel: () => Purchases.removeCustomerInfoUpdateListener(listener),
    );
    return controller.stream;
  }
}
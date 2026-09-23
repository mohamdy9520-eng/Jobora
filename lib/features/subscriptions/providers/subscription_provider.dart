import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class SubscriptionProvider with ChangeNotifier {
  String? _uid;
  Offerings? _offerings;
  CustomerInfo? _customerInfo;
  bool _isLoading = false;
  String? _error;

  Offerings? get offerings => _offerings;
  CustomerInfo? get customerInfo => _customerInfo;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // غيّر "Jobora Pro" لاسم الـ Entitlement بالظبط زي ما هو في RevenueCat Dashboard
  bool get isPro =>
      _customerInfo?.entitlements.active.containsKey('jobora_pro') ?? false;

  /// بينادى من الـ ChangeNotifierProxyProvider في main.dart كل ما حالة
  /// AuthController تتغير، عشان يربط/يفك ربط RevenueCat App User ID
  /// مع الـ Firebase UID الحالي.
  Future<void> updateAuth(String? uid) async {
    if (_uid == uid) return; // منع استدعاءات مكررة لنفس الـ uid
    _uid = uid;

    try {
      if (uid != null) {
        final result = await Purchases.logIn(uid);
        _customerInfo = result.customerInfo;
      } else {
        final info = await Purchases.logOut();
        _customerInfo = info;
      }
    } on PlatformException catch (e) {
      _error = e.message;
    } finally {
      notifyListeners();
    }
  }

  Future<void> fetchOfferings() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _offerings = await Purchases.getOfferings();
    } on PlatformException catch (e) {
      _error = e.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> purchasePackage(Package package) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await Purchases.purchasePackage(package);
      _customerInfo = result.customerInfo;

      // 🔍 تشخيص مؤقت
      debugPrint('🔍 Active entitlements: ${_customerInfo?.entitlements.active.keys.toList()}');
      debugPrint('🔍 All entitlements: ${_customerInfo?.entitlements.all.keys.toList()}');

      _isLoading = false;
      notifyListeners();
      return isPro;
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code != PurchasesErrorCode.purchaseCancelledError) {
        _error = e.message;
      }
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> refreshCustomerInfo() async {
    try {
      _customerInfo = await Purchases.getCustomerInfo();
      notifyListeners();
    } on PlatformException catch (e) {
      _error = e.message;
      notifyListeners();
    }
  }

  Future<bool> restorePurchases() async {
    _isLoading = true;
    notifyListeners();
    try {
      _customerInfo = await Purchases.restorePurchases();
      _isLoading = false;
      notifyListeners();
      return isPro;
    } on PlatformException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
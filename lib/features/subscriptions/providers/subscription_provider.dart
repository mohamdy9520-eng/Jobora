import 'dart:async';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:flutter/material.dart';
import '../models/subscription_status.dart';
import '../repostory/subscription_repository.dart';

class SubscriptionProvider extends ChangeNotifier {
  final _repository = SubscriptionRepository();
  StreamSubscription<CustomerInfo>? _sub;
  String? _uid;

  SubscriptionStatus _status = SubscriptionStatus.free();
  Offerings? _offerings;
  bool _isLoading = true;
  bool _isPurchasing = false;
  String? _error;

  SubscriptionStatus get status => _status;
  Offering? get currentOffering => _offerings?.current;
  bool get isLoading => _isLoading;
  bool get isPurchasing => _isPurchasing;
  String? get error => _error;

  /// Keeps RevenueCat's App User ID in sync with the Firebase uid, and
  /// (re)loads offerings/status for the signed-in user. Same pattern as
  /// the other providers' updateAuth(auth.uid) wired in main.dart.
  void updateAuth(String? uid) {
    if (_uid == uid) return;
    _uid = uid;
    if (uid != null) {
      Purchases.logIn(uid).then((_) => _refresh());
    } else {
      Purchases.logOut();
      _status = SubscriptionStatus.free();
      _offerings = null;
      notifyListeners();
    }
  }

  SubscriptionProvider() {
    _sub = _repository.customerInfoUpdates().listen((info) {
      _status = SubscriptionStatus.fromCustomerInfo(info);
      notifyListeners();
    });
  }

  Future<void> _refresh() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final info = await _repository.fetchCustomerInfo();
      _status = SubscriptionStatus.fromCustomerInfo(info);
      _offerings = await _repository.fetchOfferings();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> purchase(Package package) async {
    _isPurchasing = true;
    _error = null;
    notifyListeners();
    try {
      final info = await _repository.purchasePackage(package);
      _status = SubscriptionStatus.fromCustomerInfo(info);
      return true;
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code != PurchasesErrorCode.purchaseCancelledError) {
        _error = e.message;
      }
      return false;
    } finally {
      _isPurchasing = false;
      notifyListeners();
    }
  }

  Future<bool> restore() async {
    _isLoading = true;
    notifyListeners();
    try {
      final info = await _repository.restorePurchases();
      _status = SubscriptionStatus.fromCustomerInfo(info);
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
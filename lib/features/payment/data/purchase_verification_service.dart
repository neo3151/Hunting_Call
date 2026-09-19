import 'package:cloud_functions/cloud_functions.dart';

class PurchaseVerificationResult {
  final bool entitled;
  final String status;
  final String? expiresAt;

  const PurchaseVerificationResult({
    required this.entitled,
    required this.status,
    this.expiresAt,
  });
}

abstract class PurchaseVerificationService {
  Future<PurchaseVerificationResult> verifyAndroidPurchase({
    required String productId,
    required String purchaseToken,
  });
}

class FirebasePurchaseVerificationService
    implements PurchaseVerificationService {
  final FirebaseFunctions _functions;

  FirebasePurchaseVerificationService({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  @override
  Future<PurchaseVerificationResult> verifyAndroidPurchase({
    required String productId,
    required String purchaseToken,
  }) async {
    final callable = _functions.httpsCallable('verifyAndroidEntitlement');
    final response = await callable.call<Map<String, dynamic>>({
      'productId': productId,
      'purchaseToken': purchaseToken,
    });
    final data = response.data;
    return PurchaseVerificationResult(
      entitled: data['entitled'] as bool? ?? false,
      status: data['status'] as String? ?? 'unknown',
      expiresAt: data['expiresAt'] as String?,
    );
  }
}

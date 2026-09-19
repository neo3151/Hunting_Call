import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:mocktail/mocktail.dart';
import 'package:outcall/features/payment/data/payment_repository.dart';
import 'package:outcall/features/payment/data/purchase_verification_service.dart';
import 'package:outcall/features/profile/domain/repositories/profile_repository.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

class MockInAppPurchase extends Mock implements InAppPurchase {}

class FakePurchaseDetails extends Fake implements PurchaseDetails {}

class FakePurchaseVerificationService implements PurchaseVerificationService {
  PurchaseVerificationResult result = const PurchaseVerificationResult(
    entitled: true,
    status: 'active',
  );
  Object? error;
  final Map<String, PurchaseVerificationResult> resultsByProduct = {};
  String? productId;
  String? purchaseToken;

  @override
  Future<PurchaseVerificationResult> verifyAndroidPurchase({
    required String productId,
    required String purchaseToken,
  }) async {
    this.productId = productId;
    this.purchaseToken = purchaseToken;
    if (error != null) throw error!;
    return resultsByProduct[productId] ?? result;
  }
}

final testProduct = ProductDetails(
  id: 'outcall_premium_monthly',
  title: 'Monthly',
  description: 'Monthly premium',
  price: r'$4.99',
  rawPrice: 4.99,
  currencyCode: 'USD',
);

void main() {
  setUpAll(() {
    registerFallbackValue(PurchaseParam(productDetails: testProduct));
    registerFallbackValue(FakePurchaseDetails());
  });

  group('MockPaymentRepository', () {
    late MockPaymentRepository paymentRepo;
    late MockProfileRepository mockProfileRepo;

    setUp(() {
      mockProfileRepo = MockProfileRepository();
      paymentRepo = MockPaymentRepository(mockProfileRepo);
    });

    test('purchasePremium returns true and updates profile', () async {
      when(() => mockProfileRepo.setPremiumStatus('user1', true))
          .thenAnswer((_) async {});

      final result = await paymentRepo.purchasePremium('user1');

      expect(result, true);
      verify(() => mockProfileRepo.setPremiumStatus('user1', true)).called(1);
    });

    test('purchasePremium returns false when profile update fails', () async {
      when(() => mockProfileRepo.setPremiumStatus('user1', true))
          .thenThrow(Exception('Network error'));

      final result = await paymentRepo.purchasePremium('user1');

      expect(result, false);
    });

    test('restorePurchases delegates to purchasePremium', () async {
      when(() => mockProfileRepo.setPremiumStatus('user1', true))
          .thenAnswer((_) async {});

      final result = await paymentRepo.restorePurchases('user1');

      expect(result, true);
      verify(() => mockProfileRepo.setPremiumStatus('user1', true)).called(1);
    });
  });

  group('NativePaymentRepository', () {
    late MockProfileRepository mockProfileRepo;
    late MockInAppPurchase mockIap;
    late FakePurchaseVerificationService verificationService;
    late StreamController<List<PurchaseDetails>> purchaseController;
    late NativePaymentRepository paymentRepo;

    setUp(() {
      mockProfileRepo = MockProfileRepository();
      mockIap = MockInAppPurchase();
      verificationService = FakePurchaseVerificationService();
      purchaseController = StreamController<List<PurchaseDetails>>.broadcast();
      when(() => mockIap.purchaseStream)
          .thenAnswer((_) => purchaseController.stream);
      when(() => mockIap.isAvailable()).thenAnswer((_) async => true);
      when(() => mockIap.queryProductDetails(any())).thenAnswer(
        (_) async => ProductDetailsResponse(
            productDetails: [testProduct], notFoundIDs: const []),
      );
      when(() => mockIap.buyNonConsumable(
              purchaseParam: any(named: 'purchaseParam')))
          .thenAnswer((_) async => true);
      when(() => mockIap.restorePurchases()).thenAnswer((_) async {});
      when(() => mockIap.completePurchase(any())).thenAnswer((_) async {});
      paymentRepo = NativePaymentRepository(
        profileRepo: mockProfileRepo,
        verificationService: verificationService,
        inAppPurchase: mockIap,
      )..initialize();
    });

    tearDown(() async {
      paymentRepo.dispose();
      await purchaseController.close();
    });

    PurchaseDetails purchase({
      String productId = 'outcall_premium_monthly',
      PurchaseStatus status = PurchaseStatus.purchased,
    }) {
      final details = PurchaseDetails(
        purchaseID: 'purchase-1',
        productID: productId,
        verificationData: PurchaseVerificationData(
          localVerificationData: 'local-data',
          serverVerificationData: 'server-purchase-token',
          source: 'google_play',
        ),
        transactionDate: DateTime.now().millisecondsSinceEpoch.toString(),
        status: status,
      );
      details.pendingCompletePurchase = true;
      return details;
    }

    test('grants success only after server verification', () async {
      final resultFuture =
          paymentRepo.purchasePremium('user1', packageId: testProduct.id);
      await Future<void>.delayed(Duration.zero);
      purchaseController.add([purchase()]);

      expect(await resultFuture, true);
      expect(verificationService.productId, testProduct.id);
      expect(verificationService.purchaseToken, 'server-purchase-token');
      verify(() => mockIap.completePurchase(any())).called(1);
      verifyNever(() => mockProfileRepo.setPremiumStatus(any(), any()));
    });

    test('does not grant premium when server verification rejects purchase',
        () async {
      verificationService.result = const PurchaseVerificationResult(
        entitled: false,
        status: 'expired',
      );
      final resultFuture =
          paymentRepo.purchasePremium('user1', packageId: testProduct.id);
      await Future<void>.delayed(Duration.zero);
      purchaseController.add([purchase()]);

      expect(await resultFuture, false);
      verify(() => mockIap.completePurchase(any())).called(1);
      verifyNever(() => mockProfileRepo.setPremiumStatus(any(), any()));
    });

    test('restore succeeds when a later restored product is entitled',
        () async {
      verificationService.resultsByProduct['outcall_premium_monthly'] =
          const PurchaseVerificationResult(entitled: false, status: 'expired');
      verificationService.resultsByProduct['outcall_premium_yearly'] =
          const PurchaseVerificationResult(entitled: true, status: 'active');
      final resultFuture = paymentRepo.restorePurchases('user1');
      await Future<void>.delayed(Duration.zero);
      purchaseController.add([
        purchase(status: PurchaseStatus.restored),
        purchase(
          productId: 'outcall_premium_yearly',
          status: PurchaseStatus.restored,
        ),
      ]);

      expect(await resultFuture, true);
      verify(() => mockIap.completePurchase(any())).called(2);
    });
  });
}

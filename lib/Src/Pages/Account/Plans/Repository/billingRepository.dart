import 'package:sistem_cormex/Src/Connection/endpoints.dart';
import 'package:sistem_cormex/Src/Connection/httpManager.dart';
import 'package:sistem_cormex/Src/Models/billingModels.dart';

abstract interface class BillingRepository {
  Future<BillingCatalog> getCatalog({required String sessionToken});

  Future<BillingCheckoutSession> createCheckout({
    required String sessionToken,
    required String planId,
    required String billingCycle,
    required List<String> addOnIds,
    required String provider,
  });

  Future<BillingVerification> verifyCheckout({
    required String sessionToken,
    required String checkoutId,
  });

  Future<BillingPortalSession> createPortal({
    required String sessionToken,
  });

  Future<BillingSubscription> cancelSubscription({
    required String sessionToken,
    required String reason,
  });

  Future<BillingSubscription> resumeSubscription({
    required String sessionToken,
  });
}

class ParseBillingRepository implements BillingRepository {
  const ParseBillingRepository(this._httpManager);

  final HttpManager _httpManager;

  @override
  Future<BillingCatalog> getCatalog({required String sessionToken}) async {
    final result = await _post(
      Endpoints.billingCatalog,
      sessionToken,
      const {},
    );
    return BillingCatalog.fromMap(result);
  }

  @override
  Future<BillingCheckoutSession> createCheckout({
    required String sessionToken,
    required String planId,
    required String billingCycle,
    required List<String> addOnIds,
    required String provider,
  }) async {
    final result = await _post(
      Endpoints.billingCheckoutCreate,
      sessionToken,
      {
        'planId': planId,
        'billingCycle': billingCycle,
        'addOnIds': addOnIds,
        'provider': provider,
        'returnPath': '/conta/plano',
      },
    );
    return BillingCheckoutSession.fromMap(_nestedMap(result, 'checkout'));
  }

  @override
  Future<BillingVerification> verifyCheckout({
    required String sessionToken,
    required String checkoutId,
  }) async {
    final result = await _post(
      Endpoints.billingCheckoutVerify,
      sessionToken,
      {'checkoutId': checkoutId},
    );
    return BillingVerification.fromMap(result);
  }

  @override
  Future<BillingPortalSession> createPortal({
    required String sessionToken,
  }) async {
    final result = await _post(
      Endpoints.billingPortalCreate,
      sessionToken,
      {'returnPath': '/conta/plano'},
    );
    return BillingPortalSession.fromMap(_nestedMap(result, 'portal'));
  }

  @override
  Future<BillingSubscription> cancelSubscription({
    required String sessionToken,
    required String reason,
  }) async {
    final result = await _post(
      Endpoints.billingSubscriptionCancel,
      sessionToken,
      {'reason': reason.trim(), 'atPeriodEnd': true},
    );
    return BillingSubscription.fromMap(_nestedMap(result, 'subscription'));
  }

  @override
  Future<BillingSubscription> resumeSubscription({
    required String sessionToken,
  }) async {
    final result = await _post(
      Endpoints.billingSubscriptionResume,
      sessionToken,
      const {},
    );
    return BillingSubscription.fromMap(_nestedMap(result, 'subscription'));
  }

  Future<Map<String, dynamic>> _post(
    String endpoint,
    String sessionToken,
    Map<String, dynamic> body,
  ) async {
    final response = await _httpManager.restRequest(
      url: endpoint,
      method: HttpMethod.post,
      sessionToken: sessionToken,
      body: body,
    );
    final result = response['result'];
    if (result is Map) return Map<String, dynamic>.from(result);
    throw const FormatException(
      'O servidor retornou uma resposta inválida para Plano e módulos.',
    );
  }

  Map<String, dynamic> _nestedMap(
    Map<String, dynamic> result,
    String key,
  ) {
    final value = result[key];
    return value is Map ? Map<String, dynamic>.from(value) : result;
  }
}

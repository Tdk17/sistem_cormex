import 'package:signals/signals.dart';
import 'package:sistem_cormex/Src/Connection/apiException.dart';
import 'package:sistem_cormex/Src/Models/billingModels.dart';
import 'package:sistem_cormex/Src/Pages/Account/Plans/Repository/billingRepository.dart';
import 'package:sistem_cormex/Src/Pages/Auth/Controller/authController.dart';

class BillingController {
  BillingController(this._repository, this._authController);

  final BillingRepository _repository;
  final AuthController _authController;
  String? _dataSessionToken;
  String? _lastVerifiedCheckoutId;

  final loading = signal(false);
  final actionLoading = signal(false);
  final verifyingCheckout = signal(false);
  final error = signal<String?>(null);
  final checkoutMessage = signal<String?>(null);
  final catalog = signal<BillingCatalog?>(null);

  final billingCycle = signal('monthly');
  final selectedPlanId = signal<String?>(null);
  final selectedAddOnIds = signal<Set<String>>(<String>{});
  final selectedProvider = signal<String?>(null);

  Future<void> initialize({String? checkoutId}) async {
    _synchronizeSession();
    if (catalog.value == null) await loadCatalog();
    if (checkoutId != null &&
        checkoutId.isNotEmpty &&
        checkoutId != _lastVerifiedCheckoutId) {
      await verifyCheckout(checkoutId);
    }
  }

  Future<bool> loadCatalog() async {
    if (loading.value) return false;
    batch(() {
      loading.value = true;
      error.value = null;
    });
    try {
      final result = await _repository.getCatalog(sessionToken: _sessionToken);
      catalog.value = result;
      _initializeSelection(result);
      return true;
    } catch (exception) {
      error.value = _messageFor(exception);
      return false;
    } finally {
      loading.value = false;
    }
  }

  void selectBillingCycle(String value) {
    if (value != 'monthly' && value != 'annual') return;
    billingCycle.value = value;
  }

  void selectPlan(BillingPlan plan) {
    if (!plan.active) return;
    selectedPlanId.value = plan.id;
    final validAddOns = selectedAddOnIds.value.where((id) {
      final addOn = _firstOrNull(
        catalog.value?.addOns.where((item) => item.id == id),
      );
      return addOn != null && addOn.supportsPlan(plan.code);
    }).toSet();
    selectedAddOnIds.value = validAddOns;
  }

  void toggleAddOn(BillingAddOn addOn) {
    final plan = selectedPlan;
    if (!addOn.active || plan == null || !addOn.supportsPlan(plan.code)) return;
    final next = Set<String>.from(selectedAddOnIds.value);
    if (!next.add(addOn.id)) next.remove(addOn.id);
    selectedAddOnIds.value = next;
  }

  void selectProvider(String code) {
    final available = catalog.value?.providers.any(
          (provider) => provider.code == code && provider.enabled,
        ) ??
        false;
    if (available) selectedProvider.value = code;
  }

  BillingPlan? get selectedPlan {
    final id = selectedPlanId.value;
    if (id == null) return null;
    return _firstOrNull(
      catalog.value?.plans.where((plan) => plan.id == id),
    );
  }

  List<BillingAddOn> get selectedAddOns {
    final ids = selectedAddOnIds.value;
    return catalog.value?.addOns.where((item) => ids.contains(item.id)).toList() ??
        const [];
  }

  double get selectionTotal {
    final cycle = billingCycle.value;
    return (selectedPlan?.priceFor(cycle) ?? 0) +
        selectedAddOns.fold<double>(
          0,
          (total, item) => total + item.priceFor(cycle),
        );
  }

  bool hasFeature(String code) {
    return catalog.value?.subscription?.hasFeature(code) ?? false;
  }

  Future<BillingCheckoutSession?> createCheckout() async {
    if (actionLoading.value) return null;
    final currentCatalog = catalog.value;
    final plan = selectedPlan;
    final provider = selectedProvider.value;
    if (currentCatalog == null || plan == null) {
      error.value = 'Selecione um plano para continuar.';
      return null;
    }
    if (!currentCatalog.permissions.canSubscribe) {
      error.value = 'Somente o responsável financeiro pode contratar planos.';
      return null;
    }
    if (provider == null || provider.isEmpty) {
      error.value = 'Selecione uma plataforma de pagamento.';
      return null;
    }

    batch(() {
      actionLoading.value = true;
      error.value = null;
      checkoutMessage.value = null;
    });
    try {
      return await _repository.createCheckout(
        sessionToken: _sessionToken,
        planId: plan.id,
        billingCycle: billingCycle.value,
        addOnIds: selectedAddOnIds.value.toList(),
        provider: provider,
      );
    } catch (exception) {
      error.value = _messageFor(exception);
      return null;
    } finally {
      actionLoading.value = false;
    }
  }

  Future<BillingVerification?> verifyCheckout(String checkoutId) async {
    if (verifyingCheckout.value) return null;
    batch(() {
      verifyingCheckout.value = true;
      error.value = null;
      checkoutMessage.value = 'Confirmando o pagamento com segurança…';
    });
    try {
      final result = await _repository.verifyCheckout(
        sessionToken: _sessionToken,
        checkoutId: checkoutId,
      );
      _lastVerifiedCheckoutId = checkoutId;
      checkoutMessage.value = result.message.isNotEmpty
          ? result.message
          : result.paid
              ? 'Pagamento confirmado e recursos liberados.'
              : 'Pagamento recebido e aguardando confirmação.';
      if (result.subscription != null) {
        _replaceSubscription(result.subscription!);
      }
      await loadCatalog();
      return result;
    } catch (exception) {
      error.value = _messageFor(exception);
      checkoutMessage.value = null;
      return null;
    } finally {
      verifyingCheckout.value = false;
    }
  }

  Future<BillingPortalSession?> createPortal() async {
    if (actionLoading.value) return null;
    batch(() {
      actionLoading.value = true;
      error.value = null;
    });
    try {
      return await _repository.createPortal(sessionToken: _sessionToken);
    } catch (exception) {
      error.value = _messageFor(exception);
      return null;
    } finally {
      actionLoading.value = false;
    }
  }

  Future<bool> cancelSubscription(String reason) async {
    if (actionLoading.value) return false;
    batch(() {
      actionLoading.value = true;
      error.value = null;
    });
    try {
      final result = await _repository.cancelSubscription(
        sessionToken: _sessionToken,
        reason: reason,
      );
      _replaceSubscription(result);
      checkoutMessage.value =
          'Cancelamento agendado. O acesso continua até o fim do período pago.';
      return true;
    } catch (exception) {
      error.value = _messageFor(exception);
      return false;
    } finally {
      actionLoading.value = false;
    }
  }

  Future<bool> resumeSubscription() async {
    if (actionLoading.value) return false;
    batch(() {
      actionLoading.value = true;
      error.value = null;
    });
    try {
      final result = await _repository.resumeSubscription(
        sessionToken: _sessionToken,
      );
      _replaceSubscription(result);
      checkoutMessage.value = 'Renovação automática reativada.';
      return true;
    } catch (exception) {
      error.value = _messageFor(exception);
      return false;
    } finally {
      actionLoading.value = false;
    }
  }

  void clearError() => error.value = null;
  void clearCheckoutMessage() => checkoutMessage.value = null;

  void _initializeSelection(BillingCatalog value) {
    final current = value.subscription;
    final currentPlan = _firstOrNull(value.plans.where(
      (plan) => plan.id == current?.planId || plan.code == current?.planCode,
    ));
    final fallback =
        _firstOrNull(value.plans.where((plan) => plan.highlighted)) ??
            _firstOrNull(value.plans.where((plan) => plan.active));
    selectedPlanId.value = currentPlan?.id ?? fallback?.id;
    billingCycle.value = current?.billingCycle == 'annual' ? 'annual' : 'monthly';

    final addOnCodes = current?.addOnCodes.toSet() ?? const <String>{};
    selectedAddOnIds.value = value.addOns
        .where((item) => addOnCodes.contains(item.code))
        .map((item) => item.id)
        .toSet();

    final currentProvider = _firstOrNull(value.providers.where(
      (provider) => provider.code == current?.provider && provider.enabled,
    ));
    final recommended = _firstOrNull(value.providers.where(
      (provider) => provider.enabled && provider.recommended,
    ));
    final first = _firstOrNull(
      value.providers.where((provider) => provider.enabled),
    );
    selectedProvider.value = currentProvider?.code ?? recommended?.code ?? first?.code;
  }

  void _replaceSubscription(BillingSubscription subscription) {
    final value = catalog.value;
    if (value == null) return;
    catalog.value = BillingCatalog(
      plans: value.plans,
      addOns: value.addOns,
      providers: value.providers,
      invoices: value.invoices,
      permissions: value.permissions,
      currency: value.currency,
      subscription: subscription,
    );
  }

  void _synchronizeSession() {
    final token = _authController.sessionToken.value;
    if (_dataSessionToken == token) return;
    _dataSessionToken = token;
    _lastVerifiedCheckoutId = null;
    batch(() {
      catalog.value = null;
      error.value = null;
      checkoutMessage.value = null;
      selectedPlanId.value = null;
      selectedAddOnIds.value = <String>{};
      selectedProvider.value = null;
    });
  }

  String get _sessionToken {
    final token = _authController.sessionToken.value;
    if (token == null || token.isEmpty) {
      throw const ApiException(
        message: 'Sua sessão expirou. Entre novamente.',
        code: 209,
      );
    }
    return token;
  }

  String _messageFor(Object exception) {
    if (exception is ApiException) {
      switch (exception.code) {
        case 209:
          return 'Sua sessão expirou. Entre novamente.';
        case 9800:
          return 'Cadastre sua empresa antes de contratar um plano.';
        case 9801:
          return 'Somente o responsável financeiro pode alterar o plano.';
        case 9802:
          return 'O plano selecionado não está mais disponível.';
        case 9803:
          return 'Este módulo não é compatível com o plano selecionado.';
        case 9804:
          return 'A plataforma de pagamento selecionada está indisponível.';
        case 9805:
          return 'Não foi possível criar o checkout de pagamento.';
        case 9806:
          return 'Não foi possível localizar essa tentativa de pagamento.';
        case 9807:
          return 'O pagamento ainda está sendo processado.';
        case 9808:
          return 'A assinatura não foi localizada.';
        case 9809:
          return 'A assinatura já está cancelada.';
        case 9810:
          return 'Não foi possível validar a resposta da plataforma de pagamento.';
        case 9811:
          return 'Este recurso não faz parte do pacote contratado.';
        case 9812:
          return 'O limite contratado para este recurso foi atingido.';
        default:
          return exception.message;
      }
    }
    if (exception is FormatException) return exception.message.toString();
    return 'Não foi possível concluir a operação de pagamento.';
  }
}

T? _firstOrNull<T>(Iterable<T>? values) {
  if (values == null) return null;
  final iterator = values.iterator;
  return iterator.moveNext() ? iterator.current : null;
}

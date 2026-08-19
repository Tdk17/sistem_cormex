class BillingCatalog {
  const BillingCatalog({
    required this.plans,
    required this.addOns,
    required this.providers,
    required this.invoices,
    required this.permissions,
    required this.currency,
    this.subscription,
  });

  final List<BillingPlan> plans;
  final List<BillingAddOn> addOns;
  final List<BillingProvider> providers;
  final List<BillingInvoice> invoices;
  final BillingPermissions permissions;
  final String currency;
  final BillingSubscription? subscription;

  factory BillingCatalog.fromMap(Map<String, dynamic> map) {
    return BillingCatalog(
      plans: _mapList(map['plans']).map(BillingPlan.fromMap).toList(),
      addOns: _mapList(map['addOns']).map(BillingAddOn.fromMap).toList(),
      providers:
          _mapList(map['providers']).map(BillingProvider.fromMap).toList(),
      invoices:
          _mapList(map['invoices']).map(BillingInvoice.fromMap).toList(),
      permissions: BillingPermissions.fromMap(_mapValue(map['permissions'])),
      currency: _string(map['currency'], fallback: 'BRL'),
      subscription: map['subscription'] is Map
          ? BillingSubscription.fromMap(_mapValue(map['subscription']))
          : null,
    );
  }
}

class BillingPlan {
  const BillingPlan({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.badge,
    required this.currency,
    required this.monthlyPrice,
    required this.annualPrice,
    required this.features,
    required this.limits,
    required this.highlighted,
    required this.active,
    required this.trialDays,
    required this.displayOrder,
  });

  final String id;
  final String code;
  final String name;
  final String description;
  final String badge;
  final String currency;
  final double monthlyPrice;
  final double annualPrice;
  final List<BillingFeature> features;
  final Map<String, int> limits;
  final bool highlighted;
  final bool active;
  final int trialDays;
  final int displayOrder;

  factory BillingPlan.fromMap(Map<String, dynamic> map) {
    return BillingPlan(
      id: _string(map['id'], fallback: _string(map['objectId'])),
      code: _string(map['code']),
      name: _string(map['name']),
      description: _string(map['description']),
      badge: _string(map['badge']),
      currency: _string(map['currency'], fallback: 'BRL'),
      monthlyPrice: _decimal(map['monthlyPrice']),
      annualPrice: _decimal(map['annualPrice']),
      features:
          _mapList(map['features']).map(BillingFeature.fromMap).toList(),
      limits: _intMap(map['limits']),
      highlighted: _boolean(map['highlighted']),
      active: _boolean(map['active'], fallback: true),
      trialDays: _integer(map['trialDays']),
      displayOrder: _integer(map['displayOrder']),
    );
  }

  double priceFor(String billingCycle) {
    if (billingCycle == 'annual' && annualPrice > 0) return annualPrice;
    return monthlyPrice;
  }

  double get annualMonthlyEquivalent =>
      annualPrice > 0 ? annualPrice / 12 : monthlyPrice;
}

class BillingAddOn {
  const BillingAddOn({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.icon,
    required this.currency,
    required this.monthlyPrice,
    required this.annualPrice,
    required this.features,
    required this.limits,
    required this.active,
    required this.compatiblePlanCodes,
  });

  final String id;
  final String code;
  final String name;
  final String description;
  final String icon;
  final String currency;
  final double monthlyPrice;
  final double annualPrice;
  final List<String> features;
  final Map<String, int> limits;
  final bool active;
  final List<String> compatiblePlanCodes;

  factory BillingAddOn.fromMap(Map<String, dynamic> map) {
    return BillingAddOn(
      id: _string(map['id'], fallback: _string(map['objectId'])),
      code: _string(map['code']),
      name: _string(map['name']),
      description: _string(map['description']),
      icon: _string(map['icon'], fallback: 'extension'),
      currency: _string(map['currency'], fallback: 'BRL'),
      monthlyPrice: _decimal(map['monthlyPrice']),
      annualPrice: _decimal(map['annualPrice']),
      features: _stringList(map['features']),
      limits: _intMap(map['limits']),
      active: _boolean(map['active'], fallback: true),
      compatiblePlanCodes: _stringList(map['compatiblePlanCodes']),
    );
  }

  double priceFor(String billingCycle) {
    if (billingCycle == 'annual' && annualPrice > 0) return annualPrice;
    return monthlyPrice;
  }

  bool supportsPlan(String planCode) {
    return compatiblePlanCodes.isEmpty ||
        compatiblePlanCodes.contains(planCode);
  }
}

class BillingFeature {
  const BillingFeature({
    required this.code,
    required this.label,
    required this.included,
    this.description = '',
  });

  final String code;
  final String label;
  final String description;
  final bool included;

  factory BillingFeature.fromMap(Map<String, dynamic> map) {
    return BillingFeature(
      code: _string(map['code']),
      label: _string(map['label']),
      description: _string(map['description']),
      included: _boolean(map['included'], fallback: true),
    );
  }
}

class BillingProvider {
  const BillingProvider({
    required this.code,
    required this.name,
    required this.description,
    required this.paymentMethods,
    required this.enabled,
    required this.recommended,
  });

  final String code;
  final String name;
  final String description;
  final List<String> paymentMethods;
  final bool enabled;
  final bool recommended;

  factory BillingProvider.fromMap(Map<String, dynamic> map) {
    return BillingProvider(
      code: _string(map['code']),
      name: _string(map['name']),
      description: _string(map['description']),
      paymentMethods: _stringList(map['paymentMethods']),
      enabled: _boolean(map['enabled'], fallback: true),
      recommended: _boolean(map['recommended']),
    );
  }
}

class BillingSubscription {
  const BillingSubscription({
    required this.id,
    required this.status,
    required this.statusLabel,
    required this.planId,
    required this.planCode,
    required this.planName,
    required this.billingCycle,
    required this.amount,
    required this.currency,
    required this.provider,
    required this.providerLabel,
    required this.paymentMethodLabel,
    required this.cancelAtPeriodEnd,
    required this.features,
    required this.addOnCodes,
    required this.limits,
    this.currentPeriodStart,
    this.currentPeriodEnd,
    this.trialEnd,
    this.accessUntil,
  });

  final String id;
  final String status;
  final String statusLabel;
  final String planId;
  final String planCode;
  final String planName;
  final String billingCycle;
  final double amount;
  final String currency;
  final String provider;
  final String providerLabel;
  final String paymentMethodLabel;
  final bool cancelAtPeriodEnd;
  final List<String> features;
  final List<String> addOnCodes;
  final Map<String, int> limits;
  final DateTime? currentPeriodStart;
  final DateTime? currentPeriodEnd;
  final DateTime? trialEnd;
  final DateTime? accessUntil;

  factory BillingSubscription.fromMap(Map<String, dynamic> map) {
    return BillingSubscription(
      id: _string(map['id'], fallback: _string(map['objectId'])),
      status: _string(map['status'], fallback: 'inactive'),
      statusLabel: _string(
        map['statusLabel'],
        fallback: billingStatusLabel(_string(map['status'])),
      ),
      planId: _string(map['planId']),
      planCode: _string(map['planCode']),
      planName: _string(map['planName']),
      billingCycle: _string(map['billingCycle'], fallback: 'monthly'),
      amount: _decimal(map['amount']),
      currency: _string(map['currency'], fallback: 'BRL'),
      provider: _string(map['provider']),
      providerLabel: _string(map['providerLabel']),
      paymentMethodLabel: _string(map['paymentMethodLabel']),
      cancelAtPeriodEnd: _boolean(map['cancelAtPeriodEnd']),
      features: _stringList(map['features']),
      addOnCodes: _stringList(map['addOnCodes']),
      limits: _intMap(map['limits']),
      currentPeriodStart: _date(map['currentPeriodStart']),
      currentPeriodEnd: _date(map['currentPeriodEnd']),
      trialEnd: _date(map['trialEnd']),
      accessUntil: _date(map['accessUntil']),
    );
  }

  bool get grantsAccess => const {
        'trialing',
        'active',
        'past_due_grace',
      }.contains(status);

  bool get needsPaymentAttention => const {
        'pending',
        'past_due',
        'unpaid',
      }.contains(status);

  bool hasFeature(String code) => features.contains(code);
}

class BillingInvoice {
  const BillingInvoice({
    required this.id,
    required this.description,
    required this.status,
    required this.statusLabel,
    required this.amount,
    required this.currency,
    required this.invoiceUrl,
    this.dueAt,
    this.paidAt,
  });

  final String id;
  final String description;
  final String status;
  final String statusLabel;
  final double amount;
  final String currency;
  final String? invoiceUrl;
  final DateTime? dueAt;
  final DateTime? paidAt;

  factory BillingInvoice.fromMap(Map<String, dynamic> map) {
    return BillingInvoice(
      id: _string(map['id'], fallback: _string(map['objectId'])),
      description: _string(map['description'], fallback: 'Mensalidade'),
      status: _string(map['status'], fallback: 'pending'),
      statusLabel: _string(
        map['statusLabel'],
        fallback: billingInvoiceStatusLabel(_string(map['status'])),
      ),
      amount: _decimal(map['amount']),
      currency: _string(map['currency'], fallback: 'BRL'),
      invoiceUrl: _nullableString(map['invoiceUrl']),
      dueAt: _date(map['dueAt']),
      paidAt: _date(map['paidAt']),
    );
  }
}

class BillingPermissions {
  const BillingPermissions({
    required this.canViewBilling,
    required this.canManageBilling,
    required this.canSubscribe,
    required this.canCancel,
    required this.canViewInvoices,
  });

  final bool canViewBilling;
  final bool canManageBilling;
  final bool canSubscribe;
  final bool canCancel;
  final bool canViewInvoices;

  factory BillingPermissions.fromMap(Map<String, dynamic> map) {
    return BillingPermissions(
      canViewBilling: _boolean(map['canViewBilling'], fallback: true),
      canManageBilling: _boolean(map['canManageBilling']),
      canSubscribe: _boolean(map['canSubscribe']),
      canCancel: _boolean(map['canCancel']),
      canViewInvoices: _boolean(map['canViewInvoices'], fallback: true),
    );
  }
}

class BillingCheckoutSession {
  const BillingCheckoutSession({
    required this.checkoutId,
    required this.checkoutUrl,
    required this.provider,
    required this.status,
    required this.amount,
    required this.currency,
    this.expiresAt,
  });

  final String checkoutId;
  final String checkoutUrl;
  final String provider;
  final String status;
  final double amount;
  final String currency;
  final DateTime? expiresAt;

  factory BillingCheckoutSession.fromMap(Map<String, dynamic> map) {
    return BillingCheckoutSession(
      checkoutId: _string(map['checkoutId']),
      checkoutUrl: _string(map['checkoutUrl']),
      provider: _string(map['provider']),
      status: _string(map['status'], fallback: 'pending'),
      amount: _decimal(map['amount']),
      currency: _string(map['currency'], fallback: 'BRL'),
      expiresAt: _date(map['expiresAt']),
    );
  }
}

class BillingVerification {
  const BillingVerification({
    required this.status,
    required this.message,
    required this.paid,
    this.subscription,
  });

  final String status;
  final String message;
  final bool paid;
  final BillingSubscription? subscription;

  factory BillingVerification.fromMap(Map<String, dynamic> map) {
    return BillingVerification(
      status: _string(map['status'], fallback: 'pending'),
      message: _string(map['message']),
      paid: _boolean(map['paid']),
      subscription: map['subscription'] is Map
          ? BillingSubscription.fromMap(_mapValue(map['subscription']))
          : null,
    );
  }
}

class BillingPortalSession {
  const BillingPortalSession({
    required this.portalUrl,
    required this.provider,
  });

  final String portalUrl;
  final String provider;

  factory BillingPortalSession.fromMap(Map<String, dynamic> map) {
    return BillingPortalSession(
      portalUrl: _string(map['portalUrl']),
      provider: _string(map['provider']),
    );
  }
}

String billingStatusLabel(String status) {
  switch (status) {
    case 'trialing':
      return 'Período de teste';
    case 'active':
      return 'Ativa';
    case 'pending':
      return 'Aguardando pagamento';
    case 'past_due_grace':
      return 'Pagamento em atraso';
    case 'past_due':
      return 'Pagamento pendente';
    case 'unpaid':
      return 'Não paga';
    case 'canceled':
      return 'Cancelada';
    case 'expired':
      return 'Expirada';
    default:
      return 'Sem assinatura';
  }
}

String billingInvoiceStatusLabel(String status) {
  switch (status) {
    case 'paid':
      return 'Pago';
    case 'processing':
      return 'Processando';
    case 'overdue':
      return 'Vencido';
    case 'void':
      return 'Cancelado';
    case 'refunded':
      return 'Estornado';
    default:
      return 'Pendente';
  }
}

Map<String, dynamic> _mapValue(dynamic value) {
  return value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
}

List<Map<String, dynamic>> _mapList(dynamic value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList();
}

Map<String, int> _intMap(dynamic value) {
  if (value is! Map) return const {};
  return Map<String, dynamic>.from(value).map(
    (key, entry) => MapEntry(key, _integer(entry)),
  );
}

List<String> _stringList(dynamic value) {
  if (value is! List) return const [];
  return value
      .map((item) => item?.toString().trim() ?? '')
      .where((item) => item.isNotEmpty)
      .toList();
}

String _string(dynamic value, {String fallback = ''}) {
  final result = value?.toString().trim() ?? '';
  return result.isEmpty ? fallback : result;
}

String? _nullableString(dynamic value) {
  final result = value?.toString().trim() ?? '';
  return result.isEmpty ? null : result;
}

int _integer(dynamic value, {int fallback = 0}) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

double _decimal(dynamic value, {double fallback = 0}) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString().replaceAll(',', '.') ?? '') ??
      fallback;
}

bool _boolean(dynamic value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final normalized = value?.toString().toLowerCase();
  if (normalized == 'true' || normalized == '1') return true;
  if (normalized == 'false' || normalized == '0') return false;
  return fallback;
}

DateTime? _date(dynamic value) {
  if (value is DateTime) return value;
  if (value is Map && value['iso'] != null) {
    return DateTime.tryParse(value['iso'].toString());
  }
  return DateTime.tryParse(value?.toString() ?? '');
}

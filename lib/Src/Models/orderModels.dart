class OrderListResult {
  const OrderListResult({
    required this.orders,
    required this.pagination,
    required this.filterOptions,
  });

  final List<OrderSummary> orders;
  final OrderPagination pagination;
  final OrderFilterOptions filterOptions;

  factory OrderListResult.fromMap(Map<String, dynamic> map) {
    return OrderListResult(
      orders: _mapList(map['orders']).map(OrderSummary.fromMap).toList(),
      pagination: OrderPagination.fromMap(_mapValue(map['pagination'])),
      filterOptions:
          OrderFilterOptions.fromMap(_mapValue(map['filterOptions'])),
    );
  }
}

class OrderSummary {
  const OrderSummary({
    required this.id,
    required this.number,
    required this.issueDate,
    required this.status,
    required this.statusLabel,
    required this.customer,
    required this.representedCompanyName,
    required this.sellerName,
    required this.itemCount,
    required this.total,
    required this.invoiced,
    required this.completed,
  });

  final String id;
  final String number;
  final DateTime? issueDate;
  final String status;
  final String statusLabel;
  final OrderClient customer;
  final String representedCompanyName;
  final String sellerName;
  final int itemCount;
  final double total;
  final bool invoiced;
  final bool completed;

  factory OrderSummary.fromMap(Map<String, dynamic> map) {
    return OrderSummary(
      id: _string(map['id']),
      number: _string(map['number']),
      issueDate: DateTime.tryParse(_string(map['issueDate'])),
      status: _string(map['status'], fallback: 'draft'),
      statusLabel: _string(map['statusLabel'], fallback: 'Em orçamento'),
      customer: OrderClient.fromMap(_mapValue(map['customer'])),
      representedCompanyName: _string(map['representedCompanyName']),
      sellerName: _string(map['sellerName']),
      itemCount: _integer(map['itemCount']),
      total: _double(map['total']),
      invoiced: _boolean(map['invoiced']),
      completed: _boolean(map['completed']),
    );
  }
}

class OrderFilterOptions {
  const OrderFilterOptions({
    required this.statuses,
    required this.sellers,
  });

  final List<OrderSelectOption> statuses;
  final List<OrderSelectOption> sellers;

  factory OrderFilterOptions.fromMap(Map<String, dynamic> map) {
    return OrderFilterOptions(
      statuses:
          _mapList(map['statuses']).map(OrderSelectOption.fromMap).toList(),
      sellers:
          _mapList(map['sellers']).map(OrderSelectOption.fromMap).toList(),
    );
  }
}

class OrderPagination {
  const OrderPagination({
    required this.page,
    required this.pageSize,
    required this.totalItems,
    required this.totalPages,
    required this.hasNextPage,
  });

  final int page;
  final int pageSize;
  final int totalItems;
  final int totalPages;
  final bool hasNextPage;

  factory OrderPagination.fromMap(Map<String, dynamic> map) {
    return OrderPagination(
      page: _integer(map['page'], fallback: 1),
      pageSize: _integer(map['pageSize'], fallback: 20),
      totalItems: _integer(map['totalItems']),
      totalPages: _integer(map['totalPages']),
      hasNextPage: _boolean(map['hasNextPage']),
    );
  }
}

class OrderFormOptions {
  const OrderFormOptions({
    required this.nextNumber,
    required this.issueDate,
    required this.representedCompany,
    required this.paymentTerms,
    required this.carriers,
    required this.defaultStatus,
    required this.permissions,
  });

  final String nextNumber;
  final DateTime? issueDate;
  final OrderCompany representedCompany;
  final List<OrderSelectOption> paymentTerms;
  final List<OrderSelectOption> carriers;
  final String defaultStatus;
  final OrderPermissions permissions;

  factory OrderFormOptions.fromMap(Map<String, dynamic> map) {
    return OrderFormOptions(
      nextNumber: _string(map['nextNumber']),
      issueDate: DateTime.tryParse(_string(map['issueDate'])),
      representedCompany:
          OrderCompany.fromMap(_mapValue(map['representedCompany'])),
      paymentTerms: _mapList(map['paymentTerms'])
          .map(OrderSelectOption.fromMap)
          .toList(),
      carriers:
          _mapList(map['carriers']).map(OrderSelectOption.fromMap).toList(),
      defaultStatus: _string(map['defaultStatus'], fallback: 'draft'),
      permissions:
          OrderPermissions.fromMap(_mapValue(map['permissions'])),
    );
  }
}

class OrderPermissions {
  const OrderPermissions({
    required this.canEdit,
    required this.canConfirm,
    required this.canCancel,
    required this.canDuplicate,
    required this.canSendEmail,
    required this.canDownloadPdf,
  });

  final bool canEdit;
  final bool canConfirm;
  final bool canCancel;
  final bool canDuplicate;
  final bool canSendEmail;
  final bool canDownloadPdf;

  factory OrderPermissions.fromMap(Map<String, dynamic> map) {
    return OrderPermissions(
      canEdit: _boolean(map['canEdit'], fallback: true),
      canConfirm: _boolean(map['canConfirm'], fallback: true),
      canCancel: _boolean(map['canCancel'], fallback: true),
      canDuplicate: _boolean(map['canDuplicate'], fallback: true),
      canSendEmail: _boolean(map['canSendEmail'], fallback: true),
      canDownloadPdf: _boolean(map['canDownloadPdf'], fallback: true),
    );
  }

  static const all = OrderPermissions(
    canEdit: true,
    canConfirm: true,
    canCancel: true,
    canDuplicate: true,
    canSendEmail: true,
    canDownloadPdf: true,
  );
}

class OrderDetail {
  const OrderDetail({
    required this.id,
    required this.number,
    required this.issueDate,
    required this.status,
    required this.statusLabel,
    required this.customer,
    required this.representedCompany,
    required this.items,
    required this.paymentTerm,
    required this.shippingCost,
    required this.carrier,
    required this.trackingCode,
    required this.expectedDeliveryDate,
    required this.deliveryAddress,
    required this.customerContact,
    required this.notes,
    required this.totals,
    required this.sellerName,
    required this.permissions,
  });

  final String? id;
  final String number;
  final DateTime? issueDate;
  final String status;
  final String statusLabel;
  final OrderClient? customer;
  final OrderCompany representedCompany;
  final List<OrderLineItem> items;
  final OrderSelectOption? paymentTerm;
  final double shippingCost;
  final OrderSelectOption? carrier;
  final String trackingCode;
  final DateTime? expectedDeliveryDate;
  final String deliveryAddress;
  final String customerContact;
  final String notes;
  final OrderTotals totals;
  final String sellerName;
  final OrderPermissions permissions;

  bool get isPersisted => id != null && id!.isNotEmpty;

  factory OrderDetail.fromMap(Map<String, dynamic> map) {
    return OrderDetail(
      id: _nullableString(map['id']),
      number: _string(map['number']),
      issueDate: DateTime.tryParse(_string(map['issueDate'])),
      status: _string(map['status'], fallback: 'draft'),
      statusLabel: _string(map['statusLabel'], fallback: 'Em orçamento'),
      customer: map['customer'] is Map
          ? OrderClient.fromMap(_mapValue(map['customer']))
          : null,
      representedCompany:
          OrderCompany.fromMap(_mapValue(map['representedCompany'])),
      items:
          _mapList(map['items']).map(OrderLineItem.fromMap).toList(),
      paymentTerm: map['paymentTerm'] is Map
          ? OrderSelectOption.fromMap(_mapValue(map['paymentTerm']))
          : null,
      shippingCost: _double(map['shippingCost']),
      carrier: map['carrier'] is Map
          ? OrderSelectOption.fromMap(_mapValue(map['carrier']))
          : null,
      trackingCode: _string(map['trackingCode']),
      expectedDeliveryDate:
          DateTime.tryParse(_string(map['expectedDeliveryDate'])),
      deliveryAddress: _string(map['deliveryAddress']),
      customerContact: _string(map['customerContact']),
      notes: _string(map['notes']),
      totals: OrderTotals.fromMap(_mapValue(map['totals'])),
      sellerName: _string(map['sellerName']),
      permissions:
          OrderPermissions.fromMap(_mapValue(map['permissions'])),
    );
  }

  factory OrderDetail.empty(OrderFormOptions options) {
    return OrderDetail(
      id: null,
      number: options.nextNumber,
      issueDate: options.issueDate ?? DateTime.now(),
      status: options.defaultStatus,
      statusLabel: 'Em orçamento',
      customer: null,
      representedCompany: options.representedCompany,
      items: const [],
      paymentTerm: null,
      shippingCost: 0,
      carrier: null,
      trackingCode: '',
      expectedDeliveryDate: null,
      deliveryAddress: '',
      customerContact: '',
      notes: '',
      totals: const OrderTotals.zero(),
      sellerName: '',
      permissions: options.permissions,
    );
  }

  OrderDetail copyWith({
    String? id,
    String? number,
    DateTime? issueDate,
    String? status,
    String? statusLabel,
    OrderClient? customer,
    bool clearCustomer = false,
    OrderCompany? representedCompany,
    List<OrderLineItem>? items,
    OrderSelectOption? paymentTerm,
    bool clearPaymentTerm = false,
    double? shippingCost,
    OrderSelectOption? carrier,
    bool clearCarrier = false,
    String? trackingCode,
    DateTime? expectedDeliveryDate,
    bool clearExpectedDeliveryDate = false,
    String? deliveryAddress,
    String? customerContact,
    String? notes,
    OrderTotals? totals,
    String? sellerName,
    OrderPermissions? permissions,
  }) {
    return OrderDetail(
      id: id ?? this.id,
      number: number ?? this.number,
      issueDate: issueDate ?? this.issueDate,
      status: status ?? this.status,
      statusLabel: statusLabel ?? this.statusLabel,
      customer: clearCustomer ? null : customer ?? this.customer,
      representedCompany: representedCompany ?? this.representedCompany,
      items: items ?? this.items,
      paymentTerm:
          clearPaymentTerm ? null : paymentTerm ?? this.paymentTerm,
      shippingCost: shippingCost ?? this.shippingCost,
      carrier: clearCarrier ? null : carrier ?? this.carrier,
      trackingCode: trackingCode ?? this.trackingCode,
      expectedDeliveryDate: clearExpectedDeliveryDate
          ? null
          : expectedDeliveryDate ?? this.expectedDeliveryDate,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      customerContact: customerContact ?? this.customerContact,
      notes: notes ?? this.notes,
      totals: totals ?? this.totals,
      sellerName: sellerName ?? this.sellerName,
      permissions: permissions ?? this.permissions,
    );
  }

  Map<String, dynamic> toRequest() {
    return {
      if (id != null) 'orderId': id,
      'number': number,
      'issueDate': _dateOnly(issueDate),
      'customerId': customer?.id,
      'items': items.map((item) => item.toRequest()).toList(),
      'paymentTermId': paymentTerm?.id,
      'shippingCost': shippingCost,
      'carrierId': carrier?.id,
      'trackingCode': trackingCode.trim(),
      'expectedDeliveryDate': _dateOnly(expectedDeliveryDate),
      'deliveryAddress': deliveryAddress.trim(),
      'customerContact': customerContact.trim(),
      'notes': notes.trim(),
    };
  }
}

class OrderClient {
  const OrderClient({
    required this.id,
    required this.name,
    required this.tradeName,
    required this.document,
    required this.email,
    required this.phone,
    required this.addresses,
  });

  final String id;
  final String name;
  final String tradeName;
  final String document;
  final String email;
  final String phone;
  final List<OrderAddress> addresses;

  String get displayName => tradeName.isEmpty ? name : tradeName;

  factory OrderClient.fromMap(Map<String, dynamic> map) {
    return OrderClient(
      id: _string(map['id']),
      name: _string(map['name']),
      tradeName: _string(map['tradeName']),
      document: _string(map['document']),
      email: _string(map['email']),
      phone: _string(map['phone']),
      addresses:
          _mapList(map['addresses']).map(OrderAddress.fromMap).toList(),
    );
  }
}

class OrderAddress {
  const OrderAddress({
    required this.id,
    required this.label,
    required this.formatted,
    required this.primary,
  });

  final String id;
  final String label;
  final String formatted;
  final bool primary;

  factory OrderAddress.fromMap(Map<String, dynamic> map) {
    return OrderAddress(
      id: _string(map['id']),
      label: _string(map['label']),
      formatted: _string(map['formatted']),
      primary: _boolean(map['primary']),
    );
  }
}

class OrderCompany {
  const OrderCompany({
    required this.id,
    required this.name,
    required this.legalName,
    required this.document,
    required this.email,
    required this.phone,
  });

  final String id;
  final String name;
  final String legalName;
  final String document;
  final String email;
  final String phone;

  factory OrderCompany.fromMap(Map<String, dynamic> map) {
    return OrderCompany(
      id: _string(map['id']),
      name: _string(map['name']),
      legalName: _string(map['legalName']),
      document: _string(map['document']),
      email: _string(map['email']),
      phone: _string(map['phone']),
    );
  }
}

class OrderProduct {
  const OrderProduct({
    required this.id,
    required this.code,
    required this.name,
    required this.unit,
    required this.listPrice,
    required this.availableStock,
    required this.minimumQuantity,
  });

  final String id;
  final String code;
  final String name;
  final String unit;
  final double listPrice;
  final double? availableStock;
  final double minimumQuantity;

  factory OrderProduct.fromMap(Map<String, dynamic> map) {
    return OrderProduct(
      id: _string(map['id']),
      code: _string(map['code']),
      name: _string(map['name']),
      unit: _string(map['unit'], fallback: 'UN'),
      listPrice: _double(map['listPrice']),
      availableStock:
          map['availableStock'] == null ? null : _double(map['availableStock']),
      minimumQuantity: _double(map['minimumQuantity'], fallback: 1),
    );
  }
}

class OrderLineItem {
  const OrderLineItem({
    required this.id,
    required this.productId,
    required this.code,
    required this.name,
    required this.unit,
    required this.quantity,
    required this.listPrice,
    required this.discountPercent,
    required this.netPrice,
    required this.subtotal,
  });

  final String? id;
  final String productId;
  final String code;
  final String name;
  final String unit;
  final double quantity;
  final double listPrice;
  final double discountPercent;
  final double netPrice;
  final double subtotal;

  factory OrderLineItem.fromMap(Map<String, dynamic> map) {
    return OrderLineItem(
      id: _nullableString(map['id']),
      productId: _string(map['productId']),
      code: _string(map['code']),
      name: _string(map['name']),
      unit: _string(map['unit'], fallback: 'UN'),
      quantity: _double(map['quantity'], fallback: 1),
      listPrice: _double(map['listPrice']),
      discountPercent: _double(map['discountPercent']),
      netPrice: _double(map['netPrice']),
      subtotal: _double(map['subtotal']),
    );
  }

  factory OrderLineItem.fromProduct(OrderProduct product) {
    final quantity = product.minimumQuantity <= 0 ? 1.0 : product.minimumQuantity;
    return OrderLineItem(
      id: null,
      productId: product.id,
      code: product.code,
      name: product.name,
      unit: product.unit,
      quantity: quantity,
      listPrice: product.listPrice,
      discountPercent: 0,
      netPrice: product.listPrice,
      subtotal: product.listPrice * quantity,
    );
  }

  OrderLineItem copyWith({double? quantity, double? discountPercent}) {
    final nextQuantity = quantity ?? this.quantity;
    final nextDiscount = discountPercent ?? this.discountPercent;
    final nextNetPrice = listPrice * (1 - nextDiscount / 100);
    return OrderLineItem(
      id: id,
      productId: productId,
      code: code,
      name: name,
      unit: unit,
      quantity: nextQuantity,
      listPrice: listPrice,
      discountPercent: nextDiscount,
      netPrice: nextNetPrice,
      subtotal: nextNetPrice * nextQuantity,
    );
  }

  Map<String, dynamic> toRequest() {
    return {
      if (id != null) 'itemId': id,
      'productId': productId,
      'quantity': quantity,
      'discountPercent': discountPercent,
    };
  }
}

class OrderTotals {
  const OrderTotals({
    required this.itemsSubtotal,
    required this.discountTotal,
    required this.shippingCost,
    required this.grandTotal,
  });

  const OrderTotals.zero()
      : itemsSubtotal = 0,
        discountTotal = 0,
        shippingCost = 0,
        grandTotal = 0;

  final double itemsSubtotal;
  final double discountTotal;
  final double shippingCost;
  final double grandTotal;

  factory OrderTotals.fromMap(Map<String, dynamic> map) {
    return OrderTotals(
      itemsSubtotal: _double(map['itemsSubtotal']),
      discountTotal: _double(map['discountTotal']),
      shippingCost: _double(map['shippingCost']),
      grandTotal: _double(map['grandTotal']),
    );
  }

  factory OrderTotals.calculate(
    List<OrderLineItem> items,
    double shippingCost,
  ) {
    var gross = 0.0;
    var net = 0.0;
    for (final item in items) {
      gross += item.listPrice * item.quantity;
      net += item.subtotal;
    }
    return OrderTotals(
      itemsSubtotal: gross,
      discountTotal: gross - net,
      shippingCost: shippingCost,
      grandTotal: net + shippingCost,
    );
  }
}

class OrderSelectOption {
  const OrderSelectOption({required this.id, required this.label});

  final String id;
  final String label;

  factory OrderSelectOption.fromMap(Map<String, dynamic> map) {
    return OrderSelectOption(
      id: _string(map['id'], fallback: _string(map['value'])),
      label: _string(map['label']),
    );
  }
}

class OrderPreview {
  const OrderPreview({
    required this.order,
    required this.documentTitle,
    required this.portalUrl,
    required this.defaultEmail,
  });

  final OrderDetail order;
  final String documentTitle;
  final String? portalUrl;
  final String defaultEmail;

  factory OrderPreview.fromMap(Map<String, dynamic> map) {
    return OrderPreview(
      order: OrderDetail.fromMap(_mapValue(map['order'])),
      documentTitle:
          _string(map['documentTitle'], fallback: 'Pedido comercial'),
      portalUrl: _nullableString(map['portalUrl']),
      defaultEmail: _string(map['defaultEmail']),
    );
  }
}

class OrderDocumentJob {
  const OrderDocumentJob({
    required this.id,
    required this.status,
    required this.progressPercent,
    required this.fileName,
    required this.downloadUrl,
    required this.expiresAt,
  });

  final String id;
  final String status;
  final double? progressPercent;
  final String? fileName;
  final String? downloadUrl;
  final DateTime? expiresAt;

  bool get isFinished =>
      status == 'ready' || status == 'failed' || status == 'expired';

  factory OrderDocumentJob.fromMap(Map<String, dynamic> map) {
    return OrderDocumentJob(
      id: _string(map['documentId']),
      status: _string(map['status'], fallback: 'queued'),
      progressPercent: map['progressPercent'] == null
          ? null
          : _double(map['progressPercent']),
      fileName: _nullableString(map['fileName']),
      downloadUrl: _nullableString(map['downloadUrl']),
      expiresAt: DateTime.tryParse(_string(map['expiresAt'])),
    );
  }
}

class OrderEmailResult {
  const OrderEmailResult({
    required this.sent,
    required this.recipient,
    required this.sentAt,
  });

  final bool sent;
  final String recipient;
  final DateTime? sentAt;

  factory OrderEmailResult.fromMap(Map<String, dynamic> map) {
    return OrderEmailResult(
      sent: _boolean(map['sent']),
      recipient: _string(map['recipient']),
      sentAt: DateTime.tryParse(_string(map['sentAt'])),
    );
  }
}

Map<String, dynamic> _mapValue(dynamic value) {
  return value is Map
      ? Map<String, dynamic>.from(value)
      : <String, dynamic>{};
}

List<Map<String, dynamic>> _mapList(dynamic value) {
  if (value is! List) return <Map<String, dynamic>>[];
  return value
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList();
}

String _string(dynamic value, {String fallback = ''}) {
  final text = value?.toString() ?? '';
  return text.isEmpty ? fallback : text;
}

String? _nullableString(dynamic value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

double _double(dynamic value, {double fallback = 0}) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}

int _integer(dynamic value, {int fallback = 0}) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

bool _boolean(dynamic value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value?.toString().toLowerCase() == 'true') return true;
  if (value?.toString().toLowerCase() == 'false') return false;
  return fallback;
}

String? _dateOnly(DateTime? value) {
  if (value == null) return null;
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '${value.year}-$month-$day';
}

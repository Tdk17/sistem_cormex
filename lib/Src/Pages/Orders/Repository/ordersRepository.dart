import 'package:sistem_cormex/Src/Connection/endpoints.dart';
import 'package:sistem_cormex/Src/Connection/httpManager.dart';
import 'package:sistem_cormex/Src/Models/orderModels.dart';

abstract interface class OrdersRepository {
  Future<OrderListResult> listOrders({
    required String sessionToken,
    required int page,
    required int pageSize,
    required String query,
    String? status,
    String? sellerId,
    DateTime? dateFrom,
    DateTime? dateTo,
  });

  Future<OrderFormOptions> getFormOptions({required String sessionToken});

  Future<List<OrderClient>> searchClients({
    required String sessionToken,
    required String query,
  });

  Future<List<OrderProduct>> searchProducts({
    required String sessionToken,
    required String query,
    String? customerId,
  });

  Future<OrderDetail> getOrder({
    required String sessionToken,
    required String orderId,
  });

  Future<OrderDetail> saveOrder({
    required String sessionToken,
    required Map<String, dynamic> order,
  });

  Future<OrderDetail> confirmOrder({
    required String sessionToken,
    required String orderId,
  });

  Future<OrderPreview> getPreview({
    required String sessionToken,
    required String orderId,
  });

  Future<OrderDocumentJob> requestPdf({
    required String sessionToken,
    required String orderId,
  });

  Future<OrderDocumentJob> getDocumentStatus({
    required String sessionToken,
    required String documentId,
  });

  Future<OrderEmailResult> sendEmail({
    required String sessionToken,
    required String orderId,
    required String recipient,
    required String subject,
    required String message,
  });

  Future<OrderDetail> cancelOrder({
    required String sessionToken,
    required String orderId,
    required String reason,
  });

  Future<OrderDetail> duplicateOrder({
    required String sessionToken,
    required String orderId,
  });
}

class ParseOrdersRepository implements OrdersRepository {
  const ParseOrdersRepository(this._httpManager);

  final HttpManager _httpManager;

  @override
  Future<OrderListResult> listOrders({
    required String sessionToken,
    required int page,
    required int pageSize,
    required String query,
    String? status,
    String? sellerId,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    final result = await _post(
      Endpoints.ordersList,
      sessionToken,
      {
        'page': page,
        'pageSize': pageSize,
        'query': query.trim(),
        'status': status,
        'sellerId': sellerId,
        'dateFrom': _dateOnly(dateFrom),
        'dateTo': _dateOnly(dateTo),
      },
    );
    return OrderListResult.fromMap(result);
  }

  @override
  Future<OrderFormOptions> getFormOptions({
    required String sessionToken,
  }) async {
    final result = await _post(
      Endpoints.ordersFormOptions,
      sessionToken,
      const {},
    );
    return OrderFormOptions.fromMap(result);
  }

  @override
  Future<List<OrderClient>> searchClients({
    required String sessionToken,
    required String query,
  }) async {
    final result = await _post(
      Endpoints.ordersSearchClients,
      sessionToken,
      {'query': query.trim(), 'limit': 20},
    );
    return _mapList(result['clients']).map(OrderClient.fromMap).toList();
  }

  @override
  Future<List<OrderProduct>> searchProducts({
    required String sessionToken,
    required String query,
    String? customerId,
  }) async {
    final result = await _post(
      Endpoints.ordersSearchProducts,
      sessionToken,
      {
        'query': query.trim(),
        'customerId': customerId,
        'limit': 30,
      },
    );
    return _mapList(result['products']).map(OrderProduct.fromMap).toList();
  }

  @override
  Future<OrderDetail> getOrder({
    required String sessionToken,
    required String orderId,
  }) async {
    final result = await _post(
      Endpoints.ordersGet,
      sessionToken,
      {'orderId': orderId},
    );
    return OrderDetail.fromMap(_orderMap(result));
  }

  @override
  Future<OrderDetail> saveOrder({
    required String sessionToken,
    required Map<String, dynamic> order,
  }) async {
    final result = await _post(Endpoints.ordersSave, sessionToken, order);
    return OrderDetail.fromMap(_orderMap(result));
  }

  @override
  Future<OrderDetail> confirmOrder({
    required String sessionToken,
    required String orderId,
  }) async {
    final result = await _post(
      Endpoints.ordersConfirm,
      sessionToken,
      {'orderId': orderId},
    );
    return OrderDetail.fromMap(_orderMap(result));
  }

  @override
  Future<OrderPreview> getPreview({
    required String sessionToken,
    required String orderId,
  }) async {
    final result = await _post(
      Endpoints.ordersPreview,
      sessionToken,
      {'orderId': orderId},
    );
    return OrderPreview.fromMap(result);
  }

  @override
  Future<OrderDocumentJob> requestPdf({
    required String sessionToken,
    required String orderId,
  }) async {
    final result = await _post(
      Endpoints.ordersPdf,
      sessionToken,
      {'orderId': orderId},
    );
    return OrderDocumentJob.fromMap(result);
  }

  @override
  Future<OrderDocumentJob> getDocumentStatus({
    required String sessionToken,
    required String documentId,
  }) async {
    final result = await _post(
      Endpoints.ordersDocumentStatus,
      sessionToken,
      {'documentId': documentId},
    );
    return OrderDocumentJob.fromMap(result);
  }

  @override
  Future<OrderEmailResult> sendEmail({
    required String sessionToken,
    required String orderId,
    required String recipient,
    required String subject,
    required String message,
  }) async {
    final result = await _post(
      Endpoints.ordersSendEmail,
      sessionToken,
      {
        'orderId': orderId,
        'recipient': recipient.trim(),
        'subject': subject.trim(),
        'message': message.trim(),
        'attachPdf': true,
      },
    );
    return OrderEmailResult.fromMap(result);
  }

  @override
  Future<OrderDetail> cancelOrder({
    required String sessionToken,
    required String orderId,
    required String reason,
  }) async {
    final result = await _post(
      Endpoints.ordersCancel,
      sessionToken,
      {'orderId': orderId, 'reason': reason.trim()},
    );
    return OrderDetail.fromMap(_orderMap(result));
  }

  @override
  Future<OrderDetail> duplicateOrder({
    required String sessionToken,
    required String orderId,
  }) async {
    final result = await _post(
      Endpoints.ordersDuplicate,
      sessionToken,
      {'orderId': orderId},
    );
    return OrderDetail.fromMap(_orderMap(result));
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
      'O servidor retornou uma resposta inválida para Pedidos.',
    );
  }

  Map<String, dynamic> _orderMap(Map<String, dynamic> result) {
    final order = result['order'];
    return order is Map ? Map<String, dynamic>.from(order) : result;
  }

  List<Map<String, dynamic>> _mapList(dynamic value) {
    if (value is! List) return <Map<String, dynamic>>[];
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  String? _dateOnly(DateTime? value) {
    if (value == null) return null;
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
}

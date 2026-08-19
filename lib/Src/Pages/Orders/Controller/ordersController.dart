import 'package:signals/signals.dart';
import 'package:sistem_cormex/Src/Connection/apiException.dart';
import 'package:sistem_cormex/Src/Models/orderModels.dart';
import 'package:sistem_cormex/Src/Pages/Auth/Controller/authController.dart';
import 'package:sistem_cormex/Src/Pages/Orders/Repository/ordersRepository.dart';

class OrdersController {
  OrdersController(this._repository, this._authController);

  final OrdersRepository _repository;
  final AuthController _authController;
  String? _dataSessionToken;
  int _listRequestId = 0;
  int _clientSearchId = 0;
  int _productSearchId = 0;

  final listLoading = signal(false);
  final listError = signal<String?>(null);
  final orders = signal<List<OrderSummary>>([]);
  final pagination = signal<OrderPagination?>(null);
  final filterOptions = signal<OrderFilterOptions?>(null);
  final query = signal('');
  final selectedStatus = signal<String?>(null);
  final selectedSellerId = signal<String?>(null);
  final dateFrom = signal<DateTime?>(null);
  final dateTo = signal<DateTime?>(null);

  final formLoading = signal(false);
  final formError = signal<String?>(null);
  final formOptions = signal<OrderFormOptions?>(null);
  final editingOrder = signal<OrderDetail?>(null);
  final saving = signal(false);
  final actionLoading = signal(false);
  final lastSavedAt = signal<DateTime?>(null);

  final clientSearchLoading = signal(false);
  final clientResults = signal<List<OrderClient>>([]);
  final productSearchLoading = signal(false);
  final productResults = signal<List<OrderProduct>>([]);

  final previewLoading = signal(false);
  final previewError = signal<String?>(null);
  final preview = signal<OrderPreview?>(null);

  final documentLoading = signal(false);
  final documentJob = signal<OrderDocumentJob?>(null);
  final emailSending = signal(false);
  final emailResult = signal<OrderEmailResult?>(null);

  Future<void> initializeList() async {
    _synchronizeSession();
    if (orders.value.isEmpty) await loadOrders();
  }

  Future<void> loadOrders({int page = 1}) async {
    final requestId = ++_listRequestId;
    batch(() {
      listLoading.value = true;
      listError.value = null;
    });
    try {
      final result = await _repository.listOrders(
        sessionToken: _sessionToken,
        page: page,
        pageSize: 20,
        query: query.value,
        status: selectedStatus.value,
        sellerId: selectedSellerId.value,
        dateFrom: dateFrom.value,
        dateTo: dateTo.value,
      );
      if (requestId != _listRequestId) return;
      batch(() {
        orders.value = result.orders;
        pagination.value = result.pagination;
        filterOptions.value = result.filterOptions;
      });
    } catch (error) {
      if (requestId == _listRequestId) listError.value = _messageFor(error);
    } finally {
      if (requestId == _listRequestId) listLoading.value = false;
    }
  }

  Future<void> applySearch(String value) async {
    query.value = value.trim();
    await loadOrders();
  }

  Future<void> changeStatus(String? value) async {
    selectedStatus.value = value;
    await loadOrders();
  }

  Future<void> changeSeller(String? value) async {
    selectedSellerId.value = value;
    await loadOrders();
  }

  Future<void> changeDateRange(DateTimeRangeValue? range) async {
    batch(() {
      dateFrom.value = range?.start;
      dateTo.value = range?.end;
    });
    await loadOrders();
  }

  Future<void> initializeForm(String? orderId) async {
    _synchronizeSession();
    batch(() {
      formLoading.value = true;
      formError.value = null;
      editingOrder.value = null;
      preview.value = null;
      previewError.value = null;
      documentJob.value = null;
      emailResult.value = null;
      clientResults.value = [];
      productResults.value = [];
    });
    try {
      final optionsFuture = _repository.getFormOptions(
        sessionToken: _sessionToken,
      );
      final orderFuture = orderId == null
          ? Future<OrderDetail?>.value(null)
          : _repository
              .getOrder(sessionToken: _sessionToken, orderId: orderId)
              .then<OrderDetail?>((value) => value);
      final results = await Future.wait<dynamic>([optionsFuture, orderFuture]);
      final options = results[0] as OrderFormOptions;
      final order = results[1] as OrderDetail?;
      batch(() {
        formOptions.value = options;
        editingOrder.value = order ?? OrderDetail.empty(options);
      });
    } catch (error) {
      formError.value = _messageFor(error);
    } finally {
      formLoading.value = false;
    }
  }

  Future<void> searchClients(String value) async {
    final term = value.trim();
    final requestId = ++_clientSearchId;
    if (term.length < 2) {
      clientResults.value = [];
      return;
    }
    clientSearchLoading.value = true;
    try {
      final result = await _repository.searchClients(
        sessionToken: _sessionToken,
        query: term,
      );
      if (requestId == _clientSearchId) clientResults.value = result;
    } catch (error) {
      if (requestId == _clientSearchId) formError.value = _messageFor(error);
    } finally {
      if (requestId == _clientSearchId) clientSearchLoading.value = false;
    }
  }

  void selectClient(OrderClient client) {
    final order = editingOrder.value;
    if (order == null) return;
    final primaryAddresses = client.addresses.where((item) => item.primary);
    final address = primaryAddresses.isNotEmpty
        ? primaryAddresses.first.formatted
        : client.addresses.isEmpty
            ? ''
            : client.addresses.first.formatted;
    editingOrder.value = order.copyWith(
      customer: client,
      customerContact: client.email,
      deliveryAddress: address,
    );
    clientResults.value = [];
  }

  void clearClient() {
    final order = editingOrder.value;
    if (order == null) return;
    editingOrder.value = order.copyWith(
      clearCustomer: true,
      customerContact: '',
      deliveryAddress: '',
    );
  }

  Future<void> searchProducts(String value) async {
    final term = value.trim();
    final requestId = ++_productSearchId;
    if (term.length < 2) {
      productResults.value = [];
      return;
    }
    productSearchLoading.value = true;
    try {
      final result = await _repository.searchProducts(
        sessionToken: _sessionToken,
        query: term,
        customerId: editingOrder.value?.customer?.id,
      );
      if (requestId == _productSearchId) productResults.value = result;
    } catch (error) {
      if (requestId == _productSearchId) formError.value = _messageFor(error);
    } finally {
      if (requestId == _productSearchId) productSearchLoading.value = false;
    }
  }

  void addProduct(OrderProduct product) {
    final order = editingOrder.value;
    if (order == null) return;
    final items = [...order.items];
    final index = items.indexWhere((item) => item.productId == product.id);
    if (index >= 0) {
      items[index] = items[index].copyWith(quantity: items[index].quantity + 1);
    } else {
      items.add(OrderLineItem.fromProduct(product));
    }
    _setItems(order, items);
    productResults.value = [];
  }

  void updateItem(
    int index, {
    double? quantity,
    double? discountPercent,
  }) {
    final order = editingOrder.value;
    if (order == null || index < 0 || index >= order.items.length) return;
    final items = [...order.items];
    items[index] = items[index].copyWith(
      quantity: (quantity ?? items[index].quantity)
          .clamp(.001, 999999.0)
          .toDouble(),
      discountPercent: (discountPercent ?? items[index].discountPercent)
          .clamp(0.0, 100.0)
          .toDouble(),
    );
    _setItems(order, items);
  }

  void removeItem(int index) {
    final order = editingOrder.value;
    if (order == null || index < 0 || index >= order.items.length) return;
    final items = [...order.items]..removeAt(index);
    _setItems(order, items);
  }

  void updateDetails({
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
  }) {
    final order = editingOrder.value;
    if (order == null) return;
    final nextShipping = shippingCost ?? order.shippingCost;
    editingOrder.value = order.copyWith(
      paymentTerm: paymentTerm,
      clearPaymentTerm: clearPaymentTerm,
      shippingCost: nextShipping,
      carrier: carrier,
      clearCarrier: clearCarrier,
      trackingCode: trackingCode,
      expectedDeliveryDate: expectedDeliveryDate,
      clearExpectedDeliveryDate: clearExpectedDeliveryDate,
      deliveryAddress: deliveryAddress,
      customerContact: customerContact,
      notes: notes,
      totals: OrderTotals.calculate(order.items, nextShipping),
    );
  }

  Future<bool> saveDraft() async {
    final order = editingOrder.value;
    if (order == null || saving.value) return false;
    batch(() {
      saving.value = true;
      formError.value = null;
    });
    try {
      final saved = await _repository.saveOrder(
        sessionToken: _sessionToken,
        order: order.toRequest(),
      );
      batch(() {
        editingOrder.value = saved;
        lastSavedAt.value = DateTime.now();
      });
      return true;
    } catch (error) {
      formError.value = _messageFor(error);
      return false;
    } finally {
      saving.value = false;
    }
  }

  Future<bool> confirmOrder() async {
    if (!_validateForConfirmation()) return false;
    if (!await saveDraft()) return false;
    final id = editingOrder.value?.id;
    if (id == null || actionLoading.value) return false;
    actionLoading.value = true;
    try {
      editingOrder.value = await _repository.confirmOrder(
        sessionToken: _sessionToken,
        orderId: id,
      );
      await loadOrders();
      return true;
    } catch (error) {
      formError.value = _messageFor(error);
      return false;
    } finally {
      actionLoading.value = false;
    }
  }

  Future<bool> loadPreview() async {
    if (!await _ensurePersisted()) return false;
    final id = editingOrder.value?.id;
    if (id == null) return false;
    batch(() {
      previewLoading.value = true;
      previewError.value = null;
      preview.value = null;
      documentJob.value = null;
      emailResult.value = null;
    });
    try {
      preview.value = await _repository.getPreview(
        sessionToken: _sessionToken,
        orderId: id,
      );
      return true;
    } catch (error) {
      previewError.value = _messageFor(error);
      return false;
    } finally {
      previewLoading.value = false;
    }
  }

  Future<OrderDocumentJob?> generatePdf() async {
    final id = editingOrder.value?.id;
    if (id == null || documentLoading.value) return null;
    batch(() {
      documentLoading.value = true;
      previewError.value = null;
      documentJob.value = null;
    });
    try {
      var job = await _repository.requestPdf(
        sessionToken: _sessionToken,
        orderId: id,
      );
      documentJob.value = job;
      for (var attempt = 0; attempt < 20 && !job.isFinished; attempt++) {
        await Future<void>.delayed(const Duration(seconds: 2));
        job = await _repository.getDocumentStatus(
          sessionToken: _sessionToken,
          documentId: job.id,
        );
        documentJob.value = job;
      }
      if (job.status != 'ready') {
        previewError.value = job.status == 'expired'
            ? 'O link do PDF expirou. Gere o arquivo novamente.'
            : 'Não foi possível concluir a geração do PDF.';
      }
      return job;
    } catch (error) {
      previewError.value = _messageFor(error);
      return null;
    } finally {
      documentLoading.value = false;
    }
  }

  Future<bool> sendOrderEmail({
    required String recipient,
    required String subject,
    required String message,
  }) async {
    final id = editingOrder.value?.id;
    if (id == null || emailSending.value) return false;
    if (!_validEmail(recipient)) {
      previewError.value = 'Informe um e-mail válido.';
      return false;
    }
    batch(() {
      emailSending.value = true;
      previewError.value = null;
      emailResult.value = null;
    });
    try {
      final result = await _repository.sendEmail(
        sessionToken: _sessionToken,
        orderId: id,
        recipient: recipient,
        subject: subject,
        message: message,
      );
      emailResult.value = result;
      return result.sent;
    } catch (error) {
      previewError.value = _messageFor(error);
      return false;
    } finally {
      emailSending.value = false;
    }
  }

  Future<bool> cancelOrder(String reason) async {
    final id = editingOrder.value?.id;
    if (id == null || actionLoading.value) return false;
    actionLoading.value = true;
    try {
      editingOrder.value = await _repository.cancelOrder(
        sessionToken: _sessionToken,
        orderId: id,
        reason: reason,
      );
      await loadOrders();
      return true;
    } catch (error) {
      formError.value = _messageFor(error);
      return false;
    } finally {
      actionLoading.value = false;
    }
  }

  Future<String?> duplicateOrder() async {
    final id = editingOrder.value?.id;
    if (id == null || actionLoading.value) return null;
    actionLoading.value = true;
    try {
      final duplicated = await _repository.duplicateOrder(
        sessionToken: _sessionToken,
        orderId: id,
      );
      editingOrder.value = duplicated;
      await loadOrders();
      return duplicated.id;
    } catch (error) {
      formError.value = _messageFor(error);
      return null;
    } finally {
      actionLoading.value = false;
    }
  }

  void _setItems(OrderDetail order, List<OrderLineItem> items) {
    editingOrder.value = order.copyWith(
      items: items,
      totals: OrderTotals.calculate(items, order.shippingCost),
    );
  }

  bool _validateForConfirmation() {
    final order = editingOrder.value;
    if (order?.customer == null) {
      formError.value = 'Selecione o cliente do pedido.';
      return false;
    }
    if (order!.items.isEmpty) {
      formError.value = 'Adicione pelo menos um produto ao pedido.';
      return false;
    }
    if (order.paymentTerm == null) {
      formError.value = 'Selecione a condição de pagamento.';
      return false;
    }
    return true;
  }

  Future<bool> _ensurePersisted() async {
    final order = editingOrder.value;
    if (order == null) return false;
    if (order.isPersisted &&
        (!order.permissions.canEdit || order.status != 'draft')) {
      return true;
    }
    return saveDraft();
  }

  bool _validEmail(String value) {
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value.trim());
  }

  void _synchronizeSession() {
    final token = _authController.sessionToken.value;
    if (_dataSessionToken == token) return;
    _dataSessionToken = token;
    _listRequestId++;
    _clientSearchId++;
    _productSearchId++;
    batch(() {
      orders.value = [];
      pagination.value = null;
      filterOptions.value = null;
      editingOrder.value = null;
      formOptions.value = null;
      preview.value = null;
      documentJob.value = null;
      emailResult.value = null;
      listError.value = null;
      formError.value = null;
      previewError.value = null;
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

  String _messageFor(Object error) {
    if (error is ApiException) {
      switch (error.code) {
        case 209:
          return 'Sua sessão expirou. Entre novamente.';
        case 9200:
          return 'Você não possui permissão para acessar os pedidos.';
        case 9201:
          return 'Pedido não encontrado.';
        case 9202:
          return 'O cliente selecionado não é válido.';
        case 9203:
          return 'Um dos produtos não está disponível.';
        case 9204:
          return 'Revise os dados e os valores do pedido.';
        case 9205:
          return 'Este pedido não pode mais ser alterado.';
        case 9206:
          return 'Não foi possível gerar o documento do pedido.';
        case 9207:
          return 'Não foi possível enviar o pedido por e-mail.';
        case 9208:
          return 'A numeração do pedido foi atualizada. Salve novamente.';
        default:
          return error.message;
      }
    }
    if (error is FormatException) return error.message.toString();
    return 'Não foi possível concluir a operação com o pedido.';
  }
}

class DateTimeRangeValue {
  const DateTimeRangeValue(this.start, this.end);
  final DateTime start;
  final DateTime end;
}

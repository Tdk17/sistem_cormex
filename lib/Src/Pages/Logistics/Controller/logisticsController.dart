import 'package:signals/signals.dart';
import 'package:sistem_cormex/Src/Connection/apiException.dart';
import 'package:sistem_cormex/Src/Models/logisticsModels.dart';
import 'package:sistem_cormex/Src/Pages/Auth/Controller/authController.dart';
import 'package:sistem_cormex/Src/Pages/Logistics/Repository/logisticsRepository.dart';

enum LogisticsSection { routes, trackings, carriers }

class LogisticsController {
  LogisticsController(this._repository, this._authController);

  final LogisticsRepository _repository;
  final AuthController _authController;

  String? _dataSessionToken;
  int _routesRequestId = 0;
  int _trackingsRequestId = 0;
  int _candidatesRequestId = 0;
  int _ordersRequestId = 0;

  final section = signal(LogisticsSection.routes);
  final bootstrap = signal(LogisticsBootstrap.empty);
  final loadingBootstrap = signal(false);
  final error = signal<String?>(null);

  final routes = signal<List<RoutePlanSummary>>([]);
  final routesPagination = signal(LogisticsPagination.empty);
  final routesLoading = signal(false);
  final routesQuery = signal('');
  final routesStatus = signal('active');
  final selectedRoute = signal<RoutePlan?>(null);
  final routeDetailsLoading = signal(false);

  final routeCandidates = signal<List<RouteCandidate>>([]);
  final selectedCandidateIds = signal<Set<String>>(<String>{});
  final candidatesLoading = signal(false);
  final optimizing = signal(false);
  final savingRoute = signal(false);
  final operatingRoute = signal(false);
  final optimizedPreview = signal<RoutePlan?>(null);

  final trackings = signal<List<ShipmentTracking>>([]);
  final trackingsPagination = signal(LogisticsPagination.empty);
  final trackingsLoading = signal(false);
  final trackingsQuery = signal('');
  final trackingsStatus = signal('active');
  final selectedTracking = signal<ShipmentTracking?>(null);
  final savingTracking = signal(false);
  final refreshingTrackingId = signal<String?>(null);
  final trackingOrderResults = signal<List<TrackingOrderOption>>([]);
  final trackingOrdersLoading = signal(false);

  final carriers = signal<List<Carrier>>([]);
  final carriersLoading = signal(false);
  final savingCarrier = signal(false);
  final deletingCarrierId = signal<String?>(null);

  LogisticsPermissions get permissions => bootstrap.value.permissions;
  LogisticsMetrics get metrics => bootstrap.value.metrics;

  Future<void> initialize() async {
    _synchronizeSession();
    if (loadingBootstrap.value) return;
    if (routes.value.isNotEmpty ||
        trackings.value.isNotEmpty ||
        carriers.value.isNotEmpty) {
      return;
    }
    await refreshAll();
  }

  Future<void> refreshAll() async {
    _synchronizeSession();
    error.value = null;
    await Future.wait<void>([
      loadBootstrap(),
      loadRoutes(),
      loadTrackings(),
      loadCarriers(),
    ]);
  }

  Future<void> loadBootstrap() async {
    loadingBootstrap.value = true;
    try {
      bootstrap.value = await _repository.getBootstrap(
        sessionToken: _sessionToken,
      );
    } catch (exception) {
      error.value = _messageFor(exception);
    } finally {
      loadingBootstrap.value = false;
    }
  }

  Future<void> loadRoutes({int page = 1}) async {
    final requestId = ++_routesRequestId;
    batch(() {
      routesLoading.value = true;
      error.value = null;
    });
    try {
      final result = await _repository.listRoutes(
        sessionToken: _sessionToken,
        page: page,
        pageSize: 20,
        query: routesQuery.value,
        status: routesStatus.value,
      );
      if (requestId != _routesRequestId) return;
      batch(() {
        routes.value = result.routes;
        routesPagination.value = result.pagination;
        bootstrap.value = _bootstrapWith(
          metrics: result.metrics,
          permissions: result.permissions,
        );
      });
    } catch (exception) {
      if (requestId == _routesRequestId) error.value = _messageFor(exception);
    } finally {
      if (requestId == _routesRequestId) routesLoading.value = false;
    }
  }

  Future<void> searchRoutes(String query) async {
    routesQuery.value = query.trim();
    await loadRoutes();
  }

  Future<void> filterRoutes(String status) async {
    routesStatus.value = status;
    await loadRoutes();
  }

  Future<RoutePlan?> openRoute(String routeId) async {
    routeDetailsLoading.value = true;
    error.value = null;
    try {
      final route = await _repository.getRoute(
        sessionToken: _sessionToken,
        routeId: routeId,
      );
      selectedRoute.value = route;
      return route;
    } catch (exception) {
      error.value = _messageFor(exception);
      return null;
    } finally {
      routeDetailsLoading.value = false;
    }
  }

  Future<void> loadRouteCandidates({
    required DateTime routeDate,
    required List<String> cities,
    required String kind,
    String query = '',
  }) async {
    final requestId = ++_candidatesRequestId;
    batch(() {
      candidatesLoading.value = true;
      error.value = null;
      optimizedPreview.value = null;
    });
    try {
      final result = await _repository.listRouteCandidates(
        sessionToken: _sessionToken,
        routeDate: routeDate,
        cities: cities,
        kind: kind,
        query: query,
      );
      if (requestId != _candidatesRequestId) return;
      final validIds = result
          .where((candidate) => candidate.hasValidAddress)
          .map((candidate) => candidate.id)
          .toSet();
      batch(() {
        routeCandidates.value = result;
        selectedCandidateIds.value = selectedCandidateIds.value
            .where(validIds.contains)
            .toSet();
      });
    } catch (exception) {
      if (requestId == _candidatesRequestId) {
        error.value = _messageFor(exception);
      }
    } finally {
      if (requestId == _candidatesRequestId) candidatesLoading.value = false;
    }
  }

  void toggleCandidate(String candidateId, bool selected) {
    final next = {...selectedCandidateIds.value};
    if (selected) {
      next.add(candidateId);
    } else {
      next.remove(candidateId);
    }
    batch(() {
      selectedCandidateIds.value = next;
      optimizedPreview.value = null;
    });
  }

  void selectAllCandidates(bool selected) {
    batch(() {
      selectedCandidateIds.value = selected
          ? routeCandidates.value
              .where((candidate) => candidate.hasValidAddress)
              .map((candidate) => candidate.id)
              .toSet()
          : <String>{};
      optimizedPreview.value = null;
    });
  }

  Future<RoutePlan?> optimizeRoute(Map<String, dynamic> request) async {
    if (optimizing.value) return null;
    final validation = _validateRoute(request);
    if (validation != null) {
      error.value = validation;
      return null;
    }
    batch(() {
      optimizing.value = true;
      error.value = null;
    });
    try {
      final result = await _repository.optimizeRoute(
        sessionToken: _sessionToken,
        request: _withSelectedCandidates(request),
      );
      optimizedPreview.value = result;
      return result;
    } catch (exception) {
      error.value = _messageFor(exception);
      return null;
    } finally {
      optimizing.value = false;
    }
  }

  Future<RoutePlan?> saveRoute(Map<String, dynamic> request) async {
    if (savingRoute.value) return null;
    final validation = _validateRoute(request);
    if (validation != null) {
      error.value = validation;
      return null;
    }
    batch(() {
      savingRoute.value = true;
      error.value = null;
    });
    try {
      final result = await _repository.saveRoute(
        sessionToken: _sessionToken,
        request: {
          ..._withSelectedCandidates(request),
          'confirmOptimization': true,
        },
      );
      await Future.wait<void>([loadRoutes(), loadBootstrap()]);
      resetRouteDraft();
      return result;
    } catch (exception) {
      error.value = _messageFor(exception);
      return null;
    } finally {
      savingRoute.value = false;
    }
  }

  Future<RoutePlan?> startRoute(String routeId) async {
    return _operateRoute(
      () => _repository.startRoute(
        sessionToken: _sessionToken,
        routeId: routeId,
      ),
    );
  }

  Future<RoutePlan?> updateRouteStop({
    required String routeId,
    required String stopId,
    required String status,
    String notes = '',
  }) async {
    return _operateRoute(
      () => _repository.updateRouteStop(
        sessionToken: _sessionToken,
        routeId: routeId,
        stopId: stopId,
        status: status,
        notes: notes,
      ),
    );
  }

  Future<RoutePlan?> finishRoute(String routeId) async {
    return _operateRoute(
      () => _repository.finishRoute(
        sessionToken: _sessionToken,
        routeId: routeId,
      ),
    );
  }

  Future<RoutePlan?> _operateRoute(Future<RoutePlan> Function() operation) async {
    if (operatingRoute.value) return null;
    batch(() {
      operatingRoute.value = true;
      error.value = null;
    });
    try {
      final route = await operation();
      selectedRoute.value = route;
      await Future.wait<void>([loadRoutes(), loadBootstrap()]);
      return route;
    } catch (exception) {
      error.value = _messageFor(exception);
      return null;
    } finally {
      operatingRoute.value = false;
    }
  }

  void resetRouteDraft() {
    _candidatesRequestId++;
    batch(() {
      routeCandidates.value = [];
      selectedCandidateIds.value = <String>{};
      optimizedPreview.value = null;
      candidatesLoading.value = false;
    });
  }

  Future<void> loadCarriers() async {
    carriersLoading.value = true;
    try {
      carriers.value = await _repository.listCarriers(
        sessionToken: _sessionToken,
        includeInactive: true,
      );
    } catch (exception) {
      error.value = _messageFor(exception);
    } finally {
      carriersLoading.value = false;
    }
  }

  Future<Carrier?> saveCarrier(Carrier carrier) async {
    if (savingCarrier.value) return null;
    final validation = _validateCarrier(carrier);
    if (validation != null) {
      error.value = validation;
      return null;
    }
    batch(() {
      savingCarrier.value = true;
      error.value = null;
    });
    try {
      final saved = await _repository.saveCarrier(
        sessionToken: _sessionToken,
        carrier: carrier.toRequest(),
      );
      await loadCarriers();
      return saved;
    } catch (exception) {
      error.value = _messageFor(exception);
      return null;
    } finally {
      savingCarrier.value = false;
    }
  }

  Future<bool> deleteCarrier(String carrierId) async {
    if (deletingCarrierId.value != null) return false;
    batch(() {
      deletingCarrierId.value = carrierId;
      error.value = null;
    });
    try {
      await _repository.deleteCarrier(
        sessionToken: _sessionToken,
        carrierId: carrierId,
      );
      await loadCarriers();
      return true;
    } catch (exception) {
      error.value = _messageFor(exception);
      return false;
    } finally {
      deletingCarrierId.value = null;
    }
  }

  Future<void> loadTrackings({int page = 1}) async {
    final requestId = ++_trackingsRequestId;
    batch(() {
      trackingsLoading.value = true;
      error.value = null;
    });
    try {
      final result = await _repository.listTrackings(
        sessionToken: _sessionToken,
        page: page,
        pageSize: 20,
        query: trackingsQuery.value,
        status: trackingsStatus.value,
      );
      if (requestId != _trackingsRequestId) return;
      batch(() {
        trackings.value = result.trackings;
        trackingsPagination.value = result.pagination;
        bootstrap.value = _bootstrapWith(
          metrics: result.metrics,
          permissions: result.permissions,
        );
      });
    } catch (exception) {
      if (requestId == _trackingsRequestId) {
        error.value = _messageFor(exception);
      }
    } finally {
      if (requestId == _trackingsRequestId) trackingsLoading.value = false;
    }
  }

  Future<void> searchTrackings(String query) async {
    trackingsQuery.value = query.trim();
    await loadTrackings();
  }

  Future<void> filterTrackings(String status) async {
    trackingsStatus.value = status;
    await loadTrackings();
  }

  Future<ShipmentTracking?> openTracking(String trackingId) async {
    error.value = null;
    try {
      final tracking = await _repository.getTracking(
        sessionToken: _sessionToken,
        trackingId: trackingId,
      );
      selectedTracking.value = tracking;
      return tracking;
    } catch (exception) {
      error.value = _messageFor(exception);
      return null;
    }
  }

  Future<ShipmentTracking?> saveTracking(Map<String, dynamic> request) async {
    if (savingTracking.value) return null;
    final validation = _validateTracking(request);
    if (validation != null) {
      error.value = validation;
      return null;
    }
    batch(() {
      savingTracking.value = true;
      error.value = null;
    });
    try {
      final tracking = await _repository.saveTracking(
        sessionToken: _sessionToken,
        tracking: request,
      );
      await Future.wait<void>([loadTrackings(), loadBootstrap()]);
      return tracking;
    } catch (exception) {
      error.value = _messageFor(exception);
      return null;
    } finally {
      savingTracking.value = false;
    }
  }

  Future<void> searchTrackingOrders(String query) async {
    final normalized = query.trim();
    final requestId = ++_ordersRequestId;
    if (normalized.length < 2) {
      batch(() {
        trackingOrdersLoading.value = false;
        trackingOrderResults.value = [];
      });
      return;
    }
    trackingOrdersLoading.value = true;
    try {
      final result = await _repository.searchTrackingOrders(
        sessionToken: _sessionToken,
        query: normalized,
      );
      if (requestId == _ordersRequestId) trackingOrderResults.value = result;
    } catch (exception) {
      if (requestId == _ordersRequestId) error.value = _messageFor(exception);
    } finally {
      if (requestId == _ordersRequestId) trackingOrdersLoading.value = false;
    }
  }

  void clearTrackingOrderSearch() {
    _ordersRequestId++;
    batch(() {
      trackingOrdersLoading.value = false;
      trackingOrderResults.value = [];
    });
  }

  Future<ShipmentTracking?> refreshTracking(String trackingId) async {
    if (refreshingTrackingId.value != null) return null;
    batch(() {
      refreshingTrackingId.value = trackingId;
      error.value = null;
    });
    try {
      final tracking = await _repository.refreshTracking(
        sessionToken: _sessionToken,
        trackingId: trackingId,
      );
      await loadTrackings(page: trackingsPagination.value.page);
      return tracking;
    } catch (exception) {
      error.value = _messageFor(exception);
      return null;
    } finally {
      refreshingTrackingId.value = null;
    }
  }

  void changeSection(LogisticsSection value) {
    section.value = value;
    error.value = null;
  }

  void clearError() => error.value = null;

  Map<String, dynamic> _withSelectedCandidates(
    Map<String, dynamic> request,
  ) {
    return {
      ...request,
      'candidateIds': selectedCandidateIds.value.toList(),
    };
  }

  String? _validateRoute(Map<String, dynamic> request) {
    if ((request['name']?.toString().trim() ?? '').length < 3) {
      return 'Informe um nome para identificar a rota.';
    }
    if (selectedCandidateIds.value.length < 2) {
      return 'Selecione pelo menos dois clientes com endereço válido.';
    }
    if ((request['originMode']?.toString() ?? '').isEmpty) {
      return 'Selecione a origem da rota.';
    }
    return null;
  }

  String? _validateCarrier(Carrier carrier) {
    if (carrier.name.trim().length < 2) {
      return 'Informe o nome da transportadora.';
    }
    if (carrier.provider == 'manual' &&
        carrier.trackingUrlTemplate.isNotEmpty &&
        !carrier.trackingUrlTemplate.contains('{codigo}')) {
      return 'A URL de rastreamento deve conter {codigo}.';
    }
    return null;
  }

  String? _validateTracking(Map<String, dynamic> request) {
    if ((request['carrierId']?.toString().trim() ?? '').isEmpty) {
      return 'Selecione a transportadora.';
    }
    if ((request['trackingCode']?.toString().trim() ?? '').length < 3) {
      return 'Informe um código de rastreamento válido.';
    }
    if ((request['orderId']?.toString().trim() ?? '').isEmpty) {
      return 'Informe o pedido relacionado ao envio.';
    }
    return null;
  }

  LogisticsBootstrap _bootstrapWith({
    required LogisticsMetrics metrics,
    required LogisticsPermissions permissions,
  }) {
    final value = bootstrap.value;
    return LogisticsBootstrap(
      companyAddress: value.companyAddress,
      cities: value.cities,
      drivers: value.drivers,
      vehicles: value.vehicles,
      permissions: permissions,
      metrics: metrics,
    );
  }

  void _synchronizeSession() {
    final token = _authController.sessionToken.value;
    if (_dataSessionToken == token) return;
    _dataSessionToken = token;
    _routesRequestId++;
    _trackingsRequestId++;
    _candidatesRequestId++;
    _ordersRequestId++;
    batch(() {
      section.value = LogisticsSection.routes;
      bootstrap.value = LogisticsBootstrap.empty;
      routes.value = [];
      routesPagination.value = LogisticsPagination.empty;
      routesQuery.value = '';
      routesStatus.value = 'active';
      selectedRoute.value = null;
      routeCandidates.value = [];
      selectedCandidateIds.value = <String>{};
      optimizedPreview.value = null;
      trackings.value = [];
      trackingsPagination.value = LogisticsPagination.empty;
      trackingsQuery.value = '';
      trackingsStatus.value = 'active';
      selectedTracking.value = null;
      trackingOrderResults.value = [];
      carriers.value = [];
      error.value = null;
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
        case 9700:
          return 'Você não possui permissão para acessar a logística.';
        case 9701:
          return 'Rota não localizada.';
        case 9702:
          return 'Revise os dados da rota.';
        case 9703:
          return 'Um dos clientes não possui endereço válido.';
        case 9704:
          return 'Não foi possível otimizar a rota no momento.';
        case 9705:
          return 'A transportadora não foi localizada.';
        case 9706:
          return 'O código de rastreamento não foi localizado.';
        case 9707:
          return 'Não foi possível atualizar o rastreamento.';
        case 9708:
          return 'A configuração do provedor logístico está incompleta.';
        default:
          return exception.message;
      }
    }
    if (exception is FormatException) return exception.message.toString();
    return 'Não foi possível concluir a operação de logística.';
  }
}

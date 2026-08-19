import 'package:sistem_cormex/Src/Connection/endpoints.dart';
import 'package:sistem_cormex/Src/Connection/httpManager.dart';
import 'package:sistem_cormex/Src/Models/logisticsModels.dart';

abstract interface class LogisticsRepository {
  Future<LogisticsBootstrap> getBootstrap({required String sessionToken});

  Future<RouteListResult> listRoutes({
    required String sessionToken,
    required int page,
    required int pageSize,
    required String query,
    required String status,
    DateTime? from,
    DateTime? to,
    String? driverId,
  });

  Future<List<RouteCandidate>> listRouteCandidates({
    required String sessionToken,
    required DateTime routeDate,
    required List<String> cities,
    required String kind,
    required String query,
  });

  Future<RoutePlan> optimizeRoute({
    required String sessionToken,
    required Map<String, dynamic> request,
  });

  Future<RoutePlan> saveRoute({
    required String sessionToken,
    required Map<String, dynamic> request,
  });

  Future<RoutePlan> getRoute({
    required String sessionToken,
    required String routeId,
  });

  Future<RoutePlan> startRoute({
    required String sessionToken,
    required String routeId,
  });

  Future<RoutePlan> updateRouteStop({
    required String sessionToken,
    required String routeId,
    required String stopId,
    required String status,
    String notes = '',
  });

  Future<RoutePlan> finishRoute({
    required String sessionToken,
    required String routeId,
  });

  Future<List<Carrier>> listCarriers({
    required String sessionToken,
    bool includeInactive = false,
  });

  Future<Carrier> saveCarrier({
    required String sessionToken,
    required Map<String, dynamic> carrier,
  });

  Future<void> deleteCarrier({
    required String sessionToken,
    required String carrierId,
  });

  Future<TrackingListResult> listTrackings({
    required String sessionToken,
    required int page,
    required int pageSize,
    required String query,
    required String status,
    String? carrierId,
  });

  Future<List<TrackingOrderOption>> searchTrackingOrders({
    required String sessionToken,
    required String query,
  });

  Future<ShipmentTracking> saveTracking({
    required String sessionToken,
    required Map<String, dynamic> tracking,
  });

  Future<ShipmentTracking> getTracking({
    required String sessionToken,
    required String trackingId,
  });

  Future<ShipmentTracking> refreshTracking({
    required String sessionToken,
    required String trackingId,
  });
}

class ParseLogisticsRepository implements LogisticsRepository {
  const ParseLogisticsRepository(this._httpManager);

  final HttpManager _httpManager;

  @override
  Future<LogisticsBootstrap> getBootstrap({
    required String sessionToken,
  }) async {
    final result = await _post(
      Endpoints.logisticsBootstrap,
      sessionToken,
      const {},
    );
    return LogisticsBootstrap.fromMap(result);
  }

  @override
  Future<RouteListResult> listRoutes({
    required String sessionToken,
    required int page,
    required int pageSize,
    required String query,
    required String status,
    DateTime? from,
    DateTime? to,
    String? driverId,
  }) async {
    final result = await _post(
      Endpoints.routesList,
      sessionToken,
      {
        'page': page,
        'pageSize': pageSize,
        'query': query.trim(),
        'status': status,
        'from': from?.toUtc().toIso8601String(),
        'to': to?.toUtc().toIso8601String(),
        'driverId': driverId,
      },
    );
    return RouteListResult.fromMap(result);
  }

  @override
  Future<List<RouteCandidate>> listRouteCandidates({
    required String sessionToken,
    required DateTime routeDate,
    required List<String> cities,
    required String kind,
    required String query,
  }) async {
    final result = await _post(
      Endpoints.routesCandidates,
      sessionToken,
      {
        'routeDate': routeDate.toUtc().toIso8601String(),
        'cities': cities,
        'kind': kind,
        'query': query.trim(),
        'includeOrders': kind == 'all' || kind == 'delivery',
        'includeVisitTasks': kind == 'all' || kind == 'visit',
      },
    );
    return _mapList(result['candidates'])
        .map(RouteCandidate.fromMap)
        .toList();
  }

  @override
  Future<RoutePlan> optimizeRoute({
    required String sessionToken,
    required Map<String, dynamic> request,
  }) async {
    final result = await _post(
      Endpoints.routesOptimize,
      sessionToken,
      request,
    );
    return RoutePlan.fromMap(_entityMap(result, 'route'));
  }

  @override
  Future<RoutePlan> saveRoute({
    required String sessionToken,
    required Map<String, dynamic> request,
  }) async {
    final result = await _post(
      Endpoints.routesSave,
      sessionToken,
      request,
    );
    return RoutePlan.fromMap(_entityMap(result, 'route'));
  }

  @override
  Future<RoutePlan> getRoute({
    required String sessionToken,
    required String routeId,
  }) async {
    final result = await _post(
      Endpoints.routesGet,
      sessionToken,
      {'routeId': routeId},
    );
    return RoutePlan.fromMap(_entityMap(result, 'route'));
  }

  @override
  Future<RoutePlan> startRoute({
    required String sessionToken,
    required String routeId,
  }) async {
    final result = await _post(
      Endpoints.routesStart,
      sessionToken,
      {
        'routeId': routeId,
        'startedAt': DateTime.now().toUtc().toIso8601String(),
      },
    );
    return RoutePlan.fromMap(_entityMap(result, 'route'));
  }

  @override
  Future<RoutePlan> updateRouteStop({
    required String sessionToken,
    required String routeId,
    required String stopId,
    required String status,
    String notes = '',
  }) async {
    final result = await _post(
      Endpoints.routeStopUpdate,
      sessionToken,
      {
        'routeId': routeId,
        'stopId': stopId,
        'status': status,
        'notes': notes.trim(),
        'occurredAt': DateTime.now().toUtc().toIso8601String(),
      },
    );
    return RoutePlan.fromMap(_entityMap(result, 'route'));
  }

  @override
  Future<RoutePlan> finishRoute({
    required String sessionToken,
    required String routeId,
  }) async {
    final result = await _post(
      Endpoints.routesFinish,
      sessionToken,
      {
        'routeId': routeId,
        'finishedAt': DateTime.now().toUtc().toIso8601String(),
      },
    );
    return RoutePlan.fromMap(_entityMap(result, 'route'));
  }

  @override
  Future<List<Carrier>> listCarriers({
    required String sessionToken,
    bool includeInactive = false,
  }) async {
    final result = await _post(
      Endpoints.carriersList,
      sessionToken,
      {'includeInactive': includeInactive},
    );
    return _mapList(result['carriers']).map(Carrier.fromMap).toList();
  }

  @override
  Future<Carrier> saveCarrier({
    required String sessionToken,
    required Map<String, dynamic> carrier,
  }) async {
    final result = await _post(
      Endpoints.carriersSave,
      sessionToken,
      carrier,
    );
    return Carrier.fromMap(_entityMap(result, 'carrier'));
  }

  @override
  Future<void> deleteCarrier({
    required String sessionToken,
    required String carrierId,
  }) async {
    await _post(
      Endpoints.carriersDelete,
      sessionToken,
      {'carrierId': carrierId},
    );
  }

  @override
  Future<TrackingListResult> listTrackings({
    required String sessionToken,
    required int page,
    required int pageSize,
    required String query,
    required String status,
    String? carrierId,
  }) async {
    final result = await _post(
      Endpoints.trackingsList,
      sessionToken,
      {
        'page': page,
        'pageSize': pageSize,
        'query': query.trim(),
        'status': status,
        'carrierId': carrierId,
      },
    );
    return TrackingListResult.fromMap(result);
  }

  @override
  Future<List<TrackingOrderOption>> searchTrackingOrders({
    required String sessionToken,
    required String query,
  }) async {
    final result = await _post(
      Endpoints.trackingsSearchOrders,
      sessionToken,
      {'query': query.trim(), 'limit': 20},
    );
    return _mapList(result['orders'])
        .map(TrackingOrderOption.fromMap)
        .toList();
  }

  @override
  Future<ShipmentTracking> saveTracking({
    required String sessionToken,
    required Map<String, dynamic> tracking,
  }) async {
    final result = await _post(
      Endpoints.trackingsSave,
      sessionToken,
      tracking,
    );
    return ShipmentTracking.fromMap(_entityMap(result, 'tracking'));
  }

  @override
  Future<ShipmentTracking> getTracking({
    required String sessionToken,
    required String trackingId,
  }) async {
    final result = await _post(
      Endpoints.trackingsGet,
      sessionToken,
      {'trackingId': trackingId},
    );
    return ShipmentTracking.fromMap(_entityMap(result, 'tracking'));
  }

  @override
  Future<ShipmentTracking> refreshTracking({
    required String sessionToken,
    required String trackingId,
  }) async {
    final result = await _post(
      Endpoints.trackingsRefresh,
      sessionToken,
      {'trackingId': trackingId},
    );
    return ShipmentTracking.fromMap(_entityMap(result, 'tracking'));
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
      'O servidor retornou uma resposta inválida para Logística.',
    );
  }

  Map<String, dynamic> _entityMap(
    Map<String, dynamic> result,
    String key,
  ) {
    final value = result[key];
    return value is Map ? Map<String, dynamic>.from(value) : result;
  }

  List<Map<String, dynamic>> _mapList(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
}

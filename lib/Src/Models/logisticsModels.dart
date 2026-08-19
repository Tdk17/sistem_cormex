class LogisticsBootstrap {
  const LogisticsBootstrap({
    required this.companyAddress,
    required this.cities,
    required this.drivers,
    required this.vehicles,
    required this.permissions,
    required this.metrics,
  });

  final LogisticsAddress companyAddress;
  final List<LogisticsOption> cities;
  final List<LogisticsOption> drivers;
  final List<LogisticsOption> vehicles;
  final LogisticsPermissions permissions;
  final LogisticsMetrics metrics;

  factory LogisticsBootstrap.fromMap(Map<String, dynamic> map) {
    final filters = _mapValue(map['filters']);
    return LogisticsBootstrap(
      companyAddress: LogisticsAddress.fromMap(
        _mapValue(map['companyAddress']),
      ),
      cities: _mapList(filters['cities'] ?? map['cities'])
          .map(LogisticsOption.fromMap)
          .toList(),
      drivers: _mapList(filters['drivers'] ?? map['drivers'])
          .map(LogisticsOption.fromMap)
          .toList(),
      vehicles: _mapList(filters['vehicles'] ?? map['vehicles'])
          .map(LogisticsOption.fromMap)
          .toList(),
      permissions: LogisticsPermissions.fromMap(
        _mapValue(map['permissions']),
      ),
      metrics: LogisticsMetrics.fromMap(_mapValue(map['metrics'])),
    );
  }

  static const empty = LogisticsBootstrap(
    companyAddress: LogisticsAddress.empty,
    cities: [],
    drivers: [],
    vehicles: [],
    permissions: LogisticsPermissions.initial,
    metrics: LogisticsMetrics.empty,
  );
}

class LogisticsOption {
  const LogisticsOption({required this.id, required this.label});

  final String id;
  final String label;

  factory LogisticsOption.fromMap(Map<String, dynamic> map) {
    return LogisticsOption(
      id: _string(
        map['id'],
        fallback: _string(map['value'], fallback: _string(map['objectId'])),
      ),
      label: _string(map['label'], fallback: _string(map['name'])),
    );
  }
}

class LogisticsAddress {
  const LogisticsAddress({
    required this.label,
    required this.street,
    required this.number,
    required this.complement,
    required this.neighborhood,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.latitude,
    required this.longitude,
  });

  final String label;
  final String street;
  final String number;
  final String complement;
  final String neighborhood;
  final String city;
  final String state;
  final String postalCode;
  final double? latitude;
  final double? longitude;

  bool get hasCoordinates => latitude != null && longitude != null;

  String get formatted {
    if (label.isNotEmpty) return label;
    final line = [
      street,
      number,
      complement,
      neighborhood,
      city,
      state,
      postalCode,
    ].where((value) => value.trim().isNotEmpty).join(', ');
    return line;
  }

  Map<String, dynamic> toRequest() => {
        'label': label.trim(),
        'street': street.trim(),
        'number': number.trim(),
        'complement': complement.trim(),
        'neighborhood': neighborhood.trim(),
        'city': city.trim(),
        'state': state.trim(),
        'postalCode': postalCode.trim(),
        'latitude': latitude,
        'longitude': longitude,
      };

  factory LogisticsAddress.fromMap(Map<String, dynamic> map) {
    return LogisticsAddress(
      label: _string(map['label'], fallback: _string(map['formatted'])),
      street: _string(map['street'], fallback: _string(map['address'])),
      number: _string(map['number']),
      complement: _string(map['complement']),
      neighborhood: _string(map['neighborhood']),
      city: _string(map['city']),
      state: _string(map['state']),
      postalCode: _string(map['postalCode'], fallback: _string(map['zipCode'])),
      latitude: _nullableDouble(map['latitude'] ?? map['lat']),
      longitude: _nullableDouble(map['longitude'] ?? map['lng']),
    );
  }

  static const empty = LogisticsAddress(
    label: '',
    street: '',
    number: '',
    complement: '',
    neighborhood: '',
    city: '',
    state: '',
    postalCode: '',
    latitude: null,
    longitude: null,
  );
}

class LogisticsMetrics {
  const LogisticsMetrics({
    required this.routesToday,
    required this.pendingStops,
    required this.completedToday,
    required this.inTransitShipments,
    required this.trackingExceptions,
  });

  final int routesToday;
  final int pendingStops;
  final int completedToday;
  final int inTransitShipments;
  final int trackingExceptions;

  factory LogisticsMetrics.fromMap(Map<String, dynamic> map) {
    return LogisticsMetrics(
      routesToday: _integer(map['routesToday']),
      pendingStops: _integer(map['pendingStops']),
      completedToday: _integer(map['completedToday']),
      inTransitShipments: _integer(map['inTransitShipments']),
      trackingExceptions: _integer(map['trackingExceptions']),
    );
  }

  static const empty = LogisticsMetrics(
    routesToday: 0,
    pendingStops: 0,
    completedToday: 0,
    inTransitShipments: 0,
    trackingExceptions: 0,
  );
}

class LogisticsPermissions {
  const LogisticsPermissions({
    required this.canViewRoutes,
    required this.canCreateRoute,
    required this.canOperateRoute,
    required this.canManageCarriers,
    required this.canManageTrackings,
    required this.canViewAllDrivers,
  });

  final bool canViewRoutes;
  final bool canCreateRoute;
  final bool canOperateRoute;
  final bool canManageCarriers;
  final bool canManageTrackings;
  final bool canViewAllDrivers;

  factory LogisticsPermissions.fromMap(Map<String, dynamic> map) {
    return LogisticsPermissions(
      canViewRoutes: _boolean(map['canViewRoutes'], fallback: true),
      canCreateRoute: _boolean(map['canCreateRoute'], fallback: true),
      canOperateRoute: _boolean(map['canOperateRoute'], fallback: true),
      canManageCarriers: _boolean(map['canManageCarriers'], fallback: true),
      canManageTrackings: _boolean(map['canManageTrackings'], fallback: true),
      canViewAllDrivers: _boolean(map['canViewAllDrivers']),
    );
  }

  static const initial = LogisticsPermissions(
    canViewRoutes: true,
    canCreateRoute: true,
    canOperateRoute: true,
    canManageCarriers: true,
    canManageTrackings: true,
    canViewAllDrivers: false,
  );
}

class RouteListResult {
  const RouteListResult({
    required this.routes,
    required this.pagination,
    required this.metrics,
    required this.permissions,
  });

  final List<RoutePlanSummary> routes;
  final LogisticsPagination pagination;
  final LogisticsMetrics metrics;
  final LogisticsPermissions permissions;

  factory RouteListResult.fromMap(Map<String, dynamic> map) {
    return RouteListResult(
      routes: _mapList(map['routes']).map(RoutePlanSummary.fromMap).toList(),
      pagination: LogisticsPagination.fromMap(_mapValue(map['pagination'])),
      metrics: LogisticsMetrics.fromMap(_mapValue(map['metrics'])),
      permissions: LogisticsPermissions.fromMap(
        _mapValue(map['permissions']),
      ),
    );
  }
}

class RoutePlanSummary {
  const RoutePlanSummary({
    required this.id,
    required this.name,
    required this.routeDate,
    required this.status,
    required this.statusLabel,
    required this.originLabel,
    required this.cities,
    required this.driverId,
    required this.driverName,
    required this.vehicleId,
    required this.vehicleName,
    required this.totalStops,
    required this.completedStops,
    required this.distanceMeters,
    required this.durationSeconds,
  });

  final String id;
  final String name;
  final DateTime routeDate;
  final String status;
  final String statusLabel;
  final String originLabel;
  final List<String> cities;
  final String? driverId;
  final String driverName;
  final String? vehicleId;
  final String vehicleName;
  final int totalStops;
  final int completedStops;
  final int distanceMeters;
  final int durationSeconds;

  double get progress => totalStops == 0 ? 0 : completedStops / totalStops;
  double get distanceKm => distanceMeters / 1000;

  factory RoutePlanSummary.fromMap(Map<String, dynamic> map) {
    final status = _string(map['status'], fallback: 'draft');
    return RoutePlanSummary(
      id: _string(map['id'], fallback: _string(map['objectId'])),
      name: _string(map['name'], fallback: 'Rota sem nome'),
      routeDate: _dateTime(map['routeDate'] ?? map['date']),
      status: status,
      statusLabel: _string(
        map['statusLabel'],
        fallback: _routeStatusLabel(status),
      ),
      originLabel: _string(map['originLabel']),
      cities: _stringList(map['cities']),
      driverId: _nullableString(map['driverId']),
      driverName: _string(map['driverName']),
      vehicleId: _nullableString(map['vehicleId']),
      vehicleName: _string(map['vehicleName']),
      totalStops: _integer(map['totalStops'] ?? map['stopsCount']),
      completedStops: _integer(map['completedStops']),
      distanceMeters: _integer(map['distanceMeters']),
      durationSeconds: _integer(map['durationSeconds']),
    );
  }
}

class RoutePlan {
  const RoutePlan({
    required this.id,
    required this.name,
    required this.routeDate,
    required this.status,
    required this.statusLabel,
    required this.origin,
    required this.returnToOrigin,
    required this.driverId,
    required this.driverName,
    required this.vehicleId,
    required this.vehicleName,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.encodedPolyline,
    required this.polylinePoints,
    required this.stops,
  });

  final String? id;
  final String name;
  final DateTime routeDate;
  final String status;
  final String statusLabel;
  final LogisticsAddress origin;
  final bool returnToOrigin;
  final String? driverId;
  final String driverName;
  final String? vehicleId;
  final String vehicleName;
  final int distanceMeters;
  final int durationSeconds;
  final String encodedPolyline;
  final List<RouteCoordinate> polylinePoints;
  final List<RouteStop> stops;

  double get distanceKm => distanceMeters / 1000;

  factory RoutePlan.fromMap(Map<String, dynamic> map) {
    final status = _string(map['status'], fallback: 'draft');
    return RoutePlan(
      id: _nullableString(map['id'] ?? map['objectId']),
      name: _string(map['name'], fallback: 'Nova rota'),
      routeDate: _dateTime(map['routeDate'] ?? map['date']),
      status: status,
      statusLabel: _string(
        map['statusLabel'],
        fallback: _routeStatusLabel(status),
      ),
      origin: LogisticsAddress.fromMap(_mapValue(map['origin'])),
      returnToOrigin: _boolean(map['returnToOrigin']),
      driverId: _nullableString(map['driverId']),
      driverName: _string(map['driverName']),
      vehicleId: _nullableString(map['vehicleId']),
      vehicleName: _string(map['vehicleName']),
      distanceMeters: _integer(map['distanceMeters']),
      durationSeconds: _integer(map['durationSeconds']),
      encodedPolyline: _string(map['encodedPolyline']),
      polylinePoints: _mapList(map['polylinePoints'])
          .map(RouteCoordinate.fromMap)
          .where((point) => point.isValid)
          .toList(),
      stops: _mapList(map['stops']).map(RouteStop.fromMap).toList()
        ..sort((a, b) => a.sequence.compareTo(b.sequence)),
    );
  }
}

class RouteCoordinate {
  const RouteCoordinate({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  bool get isValid =>
      latitude >= -90 && latitude <= 90 && longitude >= -180 && longitude <= 180;

  factory RouteCoordinate.fromMap(Map<String, dynamic> map) {
    return RouteCoordinate(
      latitude: _double(map['latitude'] ?? map['lat']),
      longitude: _double(map['longitude'] ?? map['lng']),
    );
  }
}

class RouteCandidate {
  const RouteCandidate({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.document,
    required this.kind,
    required this.kindLabel,
    required this.referenceId,
    required this.referenceLabel,
    required this.address,
    required this.hasValidAddress,
    required this.priority,
    required this.timeWindowStart,
    required this.timeWindowEnd,
  });

  final String id;
  final String clientId;
  final String clientName;
  final String document;
  final String kind;
  final String kindLabel;
  final String? referenceId;
  final String referenceLabel;
  final LogisticsAddress address;
  final bool hasValidAddress;
  final int priority;
  final DateTime? timeWindowStart;
  final DateTime? timeWindowEnd;

  factory RouteCandidate.fromMap(Map<String, dynamic> map) {
    final kind = _string(map['kind'], fallback: 'visit');
    final address = LogisticsAddress.fromMap(_mapValue(map['address']));
    return RouteCandidate(
      id: _string(
        map['id'],
        fallback: '${_string(map['clientId'])}:$kind:${_string(map['referenceId'])}',
      ),
      clientId: _string(map['clientId']),
      clientName: _string(map['clientName'], fallback: 'Cliente sem nome'),
      document: _string(map['document']),
      kind: kind,
      kindLabel: _string(
        map['kindLabel'],
        fallback: kind == 'delivery' ? 'Entrega' : 'Visita',
      ),
      referenceId: _nullableString(map['referenceId']),
      referenceLabel: _string(map['referenceLabel']),
      address: address,
      hasValidAddress: _boolean(
        map['hasValidAddress'],
        fallback: address.formatted.isNotEmpty,
      ),
      priority: _integer(map['priority']),
      timeWindowStart: _nullableDateTime(map['timeWindowStart']),
      timeWindowEnd: _nullableDateTime(map['timeWindowEnd']),
    );
  }
}

class RouteStop {
  const RouteStop({
    required this.id,
    required this.sequence,
    required this.clientId,
    required this.clientName,
    required this.kind,
    required this.kindLabel,
    required this.referenceId,
    required this.referenceLabel,
    required this.address,
    required this.status,
    required this.statusLabel,
    required this.estimatedArrival,
    required this.completedAt,
    required this.notes,
  });

  final String id;
  final int sequence;
  final String clientId;
  final String clientName;
  final String kind;
  final String kindLabel;
  final String? referenceId;
  final String referenceLabel;
  final LogisticsAddress address;
  final String status;
  final String statusLabel;
  final DateTime? estimatedArrival;
  final DateTime? completedAt;
  final String notes;

  bool get isCompleted => status == 'completed';

  factory RouteStop.fromMap(Map<String, dynamic> map) {
    final status = _string(map['status'], fallback: 'pending');
    final kind = _string(map['kind'], fallback: 'visit');
    return RouteStop(
      id: _string(map['id'], fallback: _string(map['objectId'])),
      sequence: _integer(map['sequence']),
      clientId: _string(map['clientId']),
      clientName: _string(map['clientName'], fallback: 'Cliente sem nome'),
      kind: kind,
      kindLabel: _string(
        map['kindLabel'],
        fallback: kind == 'delivery' ? 'Entrega' : 'Visita',
      ),
      referenceId: _nullableString(map['referenceId']),
      referenceLabel: _string(map['referenceLabel']),
      address: LogisticsAddress.fromMap(_mapValue(map['address'])),
      status: status,
      statusLabel: _string(
        map['statusLabel'],
        fallback: _stopStatusLabel(status),
      ),
      estimatedArrival: _nullableDateTime(map['estimatedArrival']),
      completedAt: _nullableDateTime(map['completedAt']),
      notes: _string(map['notes']),
    );
  }
}

class Carrier {
  const Carrier({
    required this.id,
    required this.name,
    required this.document,
    required this.phone,
    required this.email,
    required this.website,
    required this.trackingUrlTemplate,
    required this.provider,
    required this.providerSlug,
    required this.active,
    required this.supportsAutomaticTracking,
  });

  final String? id;
  final String name;
  final String document;
  final String phone;
  final String email;
  final String website;
  final String trackingUrlTemplate;
  final String provider;
  final String providerSlug;
  final bool active;
  final bool supportsAutomaticTracking;

  factory Carrier.fromMap(Map<String, dynamic> map) {
    return Carrier(
      id: _nullableString(map['id'] ?? map['objectId']),
      name: _string(map['name']),
      document: _string(map['document']),
      phone: _string(map['phone']),
      email: _string(map['email']),
      website: _string(map['website']),
      trackingUrlTemplate: _string(map['trackingUrlTemplate']),
      provider: _string(map['provider'], fallback: 'manual'),
      providerSlug: _string(map['providerSlug']),
      active: _boolean(map['active'], fallback: true),
      supportsAutomaticTracking: _boolean(
        map['supportsAutomaticTracking'],
        fallback: _string(map['provider'], fallback: 'manual') != 'manual',
      ),
    );
  }

  Map<String, dynamic> toRequest() => {
        'carrierId': id,
        'name': name.trim(),
        'document': document.trim(),
        'phone': phone.trim(),
        'email': email.trim().toLowerCase(),
        'website': website.trim(),
        'trackingUrlTemplate': trackingUrlTemplate.trim(),
        'provider': provider,
        'providerSlug': providerSlug.trim(),
        'active': active,
      };
}

class TrackingListResult {
  const TrackingListResult({
    required this.trackings,
    required this.pagination,
    required this.metrics,
    required this.permissions,
  });

  final List<ShipmentTracking> trackings;
  final LogisticsPagination pagination;
  final LogisticsMetrics metrics;
  final LogisticsPermissions permissions;

  factory TrackingListResult.fromMap(Map<String, dynamic> map) {
    return TrackingListResult(
      trackings: _mapList(map['trackings'])
          .map(ShipmentTracking.fromMap)
          .toList(),
      pagination: LogisticsPagination.fromMap(_mapValue(map['pagination'])),
      metrics: LogisticsMetrics.fromMap(_mapValue(map['metrics'])),
      permissions: LogisticsPermissions.fromMap(
        _mapValue(map['permissions']),
      ),
    );
  }
}

class TrackingOrderOption {
  const TrackingOrderOption({
    required this.id,
    required this.number,
    required this.clientId,
    required this.clientName,
    required this.city,
  });

  final String id;
  final String number;
  final String clientId;
  final String clientName;
  final String city;

  String get label => number.isEmpty
      ? clientName
      : 'Pedido #$number — $clientName';

  factory TrackingOrderOption.fromMap(Map<String, dynamic> map) {
    return TrackingOrderOption(
      id: _string(map['id'], fallback: _string(map['objectId'])),
      number: _string(map['number'], fallback: _string(map['orderNumber'])),
      clientId: _string(map['clientId']),
      clientName: _string(map['clientName'], fallback: 'Cliente sem nome'),
      city: _string(map['city']),
    );
  }
}

class ShipmentTracking {
  const ShipmentTracking({
    required this.id,
    required this.orderId,
    required this.orderNumber,
    required this.clientId,
    required this.clientName,
    required this.carrierId,
    required this.carrierName,
    required this.trackingCode,
    required this.status,
    required this.statusLabel,
    required this.postedAt,
    required this.estimatedDeliveryAt,
    required this.deliveredAt,
    required this.lastEventAt,
    required this.lastEventDescription,
    required this.trackingUrl,
    required this.events,
  });

  final String? id;
  final String? orderId;
  final String orderNumber;
  final String clientId;
  final String clientName;
  final String carrierId;
  final String carrierName;
  final String trackingCode;
  final String status;
  final String statusLabel;
  final DateTime? postedAt;
  final DateTime? estimatedDeliveryAt;
  final DateTime? deliveredAt;
  final DateTime? lastEventAt;
  final String lastEventDescription;
  final String trackingUrl;
  final List<TrackingEvent> events;

  bool get hasException => status == 'exception' || status == 'delayed';
  bool get isDelivered => status == 'delivered';

  factory ShipmentTracking.fromMap(Map<String, dynamic> map) {
    final status = _string(map['status'], fallback: 'pending');
    return ShipmentTracking(
      id: _nullableString(map['id'] ?? map['objectId']),
      orderId: _nullableString(map['orderId']),
      orderNumber: _string(map['orderNumber']),
      clientId: _string(map['clientId']),
      clientName: _string(map['clientName'], fallback: 'Cliente sem nome'),
      carrierId: _string(map['carrierId']),
      carrierName: _string(map['carrierName']),
      trackingCode: _string(map['trackingCode']),
      status: status,
      statusLabel: _string(
        map['statusLabel'],
        fallback: _trackingStatusLabel(status),
      ),
      postedAt: _nullableDateTime(map['postedAt']),
      estimatedDeliveryAt: _nullableDateTime(map['estimatedDeliveryAt']),
      deliveredAt: _nullableDateTime(map['deliveredAt']),
      lastEventAt: _nullableDateTime(map['lastEventAt']),
      lastEventDescription: _string(map['lastEventDescription']),
      trackingUrl: _string(map['trackingUrl']),
      events: _mapList(map['events']).map(TrackingEvent.fromMap).toList(),
    );
  }
}

class TrackingEvent {
  const TrackingEvent({
    required this.occurredAt,
    required this.status,
    required this.description,
    required this.location,
  });

  final DateTime occurredAt;
  final String status;
  final String description;
  final String location;

  factory TrackingEvent.fromMap(Map<String, dynamic> map) {
    return TrackingEvent(
      occurredAt: _dateTime(map['occurredAt'] ?? map['date']),
      status: _string(map['status']),
      description: _string(map['description'], fallback: _string(map['message'])),
      location: _string(map['location']),
    );
  }
}

class LogisticsPagination {
  const LogisticsPagination({
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

  factory LogisticsPagination.fromMap(Map<String, dynamic> map) {
    return LogisticsPagination(
      page: _integer(map['page'], fallback: 1),
      pageSize: _integer(map['pageSize'], fallback: 20),
      totalItems: _integer(map['totalItems']),
      totalPages: _integer(map['totalPages']),
      hasNextPage: _boolean(map['hasNextPage']),
    );
  }

  static const empty = LogisticsPagination(
    page: 1,
    pageSize: 20,
    totalItems: 0,
    totalPages: 0,
    hasNextPage: false,
  );
}

List<Map<String, dynamic>> _mapList(dynamic value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList();
}

Map<String, dynamic> _mapValue(dynamic value) {
  return value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
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
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

double _double(dynamic value, {double fallback = 0}) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString().replaceAll(',', '.') ?? '') ?? fallback;
}

double? _nullableDouble(dynamic value) {
  if (value == null || value.toString().trim().isEmpty) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString().replaceAll(',', '.'));
}

bool _boolean(dynamic value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    if (value.toLowerCase() == 'true') return true;
    if (value.toLowerCase() == 'false') return false;
  }
  return fallback;
}

DateTime _dateTime(dynamic value) {
  return _nullableDateTime(value) ?? DateTime.now();
}

DateTime? _nullableDateTime(dynamic value) {
  if (value is DateTime) return value.toLocal();
  if (value is Map) {
    return _nullableDateTime(value['iso'] ?? value['date']);
  }
  final text = value?.toString() ?? '';
  return DateTime.tryParse(text)?.toLocal();
}

List<String> _stringList(dynamic value) {
  if (value is! List) return const [];
  return value
      .map((item) => item?.toString().trim() ?? '')
      .where((item) => item.isNotEmpty)
      .toList();
}

String _routeStatusLabel(String status) {
  switch (status) {
    case 'ready':
      return 'Pronta';
    case 'in_progress':
      return 'Em andamento';
    case 'completed':
      return 'Concluída';
    case 'cancelled':
      return 'Cancelada';
    default:
      return 'Rascunho';
  }
}

String _stopStatusLabel(String status) {
  switch (status) {
    case 'in_progress':
      return 'Em deslocamento';
    case 'completed':
      return 'Concluída';
    case 'absent':
      return 'Cliente ausente';
    case 'cancelled':
      return 'Cancelada';
    default:
      return 'Pendente';
  }
}

String _trackingStatusLabel(String status) {
  switch (status) {
    case 'posted':
      return 'Postado';
    case 'in_transit':
      return 'Em trânsito';
    case 'out_for_delivery':
      return 'Saiu para entrega';
    case 'delivered':
      return 'Entregue';
    case 'delayed':
      return 'Atrasado';
    case 'exception':
      return 'Problema na entrega';
    default:
      return 'Aguardando postagem';
  }
}

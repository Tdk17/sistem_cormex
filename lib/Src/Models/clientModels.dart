class ClientListResult {
  const ClientListResult({
    required this.clients,
    required this.pagination,
    required this.portfolio,
    required this.permissions,
  });

  final List<ClientSummary> clients;
  final ClientPagination pagination;
  final ClientPortfolio portfolio;
  final ClientPermissions permissions;

  factory ClientListResult.fromMap(Map<String, dynamic> map) {
    return ClientListResult(
      clients: _mapList(map['clients']).map(ClientSummary.fromMap).toList(),
      pagination: ClientPagination.fromMap(_mapValue(map['pagination'])),
      portfolio: ClientPortfolio.fromMap(_mapValue(map['portfolio'])),
      permissions: ClientPermissions.fromMap(_mapValue(map['permissions'])),
    );
  }
}

class ClientSummary {
  const ClientSummary({
    required this.id,
    required this.type,
    required this.document,
    required this.legalName,
    required this.tradeName,
    required this.phone,
    required this.email,
    required this.city,
    required this.state,
    required this.blocked,
    required this.portfolioStatus,
  });

  final String id;
  final String type;
  final String document;
  final String legalName;
  final String tradeName;
  final String phone;
  final String email;
  final String city;
  final String state;
  final bool blocked;
  final String portfolioStatus;

  String get displayName => tradeName.isEmpty ? legalName : tradeName;
  String get location => [city, state].where((item) => item.isNotEmpty).join(' - ');

  factory ClientSummary.fromMap(Map<String, dynamic> map) {
    return ClientSummary(
      id: _string(map['id'], fallback: _string(map['objectId'])),
      type: _string(map['type'], fallback: 'business'),
      document: _string(map['document']),
      legalName: _string(map['legalName'], fallback: _string(map['name'])),
      tradeName: _string(map['tradeName']),
      phone: _string(map['phone']),
      email: _string(map['email']),
      city: _string(map['city']),
      state: _string(map['state']),
      blocked: _boolean(map['blocked']),
      portfolioStatus: _string(map['portfolioStatus'], fallback: 'active'),
    );
  }
}

class ClientPagination {
  const ClientPagination({
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

  factory ClientPagination.fromMap(Map<String, dynamic> map) {
    return ClientPagination(
      page: _integer(map['page'], fallback: 1),
      pageSize: _integer(map['pageSize'], fallback: 20),
      totalItems: _integer(map['totalItems']),
      totalPages: _integer(map['totalPages']),
      hasNextPage: _boolean(map['hasNextPage']),
    );
  }
}

class ClientPortfolio {
  const ClientPortfolio({required this.total, required this.segments});

  final int total;
  final List<ClientPortfolioSegment> segments;

  factory ClientPortfolio.fromMap(Map<String, dynamic> map) {
    return ClientPortfolio(
      total: _integer(map['total']),
      segments: _mapList(map['segments'])
          .map(ClientPortfolioSegment.fromMap)
          .toList(),
    );
  }

  static const empty = ClientPortfolio(total: 0, segments: []);
}

class ClientPortfolioSegment {
  const ClientPortfolioSegment({
    required this.key,
    required this.label,
    required this.value,
    required this.percent,
  });

  final String key;
  final String label;
  final int value;
  final double percent;

  factory ClientPortfolioSegment.fromMap(Map<String, dynamic> map) {
    return ClientPortfolioSegment(
      key: _string(map['key']),
      label: _string(map['label']),
      value: _integer(map['value']),
      percent: _double(map['percent']),
    );
  }
}

class ClientPermissions {
  const ClientPermissions({
    required this.canCreate,
    required this.canEdit,
    required this.canDelete,
    required this.canImport,
    required this.canManageLinks,
  });

  final bool canCreate;
  final bool canEdit;
  final bool canDelete;
  final bool canImport;
  final bool canManageLinks;

  factory ClientPermissions.fromMap(Map<String, dynamic> map) {
    return ClientPermissions(
      canCreate: _boolean(map['canCreate'], fallback: true),
      canEdit: _boolean(map['canEdit'], fallback: true),
      canDelete: _boolean(map['canDelete'], fallback: true),
      canImport: _boolean(map['canImport']),
      canManageLinks: _boolean(map['canManageLinks']),
    );
  }

  static const all = ClientPermissions(
    canCreate: true,
    canEdit: true,
    canDelete: true,
    canImport: false,
    canManageLinks: false,
  );
}

class ClientFormOptions {
  const ClientFormOptions({
    required this.fiscalExceptions,
    required this.segments,
    required this.networks,
    required this.states,
    required this.permissions,
  });

  final List<ClientOption> fiscalExceptions;
  final List<ClientOption> segments;
  final List<ClientOption> networks;
  final List<ClientOption> states;
  final ClientPermissions permissions;

  factory ClientFormOptions.fromMap(Map<String, dynamic> map) {
    return ClientFormOptions(
      fiscalExceptions: _mapList(map['fiscalExceptions'])
          .map(ClientOption.fromMap)
          .toList(),
      segments: _mapList(map['segments']).map(ClientOption.fromMap).toList(),
      networks: _mapList(map['networks']).map(ClientOption.fromMap).toList(),
      states: _mapList(map['states']).map(ClientOption.fromMap).toList(),
      permissions: ClientPermissions.fromMap(_mapValue(map['permissions'])),
    );
  }
}

class ClientOption {
  const ClientOption({required this.id, required this.label});

  final String id;
  final String label;

  factory ClientOption.fromMap(Map<String, dynamic> map) {
    return ClientOption(
      id: _string(
        map['id'],
        fallback: _string(
          map['objectId'],
          fallback: _string(map['value']),
        ),
      ),
      label: _string(map['label'], fallback: _string(map['name'])),
    );
  }
}

class ClientDetail {
  const ClientDetail({
    required this.id,
    required this.type,
    required this.document,
    required this.legalName,
    required this.tradeName,
    required this.phones,
    required this.emails,
    required this.stateRegistration,
    required this.suframa,
    required this.fiscalExceptionId,
    required this.segmentId,
    required this.networkId,
    required this.additionalInfo,
    required this.blocked,
    required this.primaryAddress,
    required this.additionalAddresses,
    required this.contacts,
  });

  final String? id;
  final String type;
  final String document;
  final String legalName;
  final String tradeName;
  final List<String> phones;
  final List<String> emails;
  final String stateRegistration;
  final String suframa;
  final String? fiscalExceptionId;
  final String? segmentId;
  final String? networkId;
  final String additionalInfo;
  final bool blocked;
  final ClientAddress primaryAddress;
  final List<ClientAddress> additionalAddresses;
  final List<ClientContact> contacts;

  bool get isPersisted => id != null && id!.isNotEmpty;

  factory ClientDetail.empty() {
    return const ClientDetail(
      id: null,
      type: 'business',
      document: '',
      legalName: '',
      tradeName: '',
      phones: [''],
      emails: [''],
      stateRegistration: '',
      suframa: '',
      fiscalExceptionId: null,
      segmentId: null,
      networkId: null,
      additionalInfo: '',
      blocked: false,
      primaryAddress: ClientAddress.empty(primary: true),
      additionalAddresses: [],
      contacts: [],
    );
  }

  factory ClientDetail.fromMap(Map<String, dynamic> map) {
    final phones = _stringList(map['phones']);
    final emails = _stringList(map['emails']);
    return ClientDetail(
      id: _nullableString(map['id']) ?? _nullableString(map['objectId']),
      type: _string(map['type'], fallback: 'business'),
      document: _string(map['document']),
      legalName: _string(map['legalName'], fallback: _string(map['name'])),
      tradeName: _string(map['tradeName']),
      phones: phones.isEmpty ? [_string(map['phone'])] : phones,
      emails: emails.isEmpty ? [_string(map['email'])] : emails,
      stateRegistration: _string(map['stateRegistration']),
      suframa: _string(map['suframa']),
      fiscalExceptionId: _nullableString(map['fiscalExceptionId']),
      segmentId: _nullableString(map['segmentId']),
      networkId: _nullableString(map['networkId']),
      additionalInfo: _string(map['additionalInfo']),
      blocked: _boolean(map['blocked']),
      primaryAddress: ClientAddress.fromMap(
        _mapValue(map['primaryAddress']),
        primaryFallback: true,
      ),
      additionalAddresses: _mapList(map['additionalAddresses'])
          .map(ClientAddress.fromMap)
          .toList(),
      contacts:
          _mapList(map['contacts']).map(ClientContact.fromMap).toList(),
    );
  }

  Map<String, dynamic> toRequest() {
    return {
      if (id != null) 'clientId': id,
      'type': type,
      'document': document.trim(),
      'legalName': legalName.trim(),
      'tradeName': tradeName.trim(),
      'phones': phones.map((item) => item.trim()).where((item) => item.isNotEmpty).toList(),
      'emails': emails.map((item) => item.trim().toLowerCase()).where((item) => item.isNotEmpty).toList(),
      'stateRegistration': stateRegistration.trim(),
      'suframa': suframa.trim(),
      'fiscalExceptionId': fiscalExceptionId,
      'segmentId': segmentId,
      'networkId': networkId,
      'additionalInfo': additionalInfo.trim(),
      'blocked': blocked,
      'primaryAddress': primaryAddress.toRequest(),
      'additionalAddresses': additionalAddresses.map((item) => item.toRequest()).toList(),
      'contacts': contacts.map((item) => item.toRequest()).toList(),
    };
  }
}

class ClientAddress {
  const ClientAddress({
    required this.id,
    required this.label,
    required this.postalCode,
    required this.street,
    required this.number,
    required this.complement,
    required this.district,
    required this.city,
    required this.state,
    required this.primary,
  });

  final String? id;
  final String label;
  final String postalCode;
  final String street;
  final String number;
  final String complement;
  final String district;
  final String city;
  final String state;
  final bool primary;

  const ClientAddress.empty({bool primary = false})
      : id = null,
        label = '',
        postalCode = '',
        street = '',
        number = '',
        complement = '',
        district = '',
        city = '',
        state = '',
        primary = primary;

  factory ClientAddress.fromMap(
    Map<String, dynamic> map, {
    bool primaryFallback = false,
  }) {
    return ClientAddress(
      id: _nullableString(map['id']) ?? _nullableString(map['objectId']),
      label: _string(map['label']),
      postalCode: _string(map['postalCode'], fallback: _string(map['zipCode'])),
      street: _string(map['street'], fallback: _string(map['address'])),
      number: _string(map['number']),
      complement: _string(map['complement']),
      district: _string(map['district'], fallback: _string(map['neighborhood'])),
      city: _string(map['city']),
      state: _string(map['state']),
      primary: _boolean(map['primary'], fallback: primaryFallback),
    );
  }

  Map<String, dynamic> toRequest() => {
        if (id != null) 'id': id,
        'label': label.trim(),
        'postalCode': postalCode.trim(),
        'street': street.trim(),
        'number': number.trim(),
        'complement': complement.trim(),
        'district': district.trim(),
        'city': city.trim(),
        'state': state,
        'primary': primary,
      };
}

class ClientContact {
  const ClientContact({
    required this.id,
    required this.name,
    required this.position,
    required this.phones,
    required this.emails,
  });

  final String? id;
  final String name;
  final String position;
  final List<String> phones;
  final List<String> emails;

  factory ClientContact.fromMap(Map<String, dynamic> map) {
    return ClientContact(
      id: _nullableString(map['id']) ?? _nullableString(map['objectId']),
      name: _string(map['name']),
      position: _string(map['position']),
      phones: _stringList(map['phones']),
      emails: _stringList(map['emails']),
    );
  }

  Map<String, dynamic> toRequest() => {
        if (id != null) 'id': id,
        'name': name.trim(),
        'position': position.trim(),
        'phones': phones.map((item) => item.trim()).where((item) => item.isNotEmpty).toList(),
        'emails': emails.map((item) => item.trim().toLowerCase()).where((item) => item.isNotEmpty).toList(),
      };
}

class ClientImportResult {
  const ClientImportResult({
    required this.created,
    required this.updated,
    required this.skipped,
    required this.errors,
  });

  final int created;
  final int updated;
  final int skipped;
  final List<String> errors;

  factory ClientImportResult.fromMap(Map<String, dynamic> map) {
    return ClientImportResult(
      created: _integer(map['created']),
      updated: _integer(map['updated']),
      skipped: _integer(map['skipped']),
      errors: _stringList(map['errors']),
    );
  }
}

Map<String, dynamic> _mapValue(dynamic value) {
  return value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
}

List<Map<String, dynamic>> _mapList(dynamic value) {
  if (value is! List) return <Map<String, dynamic>>[];
  return value.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
}

List<String> _stringList(dynamic value) {
  if (value is! List) return <String>[];
  return value.map((item) => item?.toString() ?? '').where((item) => item.isNotEmpty).toList();
}

String _string(dynamic value, {String fallback = ''}) {
  final text = value?.toString() ?? '';
  return text.isEmpty ? fallback : text;
}

String? _nullableString(dynamic value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

int _integer(dynamic value, {int fallback = 0}) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

double _double(dynamic value, {double fallback = 0}) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}

bool _boolean(dynamic value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value?.toString().toLowerCase() == 'true') return true;
  if (value?.toString().toLowerCase() == 'false') return false;
  return fallback;
}

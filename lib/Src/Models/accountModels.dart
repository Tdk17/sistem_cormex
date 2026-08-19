class AccountWorkspace {
  const AccountWorkspace({
    required this.user,
    required this.company,
    required this.permissions,
    required this.setupRequired,
    required this.userLimit,
    required this.activeUserCount,
    required this.availableRoles,
  });

  final AccountUser user;
  final CompanyProfile? company;
  final AccountPermissions permissions;
  final bool setupRequired;
  final int userLimit;
  final int activeUserCount;
  final List<AccountOption> availableRoles;

  factory AccountWorkspace.fromMap(Map<String, dynamic> map) {
    return AccountWorkspace(
      user: AccountUser.fromMap(_mapValue(map['user'])),
      company: map['company'] is Map
          ? CompanyProfile.fromMap(_mapValue(map['company']))
          : null,
      permissions:
          AccountPermissions.fromMap(_mapValue(map['permissions'])),
      setupRequired: _boolean(map['setupRequired']),
      userLimit: _integer(map['userLimit'], fallback: 5),
      activeUserCount: _integer(map['activeUserCount'], fallback: 1),
      availableRoles:
          _mapList(map['availableRoles']).map(AccountOption.fromMap).toList(),
    );
  }

  AccountWorkspace copyWith({
    AccountUser? user,
    CompanyProfile? company,
    bool? setupRequired,
    int? activeUserCount,
  }) {
    return AccountWorkspace(
      user: user ?? this.user,
      company: company ?? this.company,
      permissions: permissions,
      setupRequired: setupRequired ?? this.setupRequired,
      userLimit: userLimit,
      activeUserCount: activeUserCount ?? this.activeUserCount,
      availableRoles: availableRoles,
    );
  }
}

class AccountUser {
  const AccountUser({
    required this.id,
    required this.fullname,
    required this.email,
    required this.phone,
    required this.document,
    required this.role,
    required this.roleLabel,
    required this.active,
    required this.owner,
    required this.companyId,
    required this.sellerId,
    required this.avatarUrl,
    this.createdAt,
  });

  final String id;
  final String fullname;
  final String email;
  final String phone;
  final String document;
  final String role;
  final String roleLabel;
  final bool active;
  final bool owner;
  final String? companyId;
  final String? sellerId;
  final String? avatarUrl;
  final DateTime? createdAt;

  factory AccountUser.fromMap(Map<String, dynamic> map) {
    return AccountUser(
      id: _string(map['id'], fallback: _string(map['objectId'])),
      fullname: _string(
        map['fullname'],
        fallback: _string(map['name']),
      ),
      email: _string(map['email']),
      phone: _string(map['phone']),
      document: _string(map['document']),
      role: _string(map['role'], fallback: 'seller'),
      roleLabel: _string(map['roleLabel'], fallback: 'Usuário'),
      active: _boolean(map['active'], fallback: true),
      owner: _boolean(map['owner']),
      companyId: _nullableString(map['companyId']),
      sellerId: _nullableString(map['sellerId']),
      avatarUrl: _nullableString(map['avatarUrl']),
      createdAt: DateTime.tryParse(_string(map['createdAt'])),
    );
  }

  AccountUser copyWith({
    String? fullname,
    String? phone,
    String? document,
    String? role,
    String? roleLabel,
    bool? active,
    String? companyId,
    String? sellerId,
    String? avatarUrl,
  }) {
    return AccountUser(
      id: id,
      fullname: fullname ?? this.fullname,
      email: email,
      phone: phone ?? this.phone,
      document: document ?? this.document,
      role: role ?? this.role,
      roleLabel: roleLabel ?? this.roleLabel,
      active: active ?? this.active,
      owner: owner,
      companyId: companyId ?? this.companyId,
      sellerId: sellerId ?? this.sellerId,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt,
    );
  }
}

class AccountPermissions {
  const AccountPermissions({
    required this.canEditProfile,
    required this.canManageCompany,
    required this.canManageUsers,
    required this.canManagePaymentTerms,
  });

  final bool canEditProfile;
  final bool canManageCompany;
  final bool canManageUsers;
  final bool canManagePaymentTerms;

  factory AccountPermissions.fromMap(Map<String, dynamic> map) {
    return AccountPermissions(
      canEditProfile: _boolean(map['canEditProfile'], fallback: true),
      canManageCompany: _boolean(map['canManageCompany']),
      canManageUsers: _boolean(map['canManageUsers']),
      canManagePaymentTerms: _boolean(map['canManagePaymentTerms']),
    );
  }
}

class CompanyProfile {
  const CompanyProfile({
    required this.id,
    required this.legalName,
    required this.tradeName,
    required this.document,
    required this.email,
    required this.phone,
    required this.additionalInfo,
    required this.logoUrl,
    required this.includeFreightInIpiBase,
    required this.commissionOnIpi,
    required this.commissionOnFreight,
    required this.commissionSettlement,
    required this.stockControlEnabled,
    required this.contacts,
  });

  final String? id;
  final String legalName;
  final String tradeName;
  final String document;
  final String email;
  final String phone;
  final String additionalInfo;
  final String? logoUrl;
  final bool includeFreightInIpiBase;
  final bool commissionOnIpi;
  final bool commissionOnFreight;
  final String commissionSettlement;
  final bool stockControlEnabled;
  final List<CompanyContact> contacts;

  bool get isPersisted => id != null && id!.isNotEmpty;

  factory CompanyProfile.empty(AccountUser user) {
    return CompanyProfile(
      id: null,
      legalName: '',
      tradeName: '',
      document: '',
      email: user.email,
      phone: user.phone,
      additionalInfo: '',
      logoUrl: null,
      includeFreightInIpiBase: false,
      commissionOnIpi: false,
      commissionOnFreight: false,
      commissionSettlement: 'order_liquidity',
      stockControlEnabled: false,
      contacts: [
        CompanyContact(
          id: null,
          name: user.fullname,
          position: 'Administrador',
          phone: user.phone,
          email: user.email,
        ),
      ],
    );
  }

  factory CompanyProfile.fromMap(Map<String, dynamic> map) {
    return CompanyProfile(
      id: _nullableString(map['id']),
      legalName: _string(map['legalName']),
      tradeName: _string(map['tradeName'], fallback: _string(map['name'])),
      document: _string(map['document']),
      email: _string(map['email']),
      phone: _string(map['phone']),
      additionalInfo: _string(map['additionalInfo']),
      logoUrl: _nullableString(map['logoUrl']),
      includeFreightInIpiBase: _boolean(map['includeFreightInIpiBase']),
      commissionOnIpi: _boolean(map['commissionOnIpi']),
      commissionOnFreight: _boolean(map['commissionOnFreight']),
      commissionSettlement: _string(
        map['commissionSettlement'],
        fallback: 'order_liquidity',
      ),
      stockControlEnabled: _boolean(map['stockControlEnabled']),
      contacts:
          _mapList(map['contacts']).map(CompanyContact.fromMap).toList(),
    );
  }

  CompanyProfile copyWith({
    String? id,
    String? legalName,
    String? tradeName,
    String? document,
    String? email,
    String? phone,
    String? additionalInfo,
    String? logoUrl,
    bool? includeFreightInIpiBase,
    bool? commissionOnIpi,
    bool? commissionOnFreight,
    String? commissionSettlement,
    bool? stockControlEnabled,
    List<CompanyContact>? contacts,
  }) {
    return CompanyProfile(
      id: id ?? this.id,
      legalName: legalName ?? this.legalName,
      tradeName: tradeName ?? this.tradeName,
      document: document ?? this.document,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      additionalInfo: additionalInfo ?? this.additionalInfo,
      logoUrl: logoUrl ?? this.logoUrl,
      includeFreightInIpiBase:
          includeFreightInIpiBase ?? this.includeFreightInIpiBase,
      commissionOnIpi: commissionOnIpi ?? this.commissionOnIpi,
      commissionOnFreight: commissionOnFreight ?? this.commissionOnFreight,
      commissionSettlement:
          commissionSettlement ?? this.commissionSettlement,
      stockControlEnabled: stockControlEnabled ?? this.stockControlEnabled,
      contacts: contacts ?? this.contacts,
    );
  }

  Map<String, dynamic> toRequest() {
    return {
      if (id != null) 'companyId': id,
      'legalName': legalName.trim(),
      'tradeName': tradeName.trim(),
      'document': document.trim(),
      'email': email.trim().toLowerCase(),
      'phone': phone.trim(),
      'additionalInfo': additionalInfo.trim(),
      'includeFreightInIpiBase': includeFreightInIpiBase,
      'commissionOnIpi': commissionOnIpi,
      'commissionOnFreight': commissionOnFreight,
      'commissionSettlement': commissionSettlement,
      'stockControlEnabled': stockControlEnabled,
      'contacts': contacts.map((item) => item.toRequest()).toList(),
    };
  }
}

class CompanyContact {
  const CompanyContact({
    required this.id,
    required this.name,
    required this.position,
    required this.phone,
    required this.email,
  });

  final String? id;
  final String name;
  final String position;
  final String phone;
  final String email;

  factory CompanyContact.fromMap(Map<String, dynamic> map) {
    return CompanyContact(
      id: _nullableString(map['id']),
      name: _string(map['name']),
      position: _string(map['position']),
      phone: _string(map['phone']),
      email: _string(map['email']),
    );
  }

  Map<String, dynamic> toRequest() {
    return {
      if (id != null) 'id': id,
      'name': name.trim(),
      'position': position.trim(),
      'phone': phone.trim(),
      'email': email.trim().toLowerCase(),
    };
  }
}

class ManagedUsersResult {
  const ManagedUsersResult({
    required this.users,
    required this.userLimit,
    required this.activeUserCount,
  });

  final List<AccountUser> users;
  final int userLimit;
  final int activeUserCount;

  factory ManagedUsersResult.fromMap(Map<String, dynamic> map) {
    return ManagedUsersResult(
      users: _mapList(map['users']).map(AccountUser.fromMap).toList(),
      userLimit: _integer(map['userLimit']),
      activeUserCount: _integer(map['activeUserCount']),
    );
  }
}

class PaymentTerm {
  const PaymentTerm({
    required this.id,
    required this.label,
    required this.active,
    required this.installments,
    required this.usageCount,
  });

  final String? id;
  final String label;
  final bool active;
  final int installments;
  final int usageCount;

  factory PaymentTerm.fromMap(Map<String, dynamic> map) {
    return PaymentTerm(
      id: _nullableString(map['id']),
      label: _string(map['label']),
      active: _boolean(map['active'], fallback: true),
      installments: _integer(map['installments'], fallback: 1),
      usageCount: _integer(map['usageCount']),
    );
  }

  Map<String, dynamic> toRequest() {
    return {
      if (id != null) 'paymentTermId': id,
      'label': label.trim(),
      'active': active,
      'installments': installments,
    };
  }
}

class AccountOption {
  const AccountOption({required this.id, required this.label});
  final String id;
  final String label;

  factory AccountOption.fromMap(Map<String, dynamic> map) {
    return AccountOption(
      id: _string(map['id'], fallback: _string(map['value'])),
      label: _string(map['label']),
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

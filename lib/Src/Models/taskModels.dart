class TaskListResult {
  const TaskListResult({
    required this.tasks,
    required this.pagination,
    required this.permissions,
  });

  final List<TaskSummary> tasks;
  final TaskPagination pagination;
  final TaskPermissions permissions;

  factory TaskListResult.fromMap(Map<String, dynamic> map) {
    return TaskListResult(
      tasks: _mapList(map['tasks']).map(TaskSummary.fromMap).toList(),
      pagination: TaskPagination.fromMap(_mapValue(map['pagination'])),
      permissions: TaskPermissions.fromMap(_mapValue(map['permissions'])),
    );
  }
}

class TaskSummary {
  const TaskSummary({
    required this.id,
    required this.entryKind,
    required this.contactMethod,
    required this.contactMethodLabel,
    required this.subject,
    required this.scheduledAt,
    required this.clientId,
    required this.clientName,
    required this.assignedUserId,
    required this.assignedUserName,
    required this.status,
    required this.completedAt,
  });

  final String id;
  final String entryKind;
  final String contactMethod;
  final String contactMethodLabel;
  final String subject;
  final DateTime scheduledAt;
  final String clientId;
  final String clientName;
  final String assignedUserId;
  final String assignedUserName;
  final String status;
  final DateTime? completedAt;

  bool get isCompleted => status == 'completed';

  factory TaskSummary.fromMap(Map<String, dynamic> map) {
    final method = _string(map['contactMethod'], fallback: 'call');
    return TaskSummary(
      id: _string(map['id'], fallback: _string(map['objectId'])),
      entryKind: _string(map['entryKind'], fallback: 'task'),
      contactMethod: method,
      contactMethodLabel: _string(
        map['contactMethodLabel'],
        fallback: _contactMethodLabel(method),
      ),
      subject: _string(map['subject']),
      scheduledAt: _dateTime(map['scheduledAt']),
      clientId: _string(map['clientId']),
      clientName: _string(map['clientName'], fallback: 'Cliente não informado'),
      assignedUserId: _string(map['assignedUserId']),
      assignedUserName: _string(
        map['assignedUserName'],
        fallback: 'Usuário não informado',
      ),
      status: _string(map['status'], fallback: 'pending'),
      completedAt: _nullableDateTime(map['completedAt']),
    );
  }
}

class TaskPagination {
  const TaskPagination({
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

  factory TaskPagination.fromMap(Map<String, dynamic> map) {
    return TaskPagination(
      page: _integer(map['page'], fallback: 1),
      pageSize: _integer(map['pageSize'], fallback: 25),
      totalItems: _integer(map['totalItems']),
      totalPages: _integer(map['totalPages']),
      hasNextPage: _boolean(map['hasNextPage']),
    );
  }
}

class TaskPermissions {
  const TaskPermissions({
    required this.canCreate,
    required this.canRegisterActivity,
    required this.canEdit,
    required this.canDelete,
    required this.canComplete,
    required this.canExport,
    required this.canViewAllSellers,
  });

  final bool canCreate;
  final bool canRegisterActivity;
  final bool canEdit;
  final bool canDelete;
  final bool canComplete;
  final bool canExport;
  final bool canViewAllSellers;

  factory TaskPermissions.fromMap(Map<String, dynamic> map) {
    return TaskPermissions(
      canCreate: _boolean(map['canCreate'], fallback: true),
      canRegisterActivity: _boolean(
        map['canRegisterActivity'],
        fallback: true,
      ),
      canEdit: _boolean(map['canEdit'], fallback: true),
      canDelete: _boolean(map['canDelete'], fallback: true),
      canComplete: _boolean(map['canComplete'], fallback: true),
      canExport: _boolean(map['canExport']),
      canViewAllSellers: _boolean(map['canViewAllSellers']),
    );
  }

  static const initial = TaskPermissions(
    canCreate: true,
    canRegisterActivity: true,
    canEdit: true,
    canDelete: true,
    canComplete: true,
    canExport: false,
    canViewAllSellers: false,
  );
}

class TaskFormOptions {
  const TaskFormOptions({
    required this.contactMethods,
    required this.sellers,
    required this.currentUserId,
    required this.permissions,
  });

  final List<TaskOption> contactMethods;
  final List<TaskOption> sellers;
  final String currentUserId;
  final TaskPermissions permissions;

  factory TaskFormOptions.fromMap(Map<String, dynamic> map) {
    return TaskFormOptions(
      contactMethods: _mapList(map['contactMethods'])
          .map(TaskOption.fromMap)
          .toList(),
      sellers: _mapList(map['sellers']).map(TaskOption.fromMap).toList(),
      currentUserId: _string(map['currentUserId']),
      permissions: TaskPermissions.fromMap(_mapValue(map['permissions'])),
    );
  }
}

class TaskOption {
  const TaskOption({required this.id, required this.label});

  final String id;
  final String label;

  factory TaskOption.fromMap(Map<String, dynamic> map) {
    return TaskOption(
      id: _string(
        map['id'],
        fallback: _string(map['objectId'], fallback: _string(map['value'])),
      ),
      label: _string(map['label'], fallback: _string(map['name'])),
    );
  }
}

class TaskClientOption {
  const TaskClientOption({
    required this.id,
    required this.name,
    required this.document,
    required this.city,
  });

  final String id;
  final String name;
  final String document;
  final String city;

  String get label => document.isEmpty ? name : '$document — $name';

  factory TaskClientOption.fromMap(Map<String, dynamic> map) {
    return TaskClientOption(
      id: _string(map['id'], fallback: _string(map['objectId'])),
      name: _string(
        map['name'],
        fallback: _string(
          map['tradeName'],
          fallback: _string(map['legalName']),
        ),
      ),
      document: _string(map['document']),
      city: _string(map['city']),
    );
  }
}

class TaskDetail {
  const TaskDetail({
    required this.id,
    required this.entryKind,
    required this.scheduledAt,
    required this.contactMethod,
    required this.clientId,
    required this.clientName,
    required this.assignedUserId,
    required this.subject,
    required this.notes,
    required this.status,
  });

  final String? id;
  final String entryKind;
  final DateTime scheduledAt;
  final String contactMethod;
  final String? clientId;
  final String clientName;
  final String assignedUserId;
  final String subject;
  final String notes;
  final String status;

  bool get isPersisted => id != null && id!.isNotEmpty;
  bool get isActivity => entryKind == 'activity';

  factory TaskDetail.empty({
    required String entryKind,
    required String assignedUserId,
  }) {
    final now = DateTime.now();
    final scheduled = entryKind == 'activity'
        ? now
        : DateTime(now.year, now.month, now.day, now.hour + 1);
    return TaskDetail(
      id: null,
      entryKind: entryKind,
      scheduledAt: scheduled,
      contactMethod: 'call',
      clientId: null,
      clientName: '',
      assignedUserId: assignedUserId,
      subject: '',
      notes: '',
      status: entryKind == 'activity' ? 'completed' : 'pending',
    );
  }

  factory TaskDetail.fromMap(Map<String, dynamic> map) {
    return TaskDetail(
      id: _nullableString(map['id']) ?? _nullableString(map['objectId']),
      entryKind: _string(map['entryKind'], fallback: 'task'),
      scheduledAt: _dateTime(map['scheduledAt']),
      contactMethod: _string(map['contactMethod'], fallback: 'call'),
      clientId: _nullableString(map['clientId']),
      clientName: _string(map['clientName']),
      assignedUserId: _string(map['assignedUserId']),
      subject: _string(map['subject']),
      notes: _string(map['notes']),
      status: _string(map['status'], fallback: 'pending'),
    );
  }

  Map<String, dynamic> toRequest() {
    return {
      if (id != null) 'taskId': id,
      'entryKind': entryKind,
      'scheduledAt': scheduledAt.toUtc().toIso8601String(),
      'contactMethod': contactMethod,
      'clientId': clientId,
      'assignedUserId': assignedUserId,
      'subject': subject.trim(),
      'notes': notes.trim(),
      'status': isActivity ? 'completed' : status,
    };
  }
}

class TaskExport {
  const TaskExport({required this.exportId, required this.downloadUrl});

  final String exportId;
  final String? downloadUrl;

  factory TaskExport.fromMap(Map<String, dynamic> map) {
    return TaskExport(
      exportId: _string(map['exportId']),
      downloadUrl: _nullableString(map['downloadUrl']),
    );
  }
}

Map<String, dynamic> _mapValue(dynamic value) {
  return value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
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

String _contactMethodLabel(String value) {
  switch (value) {
    case 'visit':
      return 'Visita';
    case 'email':
      return 'E-mail';
    case 'whatsapp':
      return 'WhatsApp';
    case 'skype':
      return 'Skype';
    case 'other':
      return 'Outro';
    default:
      return 'Ligação';
  }
}

DateTime _dateTime(dynamic value) {
  return _nullableDateTime(value)?.toLocal() ?? DateTime.now();
}

DateTime? _nullableDateTime(dynamic value) {
  if (value is DateTime) return value;
  final text = value?.toString() ?? '';
  return text.isEmpty ? null : DateTime.tryParse(text);
}

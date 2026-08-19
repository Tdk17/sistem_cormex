class DashboardOverview {
  const DashboardOverview({
    required this.generatedAt,
    required this.currency,
    required this.timezone,
    required this.selectedPeriod,
    required this.selectedSellerId,
    required this.filterOptions,
    required this.summary,
    required this.salesEvolution,
    required this.goal,
    required this.clientPortfolio,
    required this.positivation,
    required this.clientAbc,
    required this.preferences,
  });

  final DateTime? generatedAt;
  final String currency;
  final String timezone;
  final String selectedPeriod;
  final String? selectedSellerId;
  final DashboardFilterOptions filterOptions;
  final DashboardSummary summary;
  final DashboardSalesEvolution salesEvolution;
  final DashboardGoal? goal;
  final DashboardBreakdown clientPortfolio;
  final DashboardPositivation positivation;
  final DashboardBreakdown clientAbc;
  final DashboardPreferences preferences;

  factory DashboardOverview.fromMap(Map<String, dynamic> map) {
    final selected = mapValue(map, 'selectedFilters');
    return DashboardOverview(
      generatedAt: DateTime.tryParse(stringValue(map['generatedAt'])),
      currency: stringValue(map['currency'], fallback: 'BRL'),
      timezone: stringValue(
        map['timezone'],
        fallback: 'America/Sao_Paulo',
      ),
      selectedPeriod: stringValue(selected['period']),
      selectedSellerId: nullableString(selected['sellerId']),
      filterOptions: DashboardFilterOptions.fromMap(
        mapValue(map, 'filterOptions'),
      ),
      summary: DashboardSummary.fromMap(mapValue(map, 'summary')),
      salesEvolution: DashboardSalesEvolution.fromMap(
        mapValue(map, 'salesEvolution'),
      ),
      goal: map['goal'] is Map
          ? DashboardGoal.fromMap(mapValue(map, 'goal'))
          : null,
      clientPortfolio: DashboardBreakdown.fromMap(
        mapValue(map, 'clientPortfolio'),
      ),
      positivation: DashboardPositivation.fromMap(
        mapValue(map, 'positivation'),
      ),
      clientAbc: DashboardBreakdown.fromMap(mapValue(map, 'clientAbc')),
      preferences: DashboardPreferences.fromMap(
        mapValue(map, 'preferences'),
      ),
    );
  }
}

class DashboardFilterOptions {
  const DashboardFilterOptions({
    required this.periods,
    required this.sellers,
  });

  final List<DashboardPeriodOption> periods;
  final List<DashboardSellerOption> sellers;

  factory DashboardFilterOptions.fromMap(Map<String, dynamic> map) {
    return DashboardFilterOptions(
      periods: mapList(map['periods'])
          .map(DashboardPeriodOption.fromMap)
          .where((item) => item.value.isNotEmpty)
          .toList(),
      sellers: mapList(map['sellers'])
          .map(DashboardSellerOption.fromMap)
          .where((item) => item.id.isNotEmpty)
          .toList(),
    );
  }
}

class DashboardPeriodOption {
  const DashboardPeriodOption({required this.value, required this.label});

  final String value;
  final String label;

  factory DashboardPeriodOption.fromMap(Map<String, dynamic> map) {
    return DashboardPeriodOption(
      value: stringValue(map['value']),
      label: stringValue(map['label']),
    );
  }
}

class DashboardSellerOption {
  const DashboardSellerOption({
    required this.id,
    required this.name,
    required this.active,
  });

  final String id;
  final String name;
  final bool active;

  factory DashboardSellerOption.fromMap(Map<String, dynamic> map) {
    return DashboardSellerOption(
      id: stringValue(map['id']),
      name: stringValue(map['name']),
      active: boolValue(map['active'], fallback: true),
    );
  }
}

class DashboardSummary {
  const DashboardSummary({
    required this.grossSales,
    required this.grossSalesChangePercent,
    required this.orderCount,
    required this.ordersToday,
    required this.activeClientCount,
    required this.activeClientPercent,
    required this.averageTicket,
    required this.averageTicketChangePercent,
  });

  final double grossSales;
  final double? grossSalesChangePercent;
  final int orderCount;
  final int ordersToday;
  final int activeClientCount;
  final double activeClientPercent;
  final double averageTicket;
  final double? averageTicketChangePercent;

  factory DashboardSummary.fromMap(Map<String, dynamic> map) {
    return DashboardSummary(
      grossSales: doubleValue(map['grossSales']),
      grossSalesChangePercent: nullableDouble(map['grossSalesChangePercent']),
      orderCount: intValue(map['orderCount']),
      ordersToday: intValue(map['ordersToday']),
      activeClientCount: intValue(map['activeClientCount']),
      activeClientPercent: doubleValue(map['activeClientPercent']),
      averageTicket: doubleValue(map['averageTicket']),
      averageTicketChangePercent:
          nullableDouble(map['averageTicketChangePercent']),
    );
  }
}

class DashboardSalesEvolution {
  const DashboardSalesEvolution({
    required this.actual,
    required this.forecast,
  });

  final List<DashboardSalesPoint> actual;
  final List<DashboardSalesPoint> forecast;

  factory DashboardSalesEvolution.fromMap(Map<String, dynamic> map) {
    return DashboardSalesEvolution(
      actual: mapList(map['actual']).map(DashboardSalesPoint.fromMap).toList(),
      forecast:
          mapList(map['forecast']).map(DashboardSalesPoint.fromMap).toList(),
    );
  }
}

class DashboardSalesPoint {
  const DashboardSalesPoint({
    required this.date,
    required this.value,
    required this.orderCount,
  });

  final DateTime? date;
  final double value;
  final int? orderCount;

  factory DashboardSalesPoint.fromMap(Map<String, dynamic> map) {
    return DashboardSalesPoint(
      date: DateTime.tryParse(stringValue(map['date'])),
      value: doubleValue(map['value']),
      orderCount: map['orderCount'] == null ? null : intValue(map['orderCount']),
    );
  }
}

class DashboardGoal {
  const DashboardGoal({
    required this.targetValue,
    required this.achievedValue,
    required this.remainingValue,
    required this.progressPercent,
    required this.remainingBusinessDays,
    required this.requiredPerBusinessDay,
  });

  final double targetValue;
  final double achievedValue;
  final double remainingValue;
  final double progressPercent;
  final int remainingBusinessDays;
  final double requiredPerBusinessDay;

  factory DashboardGoal.fromMap(Map<String, dynamic> map) {
    return DashboardGoal(
      targetValue: doubleValue(map['targetValue']),
      achievedValue: doubleValue(map['achievedValue']),
      remainingValue: doubleValue(map['remainingValue']),
      progressPercent: doubleValue(map['progressPercent']),
      remainingBusinessDays: intValue(map['remainingBusinessDays']),
      requiredPerBusinessDay: doubleValue(map['requiredPerBusinessDay']),
    );
  }
}

class DashboardBreakdown {
  const DashboardBreakdown({
    required this.total,
    required this.segments,
    this.referenceMonths,
  });

  final int total;
  final List<DashboardSegment> segments;
  final int? referenceMonths;

  factory DashboardBreakdown.fromMap(Map<String, dynamic> map) {
    return DashboardBreakdown(
      total: intValue(map['total']),
      segments: mapList(map['segments']).map(DashboardSegment.fromMap).toList(),
      referenceMonths:
          map['referenceMonths'] == null ? null : intValue(map['referenceMonths']),
    );
  }
}

class DashboardPositivation {
  const DashboardPositivation({
    required this.totalClients,
    required this.positivatedClients,
    required this.progressPercent,
    required this.segments,
  });

  final int totalClients;
  final int positivatedClients;
  final double progressPercent;
  final List<DashboardSegment> segments;

  factory DashboardPositivation.fromMap(Map<String, dynamic> map) {
    return DashboardPositivation(
      totalClients: intValue(map['totalClients']),
      positivatedClients: intValue(map['positivatedClients']),
      progressPercent: doubleValue(map['progressPercent']),
      segments: mapList(map['segments']).map(DashboardSegment.fromMap).toList(),
    );
  }
}

class DashboardSegment {
  const DashboardSegment({
    required this.key,
    required this.label,
    required this.count,
    required this.percent,
  });

  final String key;
  final String label;
  final int count;
  final double percent;

  factory DashboardSegment.fromMap(Map<String, dynamic> map) {
    return DashboardSegment(
      key: stringValue(map['key']),
      label: stringValue(map['label']),
      count: intValue(map['count']),
      percent: doubleValue(map['percent']),
    );
  }
}

class DashboardPreferences {
  const DashboardPreferences({required this.visibleIndicators});

  final List<String> visibleIndicators;

  factory DashboardPreferences.fromMap(Map<String, dynamic> map) {
    return DashboardPreferences(
      visibleIndicators: stringList(map['visibleIndicators']),
    );
  }
}

class DashboardReportCatalog {
  const DashboardReportCatalog({
    required this.categories,
    required this.savedReports,
  });

  final List<DashboardReportCategory> categories;
  final List<DashboardSavedReport> savedReports;

  List<DashboardReportDefinition> get allReports =>
      categories.expand((category) => category.reports).toList();

  factory DashboardReportCatalog.fromMap(Map<String, dynamic> map) {
    return DashboardReportCatalog(
      categories: mapList(map['categories'])
          .map(DashboardReportCategory.fromMap)
          .toList(),
      savedReports: mapList(map['savedReports'])
          .map(DashboardSavedReport.fromMap)
          .toList(),
    );
  }
}

class DashboardReportCategory {
  const DashboardReportCategory({
    required this.key,
    required this.label,
    required this.reports,
  });

  final String key;
  final String label;
  final List<DashboardReportDefinition> reports;

  factory DashboardReportCategory.fromMap(Map<String, dynamic> map) {
    return DashboardReportCategory(
      key: stringValue(map['key']),
      label: stringValue(map['label']),
      reports: mapList(map['reports'])
          .map(DashboardReportDefinition.fromMap)
          .toList(),
    );
  }
}

class DashboardReportDefinition {
  const DashboardReportDefinition({
    required this.key,
    required this.label,
    required this.isNew,
    required this.allowedFormats,
    required this.allowedFilters,
  });

  final String key;
  final String label;
  final bool isNew;
  final List<String> allowedFormats;
  final List<String> allowedFilters;

  factory DashboardReportDefinition.fromMap(Map<String, dynamic> map) {
    return DashboardReportDefinition(
      key: stringValue(map['key']),
      label: stringValue(map['label']),
      isNew: boolValue(map['isNew']),
      allowedFormats: stringList(map['allowedFormats']),
      allowedFilters: stringList(map['allowedFilters']),
    );
  }
}

class DashboardSavedReport {
  const DashboardSavedReport({
    required this.id,
    required this.name,
    required this.reportKey,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String reportKey;
  final DateTime? updatedAt;

  factory DashboardSavedReport.fromMap(Map<String, dynamic> map) {
    return DashboardSavedReport(
      id: stringValue(map['id']),
      name: stringValue(map['name']),
      reportKey: stringValue(map['reportKey']),
      updatedAt: DateTime.tryParse(stringValue(map['updatedAt'])),
    );
  }
}

class DashboardReportResult {
  const DashboardReportResult({
    required this.key,
    required this.title,
    required this.generatedAt,
    required this.columns,
    required this.rows,
    required this.totals,
    required this.pagination,
  });

  final String key;
  final String title;
  final DateTime? generatedAt;
  final List<DashboardReportColumn> columns;
  final List<Map<String, dynamic>> rows;
  final Map<String, dynamic> totals;
  final DashboardPagination pagination;

  factory DashboardReportResult.fromMap(Map<String, dynamic> map) {
    final report = mapValue(map, 'report');
    return DashboardReportResult(
      key: stringValue(report['key']),
      title: stringValue(report['title']),
      generatedAt: DateTime.tryParse(stringValue(report['generatedAt'])),
      columns: mapList(map['columns'])
          .map(DashboardReportColumn.fromMap)
          .toList(),
      rows: mapList(map['rows']),
      totals: mapValue(map, 'totals'),
      pagination: DashboardPagination.fromMap(mapValue(map, 'pagination')),
    );
  }
}

class DashboardReportColumn {
  const DashboardReportColumn({
    required this.key,
    required this.label,
    required this.type,
    required this.sortable,
  });

  final String key;
  final String label;
  final String type;
  final bool sortable;

  factory DashboardReportColumn.fromMap(Map<String, dynamic> map) {
    return DashboardReportColumn(
      key: stringValue(map['key']),
      label: stringValue(map['label']),
      type: stringValue(map['type'], fallback: 'string'),
      sortable: boolValue(map['sortable']),
    );
  }
}

class DashboardPagination {
  const DashboardPagination({
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

  factory DashboardPagination.fromMap(Map<String, dynamic> map) {
    return DashboardPagination(
      page: intValue(map['page'], fallback: 1),
      pageSize: intValue(map['pageSize'], fallback: 50),
      totalItems: intValue(map['totalItems']),
      totalPages: intValue(map['totalPages']),
      hasNextPage: boolValue(map['hasNextPage']),
    );
  }
}

class DashboardExport {
  const DashboardExport({
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

  factory DashboardExport.fromMap(Map<String, dynamic> map) {
    return DashboardExport(
      id: stringValue(map['exportId']),
      status: stringValue(map['status'], fallback: 'queued'),
      progressPercent: nullableDouble(map['progressPercent']),
      fileName: nullableString(map['fileName']),
      downloadUrl: nullableString(map['downloadUrl']),
      expiresAt: DateTime.tryParse(stringValue(map['expiresAt'])),
    );
  }
}

Map<String, dynamic> mapValue(Map<String, dynamic> map, String key) {
  final value = map[key];
  return value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
}

List<Map<String, dynamic>> mapList(dynamic value) {
  if (value is! List) return <Map<String, dynamic>>[];
  return value
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList();
}

List<String> stringList(dynamic value) {
  if (value is! List) return <String>[];
  return value.map((item) => item.toString()).toList();
}

String stringValue(dynamic value, {String fallback = ''}) {
  final result = value?.toString() ?? '';
  return result.isEmpty ? fallback : result;
}

String? nullableString(dynamic value) {
  final result = value?.toString();
  return result == null || result.isEmpty ? null : result;
}

double doubleValue(dynamic value, {double fallback = 0}) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}

double? nullableDouble(dynamic value) {
  if (value == null) return null;
  return doubleValue(value);
}

int intValue(dynamic value, {int fallback = 0}) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

bool boolValue(dynamic value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value?.toString().toLowerCase() == 'true') return true;
  if (value?.toString().toLowerCase() == 'false') return false;
  return fallback;
}

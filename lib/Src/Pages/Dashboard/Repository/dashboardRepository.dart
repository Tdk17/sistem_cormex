import 'package:sistem_cormex/Src/Connection/endpoints.dart';
import 'package:sistem_cormex/Src/Connection/httpManager.dart';
import 'package:sistem_cormex/Src/Models/dashboardModels.dart';

abstract interface class DashboardRepository {
  Future<DashboardOverview> getOverview({
    required String sessionToken,
    required String period,
    String? sellerId,
  });

  Future<DashboardReportCatalog> getReportCatalog({
    required String sessionToken,
  });

  Future<DashboardReportResult> runReport({
    required String sessionToken,
    required String reportKey,
    required Map<String, dynamic> filters,
    required int page,
    required int pageSize,
    Map<String, dynamic>? sort,
  });

  Future<DashboardExport> requestExport({
    required String sessionToken,
    required String reportKey,
    required String format,
    required Map<String, dynamic> filters,
  });

  Future<DashboardExport> getExportStatus({
    required String sessionToken,
    required String exportId,
  });

  Future<List<String>> savePreferences({
    required String sessionToken,
    required List<String> visibleIndicators,
  });

  Future<DashboardSavedReport> saveReport({
    required String sessionToken,
    String? savedReportId,
    required String name,
    required String reportKey,
    required Map<String, dynamic> filters,
    required List<String> visibleColumns,
  });

  Future<void> deleteSavedReport({
    required String sessionToken,
    required String savedReportId,
  });
}

class ParseDashboardRepository implements DashboardRepository {
  const ParseDashboardRepository(this._httpManager);

  final HttpManager _httpManager;

  @override
  Future<DashboardOverview> getOverview({
    required String sessionToken,
    required String period,
    String? sellerId,
  }) async {
    final response = await _post(
      Endpoints.dashboardOverview,
      sessionToken,
      {
        'period': period,
        'sellerId': sellerId,
      },
    );
    return DashboardOverview.fromMap(response);
  }

  @override
  Future<DashboardReportCatalog> getReportCatalog({
    required String sessionToken,
  }) async {
    final response = await _post(
      Endpoints.dashboardReportCatalog,
      sessionToken,
      const {},
    );
    return DashboardReportCatalog.fromMap(response);
  }

  @override
  Future<DashboardReportResult> runReport({
    required String sessionToken,
    required String reportKey,
    required Map<String, dynamic> filters,
    required int page,
    required int pageSize,
    Map<String, dynamic>? sort,
  }) async {
    final response = await _post(
      Endpoints.dashboardRunReport,
      sessionToken,
      {
        'reportKey': reportKey,
        'filters': filters,
        'page': page,
        'pageSize': pageSize,
        if (sort != null) 'sort': sort,
      },
    );
    return DashboardReportResult.fromMap(response);
  }

  @override
  Future<DashboardExport> requestExport({
    required String sessionToken,
    required String reportKey,
    required String format,
    required Map<String, dynamic> filters,
  }) async {
    final response = await _post(
      Endpoints.dashboardExportReport,
      sessionToken,
      {
        'reportKey': reportKey,
        'format': format,
        'filters': filters,
      },
    );
    return DashboardExport.fromMap(response);
  }

  @override
  Future<DashboardExport> getExportStatus({
    required String sessionToken,
    required String exportId,
  }) async {
    final response = await _post(
      Endpoints.dashboardExportStatus,
      sessionToken,
      {'exportId': exportId},
    );
    return DashboardExport.fromMap(response);
  }

  @override
  Future<List<String>> savePreferences({
    required String sessionToken,
    required List<String> visibleIndicators,
  }) async {
    final response = await _post(
      Endpoints.dashboardSavePreferences,
      sessionToken,
      {'visibleIndicators': visibleIndicators},
    );
    return stringList(response['visibleIndicators']);
  }

  @override
  Future<DashboardSavedReport> saveReport({
    required String sessionToken,
    String? savedReportId,
    required String name,
    required String reportKey,
    required Map<String, dynamic> filters,
    required List<String> visibleColumns,
  }) async {
    final response = await _post(
      Endpoints.dashboardSaveReport,
      sessionToken,
      {
        if (savedReportId != null) 'savedReportId': savedReportId,
        'name': name,
        'reportKey': reportKey,
        'filters': filters,
        'visibleColumns': visibleColumns,
      },
    );
    return DashboardSavedReport.fromMap(response);
  }

  @override
  Future<void> deleteSavedReport({
    required String sessionToken,
    required String savedReportId,
  }) async {
    await _post(
      Endpoints.dashboardDeleteSavedReport,
      sessionToken,
      {'savedReportId': savedReportId},
    );
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
    return _cloudResult(response);
  }

  Map<String, dynamic> _cloudResult(Map<String, dynamic> response) {
    final result = response['result'];
    if (result is Map) return Map<String, dynamic>.from(result);

    throw const FormatException(
      'O servidor retornou uma resposta inválida para o Dashboard.',
    );
  }
}

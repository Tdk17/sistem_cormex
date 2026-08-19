import 'package:signals/signals.dart';
import 'package:sistem_cormex/Src/Connection/apiException.dart';
import 'package:sistem_cormex/Src/Models/dashboardModels.dart';
import 'package:sistem_cormex/Src/Pages/Auth/Controller/authController.dart';
import 'package:sistem_cormex/Src/Pages/Dashboard/Repository/dashboardRepository.dart';

class DashboardController {
  DashboardController(this._repository, this._authController)
      : selectedPeriod = signal(_currentPeriod());

  final DashboardRepository _repository;
  final AuthController _authController;
  String? _dataSessionToken;
  int _overviewRequestId = 0;
  int _catalogRequestId = 0;

  final isLoading = signal(false);
  final errorMessage = signal<String?>(null);
  final overview = signal<DashboardOverview?>(null);
  final Signal<String> selectedPeriod;
  final selectedSellerId = signal<String?>(null);
  final visibleIndicators = signal<List<String>>([]);
  final bannerVisible = signal(true);

  final catalogLoading = signal(false);
  final catalogError = signal<String?>(null);
  final reportCatalog = signal<DashboardReportCatalog?>(null);

  final reportLoading = signal(false);
  final reportError = signal<String?>(null);
  final reportResult = signal<DashboardReportResult?>(null);
  final activeReport = signal<DashboardReportDefinition?>(null);
  final reportSortField = signal<String?>(null);
  final reportSortAscending = signal(false);

  final exportLoading = signal(false);
  final exportState = signal<DashboardExport?>(null);
  final preferencesSaving = signal(false);

  Future<void> initialize({required bool includeReports}) async {
    _synchronizeSession();
    final futures = <Future<void>>[];
    if (overview.value == null) futures.add(loadOverview());
    if (includeReports && reportCatalog.value == null) {
      futures.add(loadReportCatalog());
    }
    await Future.wait(futures);
  }

  Future<void> refreshCurrentSection({required bool reports}) async {
    if (reports) {
      await loadReportCatalog(force: true);
    } else {
      await loadOverview(force: true);
    }
  }

  Future<void> loadOverview({bool force = false}) async {
    if ((isLoading.value && !force) || (!force && overview.value != null)) {
      return;
    }
    final requestId = ++_overviewRequestId;

    batch(() {
      isLoading.value = true;
      errorMessage.value = null;
    });
    try {
      final data = await _repository.getOverview(
        sessionToken: _sessionToken,
        period: selectedPeriod.value,
        sellerId: selectedSellerId.value,
      );
      if (requestId != _overviewRequestId) return;
      batch(() {
        overview.value = data;
        if (data.selectedPeriod.isNotEmpty) {
          selectedPeriod.value = data.selectedPeriod;
        }
        selectedSellerId.value = data.selectedSellerId;
        visibleIndicators.value = data.preferences.visibleIndicators;
      });
    } catch (error) {
      if (requestId == _overviewRequestId) {
        errorMessage.value = _messageFor(error);
      }
    } finally {
      if (requestId == _overviewRequestId) isLoading.value = false;
    }
  }

  Future<void> changePeriod(String period) async {
    if (period == selectedPeriod.value) return;
    selectedPeriod.value = period;
    await loadOverview(force: true);
  }

  Future<void> changeSeller(String? sellerId) async {
    if (sellerId == selectedSellerId.value) return;
    selectedSellerId.value = sellerId;
    await loadOverview(force: true);
  }

  Future<void> loadReportCatalog({bool force = false}) async {
    if ((catalogLoading.value && !force) ||
        (!force && reportCatalog.value != null)) {
      return;
    }
    final requestId = ++_catalogRequestId;

    batch(() {
      catalogLoading.value = true;
      catalogError.value = null;
    });
    try {
      final catalog = await _repository.getReportCatalog(
        sessionToken: _sessionToken,
      );
      if (requestId == _catalogRequestId) reportCatalog.value = catalog;
    } catch (error) {
      if (requestId == _catalogRequestId) {
        catalogError.value = _messageFor(error);
      }
    } finally {
      if (requestId == _catalogRequestId) catalogLoading.value = false;
    }
  }

  Future<bool> runReport(
    DashboardReportDefinition report, {
    int page = 1,
  }) async {
    if (reportLoading.value) return false;
    final changingReport = activeReport.value?.key != report.key;

    batch(() {
      activeReport.value = report;
      reportLoading.value = true;
      reportError.value = null;
      exportState.value = null;
      if (changingReport) {
        reportResult.value = null;
        reportSortField.value = null;
        reportSortAscending.value = false;
      }
    });
    try {
      reportResult.value = await _repository.runReport(
        sessionToken: _sessionToken,
        reportKey: report.key,
        filters: currentReportFilters,
        page: page,
        pageSize: 50,
        sort: reportSortField.value == null
            ? null
            : {
                'field': reportSortField.value,
                'direction': reportSortAscending.value ? 'asc' : 'desc',
              },
      );
      return true;
    } catch (error) {
      reportError.value = _messageFor(error);
      return false;
    } finally {
      reportLoading.value = false;
    }
  }

  Future<void> sortReport(String field) async {
    final report = activeReport.value;
    if (report == null || reportLoading.value) return;
    if (reportSortField.value == field) {
      reportSortAscending.value = !reportSortAscending.value;
    } else {
      reportSortField.value = field;
      reportSortAscending.value = true;
    }
    await runReport(report);
  }

  Future<void> requestExport(String format) async {
    final report = activeReport.value;
    if (report == null || exportLoading.value) return;

    batch(() {
      exportLoading.value = true;
      reportError.value = null;
      exportState.value = null;
    });
    try {
      var state = await _repository.requestExport(
        sessionToken: _sessionToken,
        reportKey: report.key,
        format: format,
        filters: currentReportFilters,
      );
      exportState.value = state;

      for (var attempt = 0; attempt < 15 && !state.isFinished; attempt++) {
        await Future<void>.delayed(const Duration(seconds: 2));
        state = await _repository.getExportStatus(
          sessionToken: _sessionToken,
          exportId: state.id,
        );
        exportState.value = state;
      }
    } catch (error) {
      reportError.value = _messageFor(error);
    } finally {
      exportLoading.value = false;
    }
  }

  Future<bool> savePreferences(List<String> indicators) async {
    if (preferencesSaving.value) return false;
    preferencesSaving.value = true;
    errorMessage.value = null;
    try {
      visibleIndicators.value = await _repository.savePreferences(
        sessionToken: _sessionToken,
        visibleIndicators: indicators,
      );
      return true;
    } catch (error) {
      errorMessage.value = _messageFor(error);
      return false;
    } finally {
      preferencesSaving.value = false;
    }
  }

  Future<bool> saveReport({
    required String name,
    required DashboardReportDefinition report,
  }) async {
    catalogError.value = null;
    try {
      await _repository.saveReport(
        sessionToken: _sessionToken,
        name: name,
        reportKey: report.key,
        filters: currentReportFilters,
        visibleColumns:
            reportResult.value?.columns.map((column) => column.key).toList() ??
                const [],
      );
      await loadReportCatalog(force: true);
      return true;
    } catch (error) {
      catalogError.value = _messageFor(error);
      return false;
    }
  }

  Future<bool> deleteSavedReport(String id) async {
    catalogError.value = null;
    try {
      await _repository.deleteSavedReport(
        sessionToken: _sessionToken,
        savedReportId: id,
      );
      await loadReportCatalog(force: true);
      return true;
    } catch (error) {
      catalogError.value = _messageFor(error);
      return false;
    }
  }

  Map<String, dynamic> get currentReportFilters {
    final parts = selectedPeriod.value.split('-');
    final year = int.tryParse(parts.first) ?? DateTime.now().year;
    final month = parts.length > 1
        ? int.tryParse(parts[1]) ?? DateTime.now().month
        : DateTime.now().month;
    final lastDay = DateTime(year, month + 1, 0).day;
    final monthText = month.toString().padLeft(2, '0');
    final seller = selectedSellerId.value;
    return {
      'dateFrom': '$year-$monthText-01',
      'dateTo': '$year-$monthText-${lastDay.toString().padLeft(2, '0')}',
      'sellerIds': seller == null ? <String>[] : [seller],
    };
  }

  void closeBanner() => bannerVisible.value = false;

  void _synchronizeSession() {
    final currentToken = _authController.sessionToken.value;
    if (_dataSessionToken == currentToken) return;
    _dataSessionToken = currentToken;
    _overviewRequestId++;
    _catalogRequestId++;
    batch(() {
      isLoading.value = false;
      overview.value = null;
      errorMessage.value = null;
      selectedPeriod.value = _currentPeriod();
      selectedSellerId.value = null;
      visibleIndicators.value = [];
      bannerVisible.value = true;
      reportCatalog.value = null;
      catalogLoading.value = false;
      catalogError.value = null;
      activeReport.value = null;
      reportLoading.value = false;
      reportResult.value = null;
      reportError.value = null;
      reportSortField.value = null;
      reportSortAscending.value = false;
      exportState.value = null;
      exportLoading.value = false;
      preferencesSaving.value = false;
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
        case 9100:
          return 'Você não possui acesso a estes indicadores.';
        case 9101:
          return 'O período selecionado é inválido.';
        case 9102:
          return 'Um dos filtros informados é inválido.';
        case 9103:
          return 'Relatório não encontrado ou não permitido.';
        case 9104:
          return 'Os parâmetros do relatório são inválidos.';
        case 9105:
          return 'Exportação não encontrada.';
        case 9106:
          return 'Não foi possível salvar os indicadores.';
        case 9107:
          return 'Relatório salvo não encontrado.';
        case 9108:
          return 'Aguarde antes de solicitar outra exportação.';
        default:
          return error.message;
      }
    }
    if (error is FormatException) return error.message.toString();
    return 'Não foi possível carregar os dados do Dashboard.';
  }

  static String _currentPeriod() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }
}

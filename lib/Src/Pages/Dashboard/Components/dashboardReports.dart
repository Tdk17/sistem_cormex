import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';
import 'package:sistem_cormex/Src/Config/appColors.dart';
import 'package:sistem_cormex/Src/Models/dashboardModels.dart';
import 'package:sistem_cormex/Src/Pages/Dashboard/Components/dashboardCommon.dart';
import 'package:sistem_cormex/Src/Pages/Dashboard/Components/dashboardFormatters.dart';
import 'package:sistem_cormex/Src/Pages/Dashboard/Controller/dashboardController.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

class DashboardReports extends StatefulWidget {
  const DashboardReports({super.key, required this.controller});

  final DashboardController controller;

  @override
  State<DashboardReports> createState() => _DashboardReportsState();
}

class _DashboardReportsState extends State<DashboardReports> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final loading = widget.controller.catalogLoading.value;
      final error = widget.controller.catalogError.value;
      final catalog = widget.controller.reportCatalog.value;

      if (loading && catalog == null) return const _CatalogLoading();
      if (catalog == null) {
        return _CatalogMessage(
          icon: Icons.cloud_off_outlined,
          title: 'Não foi possível carregar os relatórios',
          message: error ?? 'A API não retornou o catálogo de relatórios.',
          onRetry: () => widget.controller.loadReportCatalog(force: true),
        );
      }

      final query = _query.trim().toLowerCase();
      final categories = catalog.categories
          .map(
            (category) => DashboardReportCategory(
              key: category.key,
              label: category.label,
              reports: category.reports
                  .where(
                    (report) => query.isEmpty ||
                        report.label.toLowerCase().contains(query),
                  )
                  .toList(),
            ),
          )
          .where((category) => category.reports.isNotEmpty)
          .toList();
      final savedReports = catalog.savedReports
          .where(
            (report) =>
                query.isEmpty || report.name.toLowerCase().contains(query),
          )
          .toList();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (error != null) ...[
            _InlineCatalogError(
              message: error,
              onRetry: () => widget.controller.loadReportCatalog(force: true),
            ),
            const SizedBox(height: 14),
          ],
          DashboardCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _query = value),
                    decoration: const InputDecoration(
                      hintText: 'Encontre um relatório por nome',
                      hintStyle: TextStyle(fontSize: 13),
                      prefixIcon: Icon(Icons.search_rounded),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                    ),
                  ),
                ),
                if (_query.isNotEmpty)
                  IconButton(
                    tooltip: 'Limpar busca',
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
                IconButton(
                  tooltip: 'Atualizar catálogo',
                  onPressed: loading
                      ? null
                      : () => widget.controller.loadReportCatalog(force: true),
                  icon: loading
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (categories.isEmpty && savedReports.isEmpty)
            const _CatalogMessage(
              icon: Icons.search_off_rounded,
              title: 'Nenhum relatório encontrado',
              message: 'Tente buscar usando outro nome.',
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final cards = <Widget>[
                  for (final category in categories)
                    _ReportGroupCard(
                      category: category,
                      onOpen: (report) => _openReport(
                        context,
                        widget.controller,
                        report,
                      ),
                    ),
                  if (savedReports.isNotEmpty)
                    _SavedReportsCard(
                      reports: savedReports,
                      catalog: catalog,
                      controller: widget.controller,
                    ),
                ];
                if (constraints.maxWidth < 820) {
                  return Column(
                    children: [
                      for (final card in cards) ...[
                        card,
                        const SizedBox(height: 16),
                      ],
                    ],
                  );
                }
                final left = <Widget>[];
                final right = <Widget>[];
                for (var index = 0; index < cards.length; index++) {
                  (index.isEven ? left : right).add(cards[index]);
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _CardColumn(children: left)),
                    const SizedBox(width: 16),
                    Expanded(child: _CardColumn(children: right)),
                  ],
                );
              },
            ),
        ],
      );
    });
  }
}

Future<void> showCreateDashboardReportDialog(
  BuildContext context,
  DashboardController controller,
) async {
  if (controller.catalogLoading.value) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('O catálogo ainda está carregando.')),
    );
    return;
  }
  if (controller.reportCatalog.value == null) {
    await controller.loadReportCatalog();
  }
  if (!context.mounted) return;
  final catalog = controller.reportCatalog.value;
  if (catalog == null || catalog.allReports.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          controller.catalogError.value ?? 'Nenhum relatório está disponível.',
        ),
      ),
    );
    return;
  }

  final report = await showDialog<DashboardReportDefinition>(
    context: context,
    builder: (dialogContext) => SimpleDialog(
      title: const Text('Escolha um relatório'),
      children: [
        for (final category in catalog.categories) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 4),
            child: Text(
              category.label.toUpperCase(),
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: .5,
              ),
            ),
          ),
          for (final item in category.reports)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(dialogContext, item),
              child: Text(item.label),
            ),
        ],
      ],
    ),
  );
  if (report != null && context.mounted) {
    _openReport(context, controller, report);
  }
}

void _openReport(
  BuildContext context,
  DashboardController controller,
  DashboardReportDefinition report,
) {
  controller.runReport(report);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _ReportViewer(controller: controller),
  );
}

class _CardColumn extends StatelessWidget {
  const _CardColumn({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final child in children) ...[
          child,
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class _ReportGroupCard extends StatelessWidget {
  const _ReportGroupCard({required this.category, required this.onOpen});

  final DashboardReportCategory category;
  final ValueChanged<DashboardReportDefinition> onOpen;

  @override
  Widget build(BuildContext context) {
    final color = _categoryColor(category.key);
    return DashboardCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _GroupHeading(
            label: category.label,
            icon: _categoryIcon(category.key),
            color: color,
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 7),
          for (final report in category.reports)
            InkWell(
              onTap: () => onOpen(report),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                child: Row(
                  children: [
                    Icon(Icons.description_outlined, size: 17, color: color),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        report.label,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (report.isNew) const _NewBadge(),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.muted,
                      size: 19,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SavedReportsCard extends StatelessWidget {
  const _SavedReportsCard({
    required this.reports,
    required this.catalog,
    required this.controller,
  });

  final List<DashboardSavedReport> reports;
  final DashboardReportCatalog catalog;
  final DashboardController controller;

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          const _GroupHeading(
            label: 'Relatórios salvos',
            icon: Icons.bookmark_outline_rounded,
            color: AppColors.navy,
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 7),
          for (final saved in reports)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        final matches = catalog.allReports
                            .where((item) => item.key == saved.reportKey)
                            .toList();
                        if (matches.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'O relatório original não está mais disponível.',
                              ),
                            ),
                          );
                          return;
                        }
                        _openReport(context, controller, matches.first);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.bookmark_rounded,
                              size: 17,
                              color: AppColors.navy,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                saved.name,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Excluir relatório salvo',
                    icon: const Icon(Icons.delete_outline_rounded, size: 19),
                    onPressed: () => _confirmDeleteSaved(
                      context,
                      controller,
                      saved,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _GroupHeading extends StatelessWidget {
  const _GroupHeading({
    required this.label,
    required this.icon,
    required this.color,
  });
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 39,
          height: 39,
          decoration: BoxDecoration(
            color: color.withOpacity(.11),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _NewBadge extends StatelessWidget {
  const _NewBadge();
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.lime.withOpacity(.25),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'NOVO',
        style: TextStyle(
          color: AppColors.navy,
          fontSize: 8,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ReportViewer extends StatelessWidget {
  const _ReportViewer({required this.controller});
  final DashboardController controller;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Dialog(
      insetPadding: const EdgeInsets.all(18),
      child: SizedBox(
        width: size.width > 1240 ? 1200 : size.width - 36,
        height: size.height > 800 ? 740 : size.height - 36,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 10, 10),
              child: Row(
                children: [
                  const Icon(Icons.analytics_outlined, color: AppColors.cyan),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Watch(
                      (context) => Text(
                        controller.activeReport.value?.label ?? 'Relatório',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Fechar',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: Watch((context) {
                final loading = controller.reportLoading.value;
                final error = controller.reportError.value;
                final result = controller.reportResult.value;
                if (loading && result == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (error != null && result == null) {
                  return _CatalogMessage(
                    icon: Icons.error_outline_rounded,
                    title: 'Não foi possível gerar o relatório',
                    message: error,
                    onRetry: () {
                      final report = controller.activeReport.value;
                      if (report != null) controller.runReport(report);
                    },
                  );
                }
                if (result == null) {
                  return const _CatalogMessage(
                    icon: Icons.description_outlined,
                    title: 'Aguardando dados',
                    message: 'O relatório ainda não retornou informações.',
                  );
                }
                return _ReportResultView(
                  controller: controller,
                  result: result,
                  loading: loading,
                  error: error,
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportResultView extends StatelessWidget {
  const _ReportResultView({
    required this.controller,
    required this.result,
    required this.loading,
    required this.error,
  });
  final DashboardController controller;
  final DashboardReportResult result;
  final bool loading;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final active = controller.activeReport.value;
    final sortIndex = result.columns.indexWhere(
      (column) => column.key == controller.reportSortField.value,
    );
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(14),
          child: Wrap(
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 8,
            children: [
              Text(
                '${result.pagination.totalItems} registros',
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              if (active != null)
                OutlinedButton.icon(
                  onPressed: () => _showSaveReportDialog(
                    context,
                    controller,
                    active,
                  ),
                  icon: const Icon(Icons.bookmark_add_outlined, size: 18),
                  label: const Text('Salvar visão'),
                ),
              if (active != null && active.allowedFormats.isNotEmpty)
                PopupMenuButton<String>(
                  onSelected: controller.requestExport,
                  itemBuilder: (_) => [
                    for (final format in active.allowedFormats)
                      PopupMenuItem(
                        value: format,
                        child: Text('Exportar ${format.toUpperCase()}'),
                      ),
                  ],
                  child: const _FilledButtonVisual(
                    icon: Icons.download_rounded,
                    label: 'Exportar',
                  ),
                ),
            ],
          ),
        ),
        if (loading) const LinearProgressIndicator(minHeight: 2),
        if (error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: _InlineCatalogError(
              message: error!,
              onRetry: () {
                if (active != null) {
                  controller.runReport(
                    active,
                    page: result.pagination.page,
                  );
                }
              },
            ),
          ),
        _ExportStatus(controller: controller),
        Expanded(
          child: result.rows.isEmpty || result.columns.isEmpty
              ? const Center(
                  child: Text('Nenhum dado encontrado com estes filtros.'),
                )
              : Scrollbar(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: DataTable(
                        headingRowColor:
                            MaterialStateProperty.all(AppColors.field),
                        sortColumnIndex: sortIndex < 0 ? null : sortIndex,
                        sortAscending: controller.reportSortAscending.value,
                        columns: [
                          for (final column in result.columns)
                            DataColumn(
                              label: Text(column.label),
                              onSort: column.sortable
                                  ? (_, __) => controller.sortReport(column.key)
                                  : null,
                            ),
                        ],
                        rows: [
                          for (final row in result.rows)
                            DataRow(
                              cells: [
                                for (final column in result.columns)
                                  DataCell(
                                    Text(
                                      formatReportValue(
                                        row[column.key],
                                        column.type,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          if (result.totals.isNotEmpty)
                            DataRow(
                              color: MaterialStateProperty.all(AppColors.canvas),
                              cells: [
                                for (var index = 0;
                                    index < result.columns.length;
                                    index++)
                                  DataCell(
                                    Text(
                                      index == 0
                                          ? 'TOTAIS'
                                          : formatReportValue(
                                              result.totals[
                                                  result.columns[index].key],
                                              result.columns[index].type,
                                            ),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Página ${result.pagination.page} de ${result.pagination.totalPages < 1 ? 1 : result.pagination.totalPages}',
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              const SizedBox(width: 12),
              IconButton.outlined(
                tooltip: 'Página anterior',
                onPressed: loading ||
                        active == null ||
                        result.pagination.page <= 1
                    ? null
                    : () => controller.runReport(
                          active,
                          page: result.pagination.page - 1,
                        ),
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              const SizedBox(width: 6),
              IconButton.outlined(
                tooltip: 'Próxima página',
                onPressed: loading ||
                        active == null ||
                        !result.pagination.hasNextPage
                    ? null
                    : () => controller.runReport(
                          active,
                          page: result.pagination.page + 1,
                        ),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FilledButtonVisual extends StatelessWidget {
  const _FilledButtonVisual({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: FilledButton.icon(
        onPressed: () {},
        icon: Icon(icon, size: 18),
        label: Text(label),
      ),
    );
  }
}

class _ExportStatus extends StatelessWidget {
  const _ExportStatus({required this.controller});
  final DashboardController controller;

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final loading = controller.exportLoading.value;
      final state = controller.exportState.value;
      if (!loading && state == null) return const SizedBox.shrink();

      final ready = state?.status == 'ready' && state?.downloadUrl != null;
      final failed = state?.status == 'failed' || state?.status == 'expired';
      return Container(
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.canvas,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            if (loading)
              const SizedBox.square(
                dimension: 17,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(
                failed ? Icons.error_outline_rounded : Icons.task_alt_rounded,
                color: failed ? AppColors.danger : const Color(0xFF38B87C),
                size: 19,
              ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                failed
                    ? 'A exportação não foi concluída.'
                    : ready
                        ? state?.fileName ?? 'Arquivo pronto para download.'
                        : 'Preparando exportação${state?.progressPercent == null ? '…' : ' · ${formatPercent(state!.progressPercent)}'}',
                style: const TextStyle(fontSize: 12),
              ),
            ),
            if (ready)
              TextButton.icon(
                onPressed: () => _downloadExport(context, state!.downloadUrl!),
                icon: const Icon(Icons.open_in_new_rounded, size: 16),
                label: const Text('Baixar'),
              ),
          ],
        ),
      );
    });
  }
}

Future<void> _downloadExport(BuildContext context, String url) async {
  final uri = Uri.tryParse(url);
  final launched = uri != null &&
      await url_launcher.launchUrl(
        uri,
        mode: url_launcher.LaunchMode.externalApplication,
      );
  if (!launched && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Não foi possível abrir o arquivo.')),
    );
  }
}

Future<void> _showSaveReportDialog(
  BuildContext context,
  DashboardController controller,
  DashboardReportDefinition report,
) async {
  final nameController = TextEditingController(text: report.label);
  final name = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Salvar visão do relatório'),
      content: TextField(
        controller: nameController,
        autofocus: true,
        maxLength: 80,
        decoration: const InputDecoration(labelText: 'Nome'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            final value = nameController.text.trim();
            if (value.length >= 3) Navigator.pop(dialogContext, value);
          },
          child: const Text('Salvar'),
        ),
      ],
    ),
  );
  nameController.dispose();
  if (name == null) return;
  final success = await controller.saveReport(name: name, report: report);
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Relatório salvo com sucesso.'
              : controller.catalogError.value ?? 'Não foi possível salvar.',
        ),
      ),
    );
  }
}

Future<void> _confirmDeleteSaved(
  BuildContext context,
  DashboardController controller,
  DashboardSavedReport report,
) async {
  final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Excluir relatório salvo?'),
          content: Text('A visão “${report.name}” será removida.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Excluir'),
            ),
          ],
        ),
      ) ??
      false;
  if (!confirmed) return;
  final success = await controller.deleteSavedReport(report.id);
  if (context.mounted && !success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          controller.catalogError.value ?? 'Não foi possível excluir.',
        ),
      ),
    );
  }
}

class _CatalogLoading extends StatelessWidget {
  const _CatalogLoading();
  @override
  Widget build(BuildContext context) {
    return const DashboardCard(
      child: SizedBox(
        height: 280,
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _CatalogMessage extends StatelessWidget {
  const _CatalogMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.onRetry,
  });
  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: AppColors.muted),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 14),
              FilledButton(
                onPressed: onRetry,
                child: const Text('Tentar novamente'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InlineCatalogError extends StatelessWidget {
  const _InlineCatalogError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.danger.withOpacity(.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.danger),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
          TextButton(onPressed: onRetry, child: const Text('Tentar novamente')),
        ],
      ),
    );
  }
}

Color _categoryColor(String key) {
  switch (key) {
    case 'sales':
      return AppColors.cyan;
    case 'clients':
      return const Color(0xFF7459D9);
    case 'products':
      return const Color(0xFFFFA928);
    case 'billing':
      return const Color(0xFF38B87C);
    case 'commissions':
      return const Color(0xFFE56F72);
    default:
      return AppColors.navy;
  }
}

IconData _categoryIcon(String key) {
  switch (key) {
    case 'sales':
      return Icons.trending_up_rounded;
    case 'clients':
      return Icons.groups_2_outlined;
    case 'products':
      return Icons.inventory_2_outlined;
    case 'billing':
      return Icons.account_balance_wallet_outlined;
    case 'commissions':
      return Icons.percent_rounded;
    default:
      return Icons.hub_outlined;
  }
}

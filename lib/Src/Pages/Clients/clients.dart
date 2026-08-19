import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals/signals_flutter.dart';
import 'package:sistem_cormex/Src/Config/appColors.dart';
import 'package:sistem_cormex/Src/Dependencies/dependencies.dart';
import 'package:sistem_cormex/Src/Models/clientModels.dart';
import 'package:sistem_cormex/Src/Pages/Clients/Controller/clientsController.dart';
import 'package:sistem_cormex/Src/Pages/Orders/Components/orderCommon.dart';
import 'package:sistem_cormex/Src/Routes/appRouter.dart';

class ClientsPage extends StatefulWidget {
  const ClientsPage({super.key});

  @override
  State<ClientsPage> createState() => _ClientsPageState();
}

class _ClientsPageState extends State<ClientsPage> {
  late final ClientsController controller;
  late final TextEditingController searchController;
  Timer? debounce;

  @override
  void initState() {
    super.initState();
    controller = getIt<ClientsController>();
    searchController = TextEditingController(text: controller.query.value);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.initializeList();
    });
  }

  @override
  void dispose() {
    debounce?.cancel();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OrdersScaffold(
      floatingActionButton: MediaQuery.sizeOf(context).width < 650
          ? Watch((context) => FloatingActionButton.extended(
                onPressed: controller.permissions.value.canCreate
                    ? () => context.go(AppRoutes.clientNew)
                    : null,
                icon: const Icon(Icons.person_add_alt_1_rounded),
                label: const Text('Cadastrar'),
              ))
          : null,
      child: Scrollbar(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 22, 18, 42),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1580),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OrdersPageHeader(
                    title: 'Clientes',
                    description: 'Cadastre, organize e acompanhe sua carteira comercial.',
                    actions: [
                      if (MediaQuery.sizeOf(context).width >= 650)
                        Watch((context) => FilledButton.icon(
                              onPressed: controller.permissions.value.canCreate
                                  ? () => context.go(AppRoutes.clientNew)
                                  : null,
                              icon: const Icon(Icons.add_rounded, size: 18),
                              label: const Text('Cadastrar cliente'),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.navy,
                              ),
                            )),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Watch((context) {
                    final permissions = controller.permissions.value;
                    return _ClientToolbar(
                      controller: controller,
                      searchController: searchController,
                      onSearchChanged: _scheduleSearch,
                      onImport: permissions.canImport ? () => _importFile(context) : null,
                    );
                  }),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final narrow = constraints.maxWidth < 1120;
                      final list = _ClientsList(controller: controller, onDelete: _delete);
                      final portfolio = _PortfolioColumn(controller: controller);
                      if (narrow) {
                        return Column(children: [portfolio, const SizedBox(height: 16), list]);
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [Expanded(flex: 7, child: list), const SizedBox(width: 16), Expanded(flex: 3, child: portfolio)],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _scheduleSearch(String value) {
    debounce?.cancel();
    debounce = Timer(const Duration(milliseconds: 450), () => controller.applySearch(value));
  }

  Future<void> _delete(BuildContext context, ClientSummary client) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir cliente?'),
        content: Text('Deseja excluir “${client.displayName}”? Clientes com pedidos serão preservados e deverão ser bloqueados.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), style: FilledButton.styleFrom(backgroundColor: AppColors.danger), child: const Text('Excluir')),
        ],
      ),
    );
    if (confirmed != true) return;
    final ok = await controller.deleteClient(client);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Cliente excluído.' : controller.listError.value ?? 'Não foi possível excluir.')));
  }

  Future<void> _importFile(BuildContext context) async {
    final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['csv', 'xlsx'],
    );
    if (picked.isEmpty) return;
    final file = picked.single;
    final bytes = await file.readAsBytes();
    if (bytes.length > 5 * 1024 * 1024) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('O arquivo deve ter no máximo 5 MB.')));
      return;
    }
    final result = await controller.importClients(fileName: file.name, base64: base64Encode(bytes));
    if (!context.mounted) return;
    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(controller.listError.value ?? 'Não foi possível importar os clientes.')));
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Importação concluída'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${result.created} clientes criados'),
            Text('${result.updated} clientes atualizados'),
            Text('${result.skipped} linhas ignoradas'),
            if (result.errors.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Ocorrências:', style: TextStyle(fontWeight: FontWeight.w800)),
              ...result.errors.take(5).map((message) => Text(message)),
            ],
          ],
        ),
        actions: [FilledButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Concluir'))],
      ),
    );
  }
}

class _ClientToolbar extends StatelessWidget {
  const _ClientToolbar({required this.controller, required this.searchController, required this.onSearchChanged, required this.onImport});
  final ClientsController controller;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback? onImport;

  @override
  Widget build(BuildContext context) {
    return OrderSurface(
      padding: const EdgeInsets.all(14),
      child: LayoutBuilder(builder: (context, constraints) {
        final search = ValueListenableBuilder<TextEditingValue>(
          valueListenable: searchController,
          builder: (context, value, _) => TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            onSubmitted: controller.applySearch,
            decoration: InputDecoration(
              hintText: 'Pesquise por nome, CPF/CNPJ, cidade ou estado',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: value.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        searchController.clear();
                        controller.applySearch('');
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
            ),
          ),
        );
        final filter = Watch((context) => DropdownButtonFormField<String>(
              value: controller.visibility.value,
              decoration: const InputDecoration(labelText: 'Exibir clientes'),
              items: const [
                DropdownMenuItem(value: 'unblocked', child: Text('Não bloqueados')),
                DropdownMenuItem(value: 'all', child: Text('Todos')),
                DropdownMenuItem(value: 'blocked', child: Text('Somente bloqueados')),
              ],
              onChanged: controller.listLoading.value ? null : (value) { if (value != null) controller.changeVisibility(value); },
            ));
        final actions = Wrap(spacing: 8, runSpacing: 8, children: [
          OutlinedButton.icon(onPressed: onImport, icon: const Icon(Icons.file_upload_outlined), label: const Text('Importar')),
          OutlinedButton.icon(
            onPressed: controller.permissions.value.canManageLinks
                ? () => context.go(AppRoutes.accountUsers)
                : null,
            icon: const Icon(Icons.rule_folder_outlined),
            label: const Text('Vínculos e permissões'),
          ),
          IconButton.outlined(onPressed: controller.loadClients, tooltip: 'Atualizar', icon: const Icon(Icons.refresh_rounded)),
        ]);
        if (constraints.maxWidth < 820) {
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [search, const SizedBox(height: 10), filter, const SizedBox(height: 10), actions]);
        }
        return Row(children: [Expanded(flex: 4, child: search), const SizedBox(width: 10), Expanded(flex: 2, child: filter), const SizedBox(width: 10), actions]);
      }),
    );
  }
}

class _ClientsList extends StatelessWidget {
  const _ClientsList({required this.controller, required this.onDelete});
  final ClientsController controller;
  final void Function(BuildContext, ClientSummary) onDelete;

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final loading = controller.listLoading.value;
      final error = controller.listError.value;
      final clients = controller.clients.value;
      final page = controller.pagination.value;
      final permissions = controller.permissions.value;
      return OrderSurface(
        padding: EdgeInsets.zero,
        child: Column(children: [
          if (loading) const LinearProgressIndicator(minHeight: 2),
          if (error != null) Padding(padding: const EdgeInsets.all(14), child: OrderInlineError(message: error, onRetry: controller.loadClients)),
          if (!loading && clients.isEmpty)
            const Padding(
              padding: EdgeInsets.all(30),
              child: Column(children: [Icon(Icons.group_off_outlined, size: 45, color: AppColors.muted), SizedBox(height: 10), Text('Nenhum cliente encontrado', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)), SizedBox(height: 4), Text('Ajuste a busca ou cadastre o primeiro cliente.', style: TextStyle(color: AppColors.muted))]),
            )
          else
            ...clients.map((client) => _ClientRow(
                  client: client,
                  canEdit: permissions.canEdit,
                  canDelete: permissions.canDelete,
                  onDelete: () => onDelete(context, client),
                )),
          if (page != null && page.totalPages > 1)
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('${page.totalItems} clientes', style: const TextStyle(color: AppColors.muted)),
                Row(children: [
                  IconButton.outlined(onPressed: loading || page.page <= 1 ? null : () => controller.loadClients(page: page.page - 1), icon: const Icon(Icons.chevron_left_rounded)),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Text('${page.page} de ${page.totalPages}', style: const TextStyle(fontWeight: FontWeight.w700))),
                  IconButton.outlined(onPressed: loading || !page.hasNextPage ? null : () => controller.loadClients(page: page.page + 1), icon: const Icon(Icons.chevron_right_rounded)),
                ]),
              ]),
            ),
        ]),
      );
    });
  }
}

class _ClientRow extends StatelessWidget {
  const _ClientRow({required this.client, required this.canEdit, required this.canDelete, required this.onDelete});
  final ClientSummary client;
  final bool canEdit;
  final bool canDelete;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: canEdit ? () => context.go(AppRoutes.clientById(client.id)) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
        child: LayoutBuilder(builder: (context, constraints) {
          final info = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Flexible(child: Text(client.displayName, style: const TextStyle(color: AppColors.navy, fontWeight: FontWeight.w900, fontSize: 14))),
              if (client.legalName != client.displayName && client.legalName.isNotEmpty) Flexible(child: Text(' · ${client.legalName}', overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted, fontSize: 12))),
              if (client.document.isNotEmpty) Text(' · ${client.document}', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
              if (client.blocked) const Padding(padding: EdgeInsets.only(left: 8), child: Chip(label: Text('Bloqueado'), visualDensity: VisualDensity.compact)),
            ]),
            const SizedBox(height: 9),
            Wrap(spacing: 18, runSpacing: 5, children: [
              if (client.phone.isNotEmpty) _ClientInfo(Icons.phone_outlined, client.phone),
              if (client.email.isNotEmpty) _ClientInfo(Icons.email_outlined, client.email),
              if (client.location.isNotEmpty) _ClientInfo(Icons.location_on_outlined, client.location),
            ]),
          ]);
          final actions = Wrap(spacing: 6, children: [
            OutlinedButton.icon(onPressed: canEdit ? () => context.go(AppRoutes.clientById(client.id)) : null, icon: const Icon(Icons.edit_outlined, size: 16), label: const Text('Alterar')),
            OutlinedButton.icon(onPressed: canDelete ? onDelete : null, style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger), icon: const Icon(Icons.delete_outline_rounded, size: 16), label: const Text('Excluir')),
          ]);
          if (constraints.maxWidth < 650) return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [info, const SizedBox(height: 12), actions]);
          return Row(children: [Expanded(child: info), actions]);
        }),
      ),
    );
  }
}

class _ClientInfo extends StatelessWidget {
  const _ClientInfo(this.icon, this.text);
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 15, color: AppColors.muted), const SizedBox(width: 5), Text(text, style: const TextStyle(color: AppColors.muted, fontSize: 12))]);
}

class _PortfolioColumn extends StatelessWidget {
  const _PortfolioColumn({required this.controller});
  final ClientsController controller;

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final data = controller.portfolio.value;
      return Column(children: [
        OrderSurface(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [Icon(Icons.donut_large_rounded, color: AppColors.cyan), SizedBox(width: 8), Text('Carteira de clientes', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15))]),
            const SizedBox(height: 20),
            Center(
              child: SizedBox(
                width: 180,
                height: 180,
                child: CustomPaint(
                  painter: _PortfolioPainter(data.segments),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${data.total}',
                          style: const TextStyle(
                            fontSize: 29,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Text(
                          'Clientes',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Wrap(spacing: 16, runSpacing: 9, children: data.segments.map((segment) => Row(mainAxisSize: MainAxisSize.min, children: [Container(width: 9, height: 9, decoration: BoxDecoration(color: _portfolioColor(segment.key), shape: BoxShape.circle)), const SizedBox(width: 6), Text('${segment.value} ${segment.label}', style: const TextStyle(fontSize: 12))])).toList()),
          ]),
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(color: AppColors.cyan.withOpacity(.09), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.cyan.withOpacity(.25))),
          child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.lightbulb_outline_rounded, color: AppColors.cyan), SizedBox(width: 10), Expanded(child: Text('Use clientes inativos recentes para criar ações de reativação e novas oportunidades de venda.'))]),
        ),
      ]);
    });
  }
}

class _PortfolioPainter extends CustomPainter {
  const _PortfolioPainter(this.segments);
  final List<ClientPortfolioSegment> segments;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(14, 14, size.width - 28, size.height - 28);
    final background = Paint()..color = AppColors.field..style = PaintingStyle.stroke..strokeWidth = 13;
    canvas.drawArc(rect, 0, math.pi * 2, false, background);
    var start = -math.pi / 2;
    for (final segment in segments) {
      final sweep = math.pi * 2 * (segment.percent / 100);
      final paint = Paint()..color = _portfolioColor(segment.key)..style = PaintingStyle.stroke..strokeWidth = 13..strokeCap = StrokeCap.butt;
      canvas.drawArc(rect, start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _PortfolioPainter oldDelegate) => oldDelegate.segments != segments;
}

Color _portfolioColor(String key) {
  switch (key) {
    case 'active': return const Color(0xFF52CE7B);
    case 'inactive_recent': return const Color(0xFFF3C84B);
    case 'inactive_old': return const Color(0xFFE66E6E);
    case 'prospect': return const Color(0xFFD9DDDA);
    default: return AppColors.cyan;
  }
}

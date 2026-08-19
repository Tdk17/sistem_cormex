import 'dart:async';

import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';
import 'package:sistem_cormex/Src/Config/appColors.dart';
import 'package:sistem_cormex/Src/Dependencies/dependencies.dart';
import 'package:sistem_cormex/Src/Models/logisticsModels.dart';
import 'package:sistem_cormex/Src/Pages/Logistics/Components/logisticsCommon.dart';
import 'package:sistem_cormex/Src/Pages/Logistics/Components/logisticsDetailsDialogs.dart';
import 'package:sistem_cormex/Src/Pages/Logistics/Components/logisticsDialogs.dart';
import 'package:sistem_cormex/Src/Pages/Logistics/Components/routeEditorSheet.dart';
import 'package:sistem_cormex/Src/Pages/Logistics/Controller/logisticsController.dart';
import 'package:sistem_cormex/Src/Pages/Orders/Components/orderCommon.dart';
import 'package:url_launcher/url_launcher.dart';

class LogisticsPage extends StatefulWidget {
  const LogisticsPage({super.key});

  @override
  State<LogisticsPage> createState() => _LogisticsPageState();
}

class _LogisticsPageState extends State<LogisticsPage> {
  late final LogisticsController controller;
  late final TextEditingController routesSearchController;
  late final TextEditingController trackingsSearchController;
  Timer? debounce;

  @override
  void initState() {
    super.initState();
    controller = getIt<LogisticsController>();
    routesSearchController = TextEditingController(
      text: controller.routesQuery.value,
    );
    trackingsSearchController = TextEditingController(
      text: controller.trackingsQuery.value,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => controller.initialize());
  }

  @override
  void dispose() {
    debounce?.cancel();
    routesSearchController.dispose();
    trackingsSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OrdersScaffold(
      floatingActionButton: MediaQuery.sizeOf(context).width < 650
          ? Watch((context) {
              final section = controller.section.value;
              final permission = section == LogisticsSection.routes
                  ? controller.permissions.canCreateRoute
                  : section == LogisticsSection.trackings
                      ? controller.permissions.canManageTrackings
                      : controller.permissions.canManageCarriers;
              return FloatingActionButton.extended(
                onPressed: permission ? () => _createFor(section) : null,
                icon: const Icon(Icons.add_rounded),
                label: Text(_createLabel(section)),
              );
            })
          : null,
      child: RefreshIndicator(
        onRefresh: controller.refreshAll,
        child: Scrollbar(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 22, 18, 42),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1580),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Watch((context) {
                      final section = controller.section.value;
                      return OrdersPageHeader(
                        title: 'Logística inteligente',
                        description: _description(section),
                        actions: [
                          OutlinedButton.icon(
                            onPressed: controller.refreshAll,
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: const Text('Atualizar'),
                          ),
                          if (MediaQuery.sizeOf(context).width >= 650)
                            FilledButton.icon(
                              onPressed: _canCreate(section)
                                  ? () => _createFor(section)
                                  : null,
                              icon: const Icon(Icons.add_rounded, size: 18),
                              label: Text(_createLabel(section)),
                            ),
                        ],
                      );
                    }),
                    const SizedBox(height: 16),
                    _LogisticsTabs(controller: controller),
                    const SizedBox(height: 14),
                    _Metrics(controller: controller),
                    const SizedBox(height: 14),
                    Watch((context) {
                      final message = controller.error.value;
                      if (message == null) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: OrderInlineError(
                          message: message,
                          onRetry: controller.refreshAll,
                        ),
                      );
                    }),
                    Watch((context) {
                      switch (controller.section.value) {
                        case LogisticsSection.routes:
                          return _RoutesSection(
                            controller: controller,
                            searchController: routesSearchController,
                            onSearch: _scheduleRouteSearch,
                            onOpen: _openRoute,
                          );
                        case LogisticsSection.trackings:
                          return _TrackingsSection(
                            controller: controller,
                            searchController: trackingsSearchController,
                            onSearch: _scheduleTrackingSearch,
                            onOpen: _openTracking,
                          );
                        case LogisticsSection.carriers:
                          return _CarriersSection(
                            controller: controller,
                            onEdit: _editCarrier,
                            onDelete: _deleteCarrier,
                          );
                      }
                    }),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _scheduleRouteSearch(String value) {
    debounce?.cancel();
    debounce = Timer(
      const Duration(milliseconds: 450),
      () => controller.searchRoutes(value),
    );
  }

  void _scheduleTrackingSearch(String value) {
    debounce?.cancel();
    debounce = Timer(
      const Duration(milliseconds: 450),
      () => controller.searchTrackings(value),
    );
  }

  bool _canCreate(LogisticsSection section) {
    switch (section) {
      case LogisticsSection.routes:
        return controller.permissions.canCreateRoute;
      case LogisticsSection.trackings:
        return controller.permissions.canManageTrackings;
      case LogisticsSection.carriers:
        return controller.permissions.canManageCarriers;
    }
  }

  String _createLabel(LogisticsSection section) {
    switch (section) {
      case LogisticsSection.routes:
        return 'Criar rota';
      case LogisticsSection.trackings:
        return 'Adicionar rastreio';
      case LogisticsSection.carriers:
        return 'Nova transportadora';
    }
  }

  String _description(LogisticsSection section) {
    switch (section) {
      case LogisticsSection.routes:
        return 'Organize visitas e entregas por região, com a melhor sequência de paradas.';
      case LogisticsSection.trackings:
        return 'Acompanhe entregas de transportadoras e identifique atrasos rapidamente.';
      case LogisticsSection.carriers:
        return 'Gerencie transportadoras e integrações usadas nos pedidos.';
    }
  }

  Future<void> _createFor(LogisticsSection section) async {
    bool? changed;
    switch (section) {
      case LogisticsSection.routes:
        changed = await showRouteEditorSheet(context, controller: controller);
        break;
      case LogisticsSection.trackings:
        changed = await showTrackingEditorDialog(context, controller: controller);
        break;
      case LogisticsSection.carriers:
        changed = await showCarrierEditorDialog(context, controller: controller);
        break;
    }
    if (!mounted || changed != true) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${_createLabel(section)} salvo com sucesso.')),
    );
  }

  Future<void> _openRoute(RoutePlanSummary summary) async {
    final route = await controller.openRoute(summary.id);
    if (!mounted || route == null) return;
    await showRouteDetailsDialog(
      context,
      controller: controller,
      route: route,
    );
  }

  Future<void> _openTracking(ShipmentTracking summary) async {
    final id = summary.id;
    if (id == null) return;
    final tracking = await controller.openTracking(id);
    if (!mounted || tracking == null) return;
    await showTrackingDetailsDialog(
      context,
      controller: controller,
      tracking: tracking,
    );
  }

  Future<void> _editCarrier(Carrier carrier) async {
    final changed = await showCarrierEditorDialog(
      context,
      controller: controller,
      carrier: carrier,
    );
    if (!mounted || changed != true) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transportadora atualizada.')),
    );
  }

  Future<void> _deleteCarrier(Carrier carrier) async {
    final id = carrier.id;
    if (id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir transportadora?'),
        content: Text(
          'A transportadora ${carrier.name} deixará de estar disponível para novos envios.',
        ),
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
    );
    if (confirmed != true) return;
    final deleted = await controller.deleteCarrier(id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          deleted
              ? 'Transportadora excluída.'
              : controller.error.value ?? 'Não foi possível excluir.',
        ),
      ),
    );
  }
}

class _LogisticsTabs extends StatelessWidget {
  const _LogisticsTabs({required this.controller});

  final LogisticsController controller;

  @override
  Widget build(BuildContext context) {
    return OrderSurface(
      padding: const EdgeInsets.all(8),
      child: Watch((context) {
        final selected = controller.section.value;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _TabButton(
                label: 'Rotas',
                icon: Icons.route_outlined,
                selected: selected == LogisticsSection.routes,
                onTap: () => controller.changeSection(LogisticsSection.routes),
              ),
              _TabButton(
                label: 'Rastreamentos',
                icon: Icons.local_shipping_outlined,
                selected: selected == LogisticsSection.trackings,
                onTap: () => controller.changeSection(LogisticsSection.trackings),
              ),
              _TabButton(
                label: 'Transportadoras',
                icon: Icons.warehouse_outlined,
                selected: selected == LogisticsSection.carriers,
                onTap: () => controller.changeSection(LogisticsSection.carriers),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.navy : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 17,
                color: selected ? AppColors.lime : AppColors.muted,
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Metrics extends StatelessWidget {
  const _Metrics({required this.controller});

  final LogisticsController controller;

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final metrics = controller.metrics;
      return LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 1100
              ? 4
              : constraints.maxWidth >= 620
                  ? 2
                  : 1;
          const spacing = 10.0;
          final width = (constraints.maxWidth - spacing * (columns - 1)) / columns;
          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [
              SizedBox(
                width: width,
                child: LogisticsMetricCard(
                  icon: Icons.route_rounded,
                  label: 'Rotas hoje',
                  value: '${metrics.routesToday}',
                  color: AppColors.cyan,
                ),
              ),
              SizedBox(
                width: width,
                child: LogisticsMetricCard(
                  icon: Icons.pin_drop_outlined,
                  label: 'Paradas pendentes',
                  value: '${metrics.pendingStops}',
                  color: const Color(0xFFE19A19),
                ),
              ),
              SizedBox(
                width: width,
                child: LogisticsMetricCard(
                  icon: Icons.task_alt_rounded,
                  label: 'Concluídas hoje',
                  value: '${metrics.completedToday}',
                  color: const Color(0xFF2A9C6A),
                ),
              ),
              SizedBox(
                width: width,
                child: LogisticsMetricCard(
                  icon: Icons.local_shipping_outlined,
                  label: 'Envios em trânsito',
                  value: '${metrics.inTransitShipments}',
                  color: AppColors.navy,
                ),
              ),
            ],
          );
        },
      );
    });
  }
}

class _RoutesSection extends StatelessWidget {
  const _RoutesSection({
    required this.controller,
    required this.searchController,
    required this.onSearch,
    required this.onOpen,
  });

  final LogisticsController controller;
  final TextEditingController searchController;
  final ValueChanged<String> onSearch;
  final ValueChanged<RoutePlanSummary> onOpen;

  @override
  Widget build(BuildContext context) {
    return OrderSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Toolbar(
            searchController: searchController,
            searchHint: 'Pesquisar rota, cidade ou motorista',
            onSearch: onSearch,
            filter: controller.routesStatus.value,
            onFilter: controller.filterRoutes,
            filterItems: const {
              'active': 'Rotas ativas',
              'draft': 'Rascunhos',
              'in_progress': 'Em andamento',
              'completed': 'Concluídas',
              'all': 'Todas',
            },
          ),
          const SizedBox(height: 16),
          Watch((context) {
            final loading = controller.routesLoading.value;
            final routes = controller.routes.value;
            if (loading && routes.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(50),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (routes.isEmpty) {
              return const _EmptyState(
                icon: Icons.route_outlined,
                title: 'Nenhuma rota encontrada',
                description:
                    'Crie uma rota para organizar as visitas e entregas da equipe.',
              );
            }
            return Column(
              children: [
                if (loading) const LinearProgressIndicator(minHeight: 2),
                ...routes.map(
                  (route) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _RouteCard(route: route, onTap: () => onOpen(route)),
                  ),
                ),
                _Pagination(
                  pagination: controller.routesPagination.value,
                  onPage: (page) => controller.loadRoutes(page: page),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  const _RouteCard({required this.route, required this.onTap});

  final RoutePlanSummary route;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.canvas,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 650;
              final title = Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.navy,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.alt_route_rounded,
                      color: AppColors.lime,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          route.name,
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          [
                            logisticsDate(route.routeDate),
                            if (route.driverName.isNotEmpty) route.driverName,
                            if (route.cities.isNotEmpty) route.cities.join(', '),
                          ].join(' • '),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  LogisticsStatusBadge(
                    status: route.status,
                    label: route.statusLabel,
                  ),
                ],
              );
              final stats = Wrap(
                spacing: 18,
                runSpacing: 7,
                children: [
                  _SmallInfo(
                    icon: Icons.pin_drop_outlined,
                    value: '${route.totalStops} paradas',
                  ),
                  _SmallInfo(
                    icon: Icons.straighten_rounded,
                    value: '${route.distanceKm.toStringAsFixed(1)} km',
                  ),
                  _SmallInfo(
                    icon: Icons.schedule_rounded,
                    value: logisticsDuration(route.durationSeconds),
                  ),
                  if (route.vehicleName.isNotEmpty)
                    _SmallInfo(
                      icon: Icons.local_shipping_outlined,
                      value: route.vehicleName,
                    ),
                ],
              );
              final progress = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            minHeight: 7,
                            value: route.progress,
                            backgroundColor: AppColors.border,
                            color: AppColors.cyan,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${route.completedStops}/${route.totalStops}',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              );
              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    title,
                    const SizedBox(height: 14),
                    stats,
                    const SizedBox(height: 12),
                    progress,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(flex: 5, child: title),
                  const SizedBox(width: 18),
                  Expanded(flex: 3, child: stats),
                  const SizedBox(width: 18),
                  Expanded(flex: 2, child: progress),
                  const SizedBox(width: 5),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TrackingsSection extends StatelessWidget {
  const _TrackingsSection({
    required this.controller,
    required this.searchController,
    required this.onSearch,
    required this.onOpen,
  });

  final LogisticsController controller;
  final TextEditingController searchController;
  final ValueChanged<String> onSearch;
  final ValueChanged<ShipmentTracking> onOpen;

  @override
  Widget build(BuildContext context) {
    return OrderSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Toolbar(
            searchController: searchController,
            searchHint: 'Pedido, cliente ou código de rastreamento',
            onSearch: onSearch,
            filter: controller.trackingsStatus.value,
            onFilter: controller.filterTrackings,
            filterItems: const {
              'active': 'Envios ativos',
              'in_transit': 'Em trânsito',
              'out_for_delivery': 'Saiu para entrega',
              'exception': 'Com problema',
              'delivered': 'Entregues',
              'all': 'Todos',
            },
          ),
          const SizedBox(height: 16),
          Watch((context) {
            final loading = controller.trackingsLoading.value;
            final trackings = controller.trackings.value;
            if (loading && trackings.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(50),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (trackings.isEmpty) {
              return const _EmptyState(
                icon: Icons.local_shipping_outlined,
                title: 'Nenhum rastreamento encontrado',
                description:
                    'Vincule o código da transportadora a um pedido para acompanhar a entrega.',
              );
            }
            return Column(
              children: [
                if (loading) const LinearProgressIndicator(minHeight: 2),
                ...trackings.map(
                  (tracking) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _TrackingCard(
                      tracking: tracking,
                      refreshing: controller.refreshingTrackingId.value == tracking.id,
                      onTap: () => onOpen(tracking),
                      onRefresh: tracking.id == null
                          ? null
                          : () => controller.refreshTracking(tracking.id!),
                    ),
                  ),
                ),
                _Pagination(
                  pagination: controller.trackingsPagination.value,
                  onPage: (page) => controller.loadTrackings(page: page),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _TrackingCard extends StatelessWidget {
  const _TrackingCard({
    required this.tracking,
    required this.refreshing,
    required this.onTap,
    required this.onRefresh,
  });

  final ShipmentTracking tracking;
  final bool refreshing;
  final VoidCallback onTap;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: tracking.hasException
          ? AppColors.danger.withOpacity(.035)
          : AppColors.canvas,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(
          color: tracking.hasException
              ? AppColors.danger.withOpacity(.3)
              : AppColors.border,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: tracking.hasException
                      ? AppColors.danger.withOpacity(.1)
                      : AppColors.navy.withOpacity(.08),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  tracking.isDelivered
                      ? Icons.inventory_2_outlined
                      : Icons.local_shipping_outlined,
                  color: tracking.hasException ? AppColors.danger : AppColors.navy,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 5,
                      children: [
                        Text(
                          'Pedido #${tracking.orderNumber}',
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        LogisticsStatusBadge(
                          status: tracking.status,
                          label: tracking.statusLabel,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${tracking.clientName} • ${tracking.carrierName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.muted, fontSize: 10.5),
                    ),
                    const SizedBox(height: 5),
                    SelectableText(
                      tracking.trackingCode,
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .5,
                      ),
                    ),
                  ],
                ),
              ),
              if (MediaQuery.sizeOf(context).width >= 760)
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tracking.lastEventDescription.isEmpty
                            ? 'Aguardando atualização da transportadora'
                            : tracking.lastEventDescription,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tracking.lastEventAt == null
                            ? 'Previsão: ${logisticsDate(tracking.estimatedDeliveryAt)}'
                            : 'Atualizado ${logisticsDateTime(tracking.lastEventAt)}',
                        style: const TextStyle(color: AppColors.muted, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              IconButton(
                tooltip: 'Atualizar rastreamento',
                onPressed: refreshing ? null : onRefresh,
                icon: refreshing
                    ? const SizedBox(
                        width: 17,
                        height: 17,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync_rounded),
              ),
              if (tracking.trackingUrl.isNotEmpty)
                IconButton(
                  tooltip: 'Abrir site da transportadora',
                  onPressed: () => launchUrl(
                    Uri.parse(tracking.trackingUrl),
                    mode: LaunchMode.externalApplication,
                  ),
                  icon: const Icon(Icons.open_in_new_rounded),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CarriersSection extends StatelessWidget {
  const _CarriersSection({
    required this.controller,
    required this.onEdit,
    required this.onDelete,
  });

  final LogisticsController controller;
  final ValueChanged<Carrier> onEdit;
  final ValueChanged<Carrier> onDelete;

  @override
  Widget build(BuildContext context) {
    return OrderSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const OrderSectionTitle(
            icon: Icons.warehouse_outlined,
            title: 'Transportadoras cadastradas',
            description:
                'Integrações automáticas e links usados para localizar os envios.',
          ),
          const SizedBox(height: 18),
          Watch((context) {
            if (controller.carriersLoading.value && controller.carriers.value.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(50),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final carriers = controller.carriers.value;
            if (carriers.isEmpty) {
              return const _EmptyState(
                icon: Icons.warehouse_outlined,
                title: 'Nenhuma transportadora cadastrada',
                description:
                    'Cadastre uma transportadora para vincular códigos aos pedidos.',
              );
            }
            return LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth >= 980
                    ? (constraints.maxWidth - 12) / 2
                    : constraints.maxWidth;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: carriers
                      .map(
                        (carrier) => SizedBox(
                          width: width,
                          child: _CarrierCard(
                            carrier: carrier,
                            deleting: controller.deletingCarrierId.value == carrier.id,
                            onEdit: () => onEdit(carrier),
                            onDelete: () => onDelete(carrier),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            );
          }),
        ],
      ),
    );
  }
}

class _CarrierCard extends StatelessWidget {
  const _CarrierCard({
    required this.carrier,
    required this.deleting,
    required this.onEdit,
    required this.onDelete,
  });

  final Carrier carrier;
  final bool deleting;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final providerLabel = switch (carrier.provider) {
      'aftership' => 'AfterShip',
      'melhor_envio' => 'Melhor Envio',
      _ => 'Link personalizado',
    };
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: AppColors.navy,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(Icons.local_shipping_outlined, color: AppColors.lime),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        carrier.name,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    LogisticsStatusBadge(
                      status: carrier.active ? 'completed' : 'cancelled',
                      label: carrier.active ? 'Ativa' : 'Inativa',
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  providerLabel,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (carrier.email.isNotEmpty)
                  Text(
                    carrier.email,
                    style: const TextStyle(color: AppColors.muted, fontSize: 10.5),
                  ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  children: [
                    OutlinedButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 15),
                      label: const Text('Editar'),
                    ),
                    TextButton.icon(
                      onPressed: deleting ? null : onDelete,
                      icon: deleting
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.delete_outline_rounded, size: 15),
                      label: const Text('Excluir'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.searchController,
    required this.searchHint,
    required this.onSearch,
    required this.filter,
    required this.onFilter,
    required this.filterItems,
  });

  final TextEditingController searchController;
  final String searchHint;
  final ValueChanged<String> onSearch;
  final String filter;
  final ValueChanged<String> onFilter;
  final Map<String, String> filterItems;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final search = TextField(
          controller: searchController,
          onChanged: onSearch,
          decoration: InputDecoration(
            hintText: searchHint,
            prefixIcon: const Icon(Icons.search_rounded),
          ),
        );
        final dropdown = DropdownButtonFormField<String>(
          value: filter,
          decoration: const InputDecoration(labelText: 'Exibir'),
          items: filterItems.entries
              .map(
                (entry) => DropdownMenuItem(
                  value: entry.key,
                  child: Text(entry.value),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) onFilter(value);
          },
        );
        if (constraints.maxWidth < 650) {
          return Column(
            children: [search, const SizedBox(height: 10), dropdown],
          );
        }
        return Row(
          children: [
            Expanded(child: search),
            const SizedBox(width: 10),
            SizedBox(width: 210, child: dropdown),
          ],
        );
      },
    );
  }
}

class _SmallInfo extends StatelessWidget {
  const _SmallInfo({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: AppColors.muted),
        const SizedBox(width: 5),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _Pagination extends StatelessWidget {
  const _Pagination({required this.pagination, required this.onPage});

  final LogisticsPagination pagination;
  final ValueChanged<int> onPage;

  @override
  Widget build(BuildContext context) {
    if (pagination.totalPages <= 1) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            'Página ${pagination.page} de ${pagination.totalPages}',
            style: const TextStyle(color: AppColors.muted, fontSize: 10.5),
          ),
          const SizedBox(width: 8),
          IconButton.outlined(
            onPressed: pagination.page <= 1
                ? null
                : () => onPage(pagination.page - 1),
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          const SizedBox(width: 5),
          IconButton.outlined(
            onPressed: pagination.hasNextPage
                ? () => onPage(pagination.page + 1)
                : null,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 54),
      child: Column(
        children: [
          Icon(icon, size: 48, color: AppColors.muted),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted, fontSize: 11.5),
          ),
        ],
      ),
    );
  }
}

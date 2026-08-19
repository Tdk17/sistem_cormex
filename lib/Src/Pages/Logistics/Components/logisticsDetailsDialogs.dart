import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';
import 'package:sistem_cormex/Src/Config/appColors.dart';
import 'package:sistem_cormex/Src/Models/logisticsModels.dart';
import 'package:sistem_cormex/Src/Pages/Logistics/Components/logisticsCommon.dart';
import 'package:sistem_cormex/Src/Pages/Logistics/Controller/logisticsController.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> showRouteDetailsDialog(
  BuildContext context, {
  required LogisticsController controller,
  required RoutePlan route,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _RouteDetailsDialog(
      controller: controller,
      initialRoute: route,
    ),
  );
}

class _RouteDetailsDialog extends StatelessWidget {
  const _RouteDetailsDialog({
    required this.controller,
    required this.initialRoute,
  });

  final LogisticsController controller;
  final RoutePlan initialRoute;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1050, maxHeight: 820),
        child: Watch((context) {
          final route = controller.selectedRoute.value ?? initialRoute;
          final operating = controller.operatingRoute.value;
          return Scaffold(
            backgroundColor: AppColors.canvas,
            appBar: AppBar(
              automaticallyImplyLeading: false,
              backgroundColor: Colors.white,
              foregroundColor: AppColors.ink,
              elevation: 0,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    route.name,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                  ),
                  Text(
                    '${logisticsDate(route.routeDate)} • ${route.stops.length} paradas',
                    style: const TextStyle(color: AppColors.muted, fontSize: 10.5),
                  ),
                ],
              ),
              actions: [
                LogisticsStatusBadge(
                  status: route.status,
                  label: route.statusLabel,
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Fechar',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            body: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 760;
                final map = Padding(
                  padding: const EdgeInsets.all(14),
                  child: SizedBox(
                    height: compact ? 260 : double.infinity,
                    child: LogisticsRouteMap(route: route),
                  ),
                );
                final list = _RouteStops(
                  controller: controller,
                  route: route,
                  operating: operating,
                );
                if (compact) {
                  return ListView(
                    children: [
                      map,
                      SizedBox(height: 520, child: list),
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(flex: 5, child: map),
                    const VerticalDivider(width: 1),
                    Expanded(flex: 4, child: list),
                  ],
                );
              },
            ),
            bottomNavigationBar: Material(
              color: Colors.white,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: route.stops.isEmpty ? null : () => _openNavigation(route),
                        icon: const Icon(Icons.navigation_outlined, size: 17),
                        label: const Text('Abrir navegação'),
                      ),
                      if (route.status == 'draft' || route.status == 'ready')
                        FilledButton.icon(
                          onPressed: operating || route.id == null
                              ? null
                              : () => controller.startRoute(route.id!),
                          icon: const Icon(Icons.play_arrow_rounded, size: 18),
                          label: const Text('Iniciar rota'),
                        ),
                      if (route.status == 'in_progress')
                        FilledButton.icon(
                          onPressed: operating || route.id == null
                              ? null
                              : () => controller.finishRoute(route.id!),
                          icon: const Icon(Icons.flag_outlined, size: 18),
                          label: const Text('Finalizar rota'),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Future<void> _openNavigation(RoutePlan route) async {
    final pending = route.stops.where((stop) => !stop.isCompleted).toList();
    final stops = pending.isEmpty ? route.stops : pending;
    if (stops.isEmpty) return;
    final origin = route.origin.hasCoordinates
        ? '${route.origin.latitude},${route.origin.longitude}'
        : route.origin.formatted;
    final destination = stops.last.address.hasCoordinates
        ? '${stops.last.address.latitude},${stops.last.address.longitude}'
        : stops.last.address.formatted;
    final waypoints = stops.take(stops.length - 1).map((stop) {
      return stop.address.hasCoordinates
          ? '${stop.address.latitude},${stop.address.longitude}'
          : stop.address.formatted;
    }).where((value) => value.isNotEmpty).join('|');
    final uri = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      if (origin.isNotEmpty) 'origin': origin,
      'destination': destination,
      if (waypoints.isNotEmpty) 'waypoints': waypoints,
      'travelmode': 'driving',
    });
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _RouteStops extends StatelessWidget {
  const _RouteStops({
    required this.controller,
    required this.route,
    required this.operating,
  });

  final LogisticsController controller;
  final RoutePlan route;
  final bool operating;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Sequência de paradas',
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  '${route.distanceKm.toStringAsFixed(1)} km • ${logisticsDuration(route.durationSeconds)}',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: route.stops.isEmpty
                ? const Center(child: Text('Nenhuma parada cadastrada.'))
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: route.stops.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final stop = route.stops[index];
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.canvas,
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: stop.isCompleted
                                  ? const Color(0xFF14734E)
                                  : AppColors.navy,
                              foregroundColor: stop.isCompleted
                                  ? Colors.white
                                  : AppColors.lime,
                              child: stop.isCompleted
                                  ? const Icon(Icons.check_rounded, size: 17)
                                  : Text(
                                      '${stop.sequence}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    stop.clientName,
                                    style: const TextStyle(
                                      color: AppColors.ink,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    stop.address.formatted,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.muted,
                                      fontSize: 10,
                                    ),
                                  ),
                                  const SizedBox(height: 7),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 5,
                                    children: [
                                      LogisticsStatusBadge(
                                        status: stop.status,
                                        label: stop.statusLabel,
                                      ),
                                      LogisticsStatusBadge(
                                        status: 'ready',
                                        label: stop.kindLabel,
                                      ),
                                      if (stop.estimatedArrival != null)
                                        Text(
                                          'Chegada ${logisticsDateTime(stop.estimatedArrival).split(' às ').last}',
                                          style: const TextStyle(
                                            color: AppColors.muted,
                                            fontSize: 10,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (route.status == 'in_progress' && !stop.isCompleted)
                              PopupMenuButton<String>(
                                tooltip: 'Atualizar parada',
                                enabled: !operating,
                                onSelected: (status) {
                                  if (route.id == null) return;
                                  controller.updateRouteStop(
                                    routeId: route.id!,
                                    stopId: stop.id,
                                    status: status,
                                  );
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                    value: 'in_progress',
                                    child: Text('Em deslocamento'),
                                  ),
                                  PopupMenuItem(
                                    value: 'completed',
                                    child: Text('Concluir parada'),
                                  ),
                                  PopupMenuItem(
                                    value: 'absent',
                                    child: Text('Cliente ausente'),
                                  ),
                                  PopupMenuItem(
                                    value: 'cancelled',
                                    child: Text('Cancelar parada'),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

Future<void> showTrackingDetailsDialog(
  BuildContext context, {
  required LogisticsController controller,
  required ShipmentTracking tracking,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _TrackingDetailsDialog(
      controller: controller,
      initialTracking: tracking,
    ),
  );
}

class _TrackingDetailsDialog extends StatelessWidget {
  const _TrackingDetailsDialog({
    required this.controller,
    required this.initialTracking,
  });

  final LogisticsController controller;
  final ShipmentTracking initialTracking;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Watch((context) {
        final tracking = controller.selectedTracking.value ?? initialTracking;
        return Row(
          children: [
            const Expanded(child: Text('Detalhes do rastreamento')),
            LogisticsStatusBadge(
              status: tracking.status,
              label: tracking.statusLabel,
            ),
          ],
        );
      }),
      content: SizedBox(
        width: 700,
        child: Watch((context) {
          final tracking = controller.selectedTracking.value ?? initialTracking;
          final events = [...tracking.events]
            ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: AppColors.canvas,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Wrap(
                    spacing: 28,
                    runSpacing: 12,
                    children: [
                      _TrackingInfo(label: 'Pedido', value: '#${tracking.orderNumber}'),
                      _TrackingInfo(label: 'Cliente', value: tracking.clientName),
                      _TrackingInfo(label: 'Transportadora', value: tracking.carrierName),
                      _TrackingInfo(label: 'Código', value: tracking.trackingCode),
                      _TrackingInfo(
                        label: 'Previsão',
                        value: logisticsDate(tracking.estimatedDeliveryAt),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Histórico da entrega',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                if (events.isEmpty)
                  const Text(
                    'A transportadora ainda não enviou movimentações.',
                    style: TextStyle(color: AppColors.muted, fontSize: 11.5),
                  )
                else
                  ...events.map(
                    (event) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            margin: const EdgeInsets.only(top: 3),
                            decoration: const BoxDecoration(
                              color: AppColors.cyan,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 11),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  event.description,
                                  style: const TextStyle(
                                    color: AppColors.ink,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  '${logisticsDateTime(event.occurredAt)}${event.location.isEmpty ? '' : ' • ${event.location}'}',
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 10.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
      actions: [
        Watch((context) {
          final tracking = controller.selectedTracking.value ?? initialTracking;
          return OutlinedButton.icon(
            onPressed: tracking.trackingUrl.isEmpty
                ? null
                : () => launchUrl(
                      Uri.parse(tracking.trackingUrl),
                      mode: LaunchMode.externalApplication,
                    ),
            icon: const Icon(Icons.open_in_new_rounded, size: 16),
            label: const Text('Site da transportadora'),
          );
        }),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fechar'),
        ),
      ],
    );
  }
}

class _TrackingInfo extends StatelessWidget {
  const _TrackingInfo({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 175,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            value.isEmpty ? '—' : value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

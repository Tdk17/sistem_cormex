import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals/signals_flutter.dart';
import 'package:sistem_cormex/Src/Config/appColors.dart';
import 'package:sistem_cormex/Src/Dependencies/dependencies.dart';
import 'package:sistem_cormex/Src/Models/orderModels.dart';
import 'package:sistem_cormex/Src/Pages/Orders/Components/orderCommon.dart';
import 'package:sistem_cormex/Src/Pages/Orders/Controller/ordersController.dart';
import 'package:sistem_cormex/Src/Routes/appRouter.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  late final OrdersController controller;
  late final TextEditingController searchController;
  Timer? searchDebounce;

  @override
  void initState() {
    super.initState();
    controller = getIt<OrdersController>();
    searchController = TextEditingController(text: controller.query.value);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.initializeList();
    });
  }

  @override
  void dispose() {
    searchDebounce?.cancel();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OrdersScaffold(
      floatingActionButton: MediaQuery.sizeOf(context).width < 650
          ? FloatingActionButton.extended(
              onPressed: () => context.go(AppRoutes.orderNew),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Novo pedido'),
            )
          : null,
      child: Scrollbar(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 22, 18, 36),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1580),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OrdersPageHeader(
                    title: 'Pedidos',
                    description:
                        'Crie orçamentos, acompanhe pedidos e compartilhe documentos.',
                    actions: [
                      OutlinedButton.icon(
                        onPressed: () => controller.loadOrders(),
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Atualizar'),
                      ),
                      if (MediaQuery.sizeOf(context).width >= 650)
                        FilledButton.icon(
                          onPressed: () => context.go(AppRoutes.orderNew),
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Criar pedido'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.navy,
                            foregroundColor: Colors.white,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _OrderFilters(
                    controller: controller,
                    searchController: searchController,
                    onSearchChanged: _scheduleSearch,
                  ),
                  const SizedBox(height: 16),
                  _OrdersContent(controller: controller),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _scheduleSearch(String value) {
    searchDebounce?.cancel();
    searchDebounce = Timer(
      const Duration(milliseconds: 450),
      () => controller.applySearch(value),
    );
  }
}

class _OrderFilters extends StatelessWidget {
  const _OrderFilters({
    required this.controller,
    required this.searchController,
    required this.onSearchChanged,
  });

  final OrdersController controller;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final options = controller.filterOptions.value;
      final loading = controller.listLoading.value;
      return OrderSurface(
        padding: const EdgeInsets.all(14),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 850;
            final search = TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              onSubmitted: controller.applySearch,
              decoration: InputDecoration(
                hintText: 'Pedido, cliente, documento ou representada',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: searchController.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          searchController.clear();
                          controller.applySearch('');
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
            );
            final status = DropdownButtonFormField<String>(
              value: controller.selectedStatus.value ?? '',
              decoration: const InputDecoration(labelText: 'Status'),
              items: [
                const DropdownMenuItem(value: '', child: Text('Todos')),
                for (final item in options?.statuses ?? const <OrderSelectOption>[])
                  DropdownMenuItem(value: item.id, child: Text(item.label)),
              ],
              onChanged: loading
                  ? null
                  : (value) => controller.changeStatus(
                        value == null || value.isEmpty ? null : value,
                      ),
            );
            final seller = DropdownButtonFormField<String>(
              value: controller.selectedSellerId.value ?? '',
              decoration: const InputDecoration(labelText: 'Vendedor'),
              items: [
                const DropdownMenuItem(
                  value: '',
                  child: Text('Todos os vendedores'),
                ),
                for (final item in options?.sellers ?? const <OrderSelectOption>[])
                  DropdownMenuItem(value: item.id, child: Text(item.label)),
              ],
              onChanged: loading
                  ? null
                  : (value) => controller.changeSeller(
                        value == null || value.isEmpty ? null : value,
                      ),
            );
            final period = OutlinedButton.icon(
              onPressed: loading ? null : () => _pickDateRange(context),
              icon: const Icon(Icons.calendar_month_outlined),
              label: Text(_periodLabel()),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(190, 55),
                alignment: Alignment.centerLeft,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            );
            final hasPeriod = controller.dateFrom.value != null &&
                controller.dateTo.value != null;
            final periodFilter = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(child: period),
                if (hasPeriod) ...[
                  const SizedBox(width: 6),
                  IconButton.outlined(
                    tooltip: 'Limpar período',
                    onPressed: loading
                        ? null
                        : () => controller.changeDateRange(null),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ],
            );

            if (narrow) {
              return Column(
                children: [
                  search,
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: status),
                      const SizedBox(width: 10),
                      Expanded(child: seller),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(width: double.infinity, child: periodFilter),
                ],
              );
            }
            return Row(
              children: [
                Expanded(flex: 4, child: search),
                const SizedBox(width: 10),
                Expanded(flex: 2, child: status),
                const SizedBox(width: 10),
                Expanded(flex: 2, child: seller),
                const SizedBox(width: 10),
                SizedBox(width: hasPeriod ? 270 : 210, child: periodFilter),
              ],
            );
          },
        ),
      );
    });
  }

  String _periodLabel() {
    final start = controller.dateFrom.value;
    final end = controller.dateTo.value;
    if (start == null || end == null) return 'Qualquer período';
    return '${orderDate(start)} — ${orderDate(end)}';
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final now = DateTime.now();
    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 2),
      initialDateRange:
          controller.dateFrom.value != null && controller.dateTo.value != null
              ? DateTimeRange(
                  start: controller.dateFrom.value!,
                  end: controller.dateTo.value!,
                )
              : null,
      helpText: 'Período dos pedidos',
      cancelText: 'Cancelar',
      confirmText: 'Aplicar',
    );
    if (result != null) {
      controller.changeDateRange(DateTimeRangeValue(result.start, result.end));
    }
  }
}

class _OrdersContent extends StatelessWidget {
  const _OrdersContent({required this.controller});
  final OrdersController controller;

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final loading = controller.listLoading.value;
      final error = controller.listError.value;
      final orders = controller.orders.value;
      if (loading && orders.isEmpty) {
        return const OrderSurface(
          child: SizedBox(
            height: 300,
            child: Center(child: CircularProgressIndicator()),
          ),
        );
      }
      if (error != null && orders.isEmpty) {
        return OrderInlineError(
          message: error,
          onRetry: controller.loadOrders,
        );
      }
      if (orders.isEmpty) {
        return OrderSurface(
          child: SizedBox(
            height: 300,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.receipt_long_outlined,
                    size: 48,
                    color: AppColors.muted,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Nenhum pedido encontrado',
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Ajuste os filtros ou crie o primeiro pedido.',
                    style: TextStyle(color: AppColors.muted),
                  ),
                  const SizedBox(height: 15),
                  FilledButton.icon(
                    onPressed: () => context.go(AppRoutes.orderNew),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Criar pedido'),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      final groups = <DateTime, List<OrderSummary>>{};
      for (final order in orders) {
        final date = order.issueDate ?? DateTime(1970);
        final key = DateTime(date.year, date.month, date.day);
        groups.putIfAbsent(key, () => []).add(order);
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (error != null) ...[
            OrderInlineError(message: error, onRetry: controller.loadOrders),
            const SizedBox(height: 14),
          ],
          if (loading) const LinearProgressIndicator(minHeight: 2),
          for (final group in groups.entries) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 18, 4, 9),
              child: Text(
                _groupLabel(group.key),
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .6,
                ),
              ),
            ),
            for (final order in group.value) ...[
              _OrderCard(order: order),
              const SizedBox(height: 10),
            ],
          ],
          const SizedBox(height: 10),
          _OrderPagination(controller: controller),
        ],
      );
    });
  }

  String _groupLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (date == today) return 'HOJE';
    if (date == today.subtract(const Duration(days: 1))) return 'ONTEM';
    return orderDate(date, withWeekday: true).toUpperCase();
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});
  final OrderSummary order;

  @override
  Widget build(BuildContext context) {
    return OrderSurface(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: () => context.go(AppRoutes.orderById(order.id)),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 650;
              final identity = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '#${order.number}',
                        style: const TextStyle(
                          color: AppColors.cyan,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          order.customer.displayName,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 14,
                    runSpacing: 6,
                    children: [
                      _OrderMeta(
                        icon: Icons.business_outlined,
                        text: order.representedCompanyName,
                      ),
                      _OrderMeta(
                        icon: Icons.person_outline_rounded,
                        text: order.sellerName,
                      ),
                      _OrderMeta(
                        icon: Icons.inventory_2_outlined,
                        text: '${order.itemCount} itens',
                      ),
                    ],
                  ),
                ],
              );
              final summary = Column(
                crossAxisAlignment:
                    narrow ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      OrderStatusBadge(
                        status: order.status,
                        label: order.statusLabel,
                      ),
                      if (order.invoiced)
                        const OrderStatusBadge(
                          status: 'invoiced',
                          label: 'Faturado',
                        ),
                      if (order.completed)
                        const OrderStatusBadge(
                          status: 'completed',
                          label: 'Concluído',
                        ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  Text(
                    orderCurrency(order.total),
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              );
              if (narrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    identity,
                    const SizedBox(height: 14),
                    summary,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: identity),
                  const SizedBox(width: 20),
                  summary,
                  const SizedBox(width: 6),
                  const Icon(Icons.chevron_right_rounded),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _OrderMeta extends StatelessWidget {
  const _OrderMeta({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.muted),
        const SizedBox(width: 5),
        Text(
          text.isEmpty ? '—' : text,
          style: const TextStyle(color: AppColors.muted, fontSize: 11),
        ),
      ],
    );
  }
}

class _OrderPagination extends StatelessWidget {
  const _OrderPagination({required this.controller});
  final OrdersController controller;

  @override
  Widget build(BuildContext context) {
    final pagination = controller.pagination.value;
    if (pagination == null || pagination.totalPages <= 1) {
      return const SizedBox.shrink();
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          '${pagination.totalItems} pedidos · Página ${pagination.page} de ${pagination.totalPages}',
          style: const TextStyle(color: AppColors.muted, fontSize: 12),
        ),
        const SizedBox(width: 10),
        IconButton.outlined(
          onPressed: controller.listLoading.value || pagination.page <= 1
              ? null
              : () => controller.loadOrders(page: pagination.page - 1),
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        const SizedBox(width: 6),
        IconButton.outlined(
          onPressed: controller.listLoading.value || !pagination.hasNextPage
              ? null
              : () => controller.loadOrders(page: pagination.page + 1),
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }
}

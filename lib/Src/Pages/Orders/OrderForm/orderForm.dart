import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals/signals_flutter.dart';
import 'package:sistem_cormex/Src/Config/appColors.dart';
import 'package:sistem_cormex/Src/Dependencies/dependencies.dart';
import 'package:sistem_cormex/Src/Models/orderModels.dart';
import 'package:sistem_cormex/Src/Pages/Orders/Components/orderCommon.dart';
import 'package:sistem_cormex/Src/Pages/Orders/Components/orderPreviewDialog.dart';
import 'package:sistem_cormex/Src/Pages/Orders/Controller/ordersController.dart';
import 'package:sistem_cormex/Src/Routes/appRouter.dart';

class OrderFormPage extends StatefulWidget {
  const OrderFormPage({super.key, this.orderId});
  final String? orderId;

  @override
  State<OrderFormPage> createState() => _OrderFormPageState();
}

class _OrderFormPageState extends State<OrderFormPage> {
  late final OrdersController controller;
  final clientSearchController = TextEditingController();
  final productSearchController = TextEditingController();
  final shippingController = TextEditingController();
  final trackingController = TextEditingController();
  final addressController = TextEditingController();
  final contactController = TextEditingController();
  final notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    controller = getIt<OrdersController>();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  @override
  void didUpdateWidget(covariant OrderFormPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.orderId != widget.orderId) _initialize();
  }

  Future<void> _initialize() async {
    await controller.initializeForm(widget.orderId);
    if (mounted) _syncFields();
  }

  void _syncFields() {
    final order = controller.editingOrder.value;
    if (order == null) return;
    shippingController.text = order.shippingCost == 0
        ? ''
        : order.shippingCost.toStringAsFixed(2).replaceAll('.', ',');
    trackingController.text = order.trackingCode;
    addressController.text = order.deliveryAddress;
    contactController.text = order.customerContact;
    notesController.text = order.notes;
    clientSearchController.clear();
    productSearchController.clear();
  }

  @override
  void dispose() {
    clientSearchController.dispose();
    productSearchController.dispose();
    shippingController.dispose();
    trackingController.dispose();
    addressController.dispose();
    contactController.dispose();
    notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OrdersScaffold(
      child: Watch((context) {
        final loading = controller.formLoading.value;
        final error = controller.formError.value;
        final order = controller.editingOrder.value;
        if (loading && order == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (order == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 650),
                child: OrderInlineError(
                  message: error ?? 'Não foi possível abrir o pedido.',
                  onRetry: _initialize,
                ),
              ),
            ),
          );
        }

        return Scrollbar(
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
                      leading: IconButton.outlined(
                        tooltip: 'Voltar para pedidos',
                        onPressed: () => context.go(AppRoutes.orders),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      title: order.isPersisted
                          ? 'Pedido #${order.number}'
                          : 'Novo pedido #${order.number}',
                      description: order.isPersisted
                          ? 'Edite, confirme e compartilhe este pedido.'
                          : 'Monte um orçamento e salve quando estiver pronto.',
                      actions: [
                        OrderStatusBadge(
                          status: order.status,
                          label: order.statusLabel,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _OrderActionBar(
                      controller: controller,
                      onSaved: _afterSave,
                      onPreview: _openPreview,
                      onEmail: _openEmail,
                      onConfirm: _confirm,
                      onDuplicate: _duplicate,
                      onCancel: _cancel,
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 12),
                      OrderInlineError(message: error),
                    ],
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final content = Column(
                          children: [
                            _ClientSection(
                              controller: controller,
                              searchController: clientSearchController,
                              onSelected: () {
                                _syncFields();
                                setState(() {});
                              },
                            ),
                            const SizedBox(height: 14),
                            _CompanySection(order: order),
                            const SizedBox(height: 14),
                            _ProductsSection(
                              controller: controller,
                              searchController: productSearchController,
                            ),
                            const SizedBox(height: 14),
                            _DetailsSection(
                              controller: controller,
                              shippingController: shippingController,
                              trackingController: trackingController,
                              addressController: addressController,
                              contactController: contactController,
                              notesController: notesController,
                            ),
                          ],
                        );
                        final summary = _OrderSummaryCard(
                          controller: controller,
                          onPreview: _openPreview,
                          onConfirm: _confirm,
                        );
                        if (constraints.maxWidth < 1080) {
                          return Column(
                            children: [
                              content,
                              const SizedBox(height: 14),
                              summary,
                            ],
                          );
                        }
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: content),
                            const SizedBox(width: 16),
                            SizedBox(width: 320, child: summary),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Future<void> _afterSave() async {
    final wasNew = !controller.editingOrder.value!.isPersisted;
    final saved = await controller.saveDraft();
    if (!mounted) return;
    if (saved) {
      _syncFields();
      final id = controller.editingOrder.value?.id;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pedido salvo com sucesso.')),
      );
      if (wasNew && id != null) context.go(AppRoutes.orderById(id));
    }
  }

  Future<void> _confirm() async {
    final confirmed = await controller.confirmOrder();
    if (mounted && confirmed) {
      _syncFields();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pedido confirmado com sucesso.')),
      );
    }
  }

  Future<void> _openPreview() async {
    final loaded = await controller.loadPreview();
    if (loaded && mounted) showOrderPreviewDialog(context, controller);
  }

  Future<void> _openEmail() async {
    final loaded = await controller.loadPreview();
    if (loaded && mounted) showOrderEmailDialog(context, controller);
  }

  Future<void> _duplicate() async {
    final id = await controller.duplicateOrder();
    if (id != null && mounted) context.go(AppRoutes.orderById(id));
  }

  Future<void> _cancel() async {
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancelar pedido?'),
        content: TextField(
          controller: reasonController,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Motivo do cancelamento',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Voltar'),
          ),
          FilledButton(
            onPressed: () {
              final value = reasonController.text.trim();
              if (value.length >= 3) Navigator.pop(dialogContext, value);
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Cancelar pedido'),
          ),
        ],
      ),
    );
    reasonController.dispose();
    if (reason == null) return;
    final cancelled = await controller.cancelOrder(reason);
    if (mounted && cancelled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pedido cancelado.')),
      );
    }
  }
}

class _OrderActionBar extends StatelessWidget {
  const _OrderActionBar({
    required this.controller,
    required this.onSaved,
    required this.onPreview,
    required this.onEmail,
    required this.onConfirm,
    required this.onDuplicate,
    required this.onCancel,
  });

  final OrdersController controller;
  final VoidCallback onSaved;
  final VoidCallback onPreview;
  final VoidCallback onEmail;
  final VoidCallback onConfirm;
  final VoidCallback onDuplicate;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final order = controller.editingOrder.value!;
      final busy = controller.saving.value || controller.actionLoading.value;
      return OrderSurface(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (order.permissions.canEdit)
              OutlinedButton.icon(
                onPressed: busy ? null : onSaved,
                icon: controller.saving.value
                    ? const SizedBox.square(
                        dimension: 17,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined, size: 18),
                label: Text(controller.saving.value ? 'Salvando…' : 'Salvar'),
              ),
            if (order.permissions.canConfirm && order.status == 'draft')
              FilledButton.icon(
                onPressed: busy ? null : onConfirm,
                icon: const Icon(Icons.task_alt_rounded, size: 18),
                label: const Text('Gerar pedido'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  foregroundColor: Colors.white,
                ),
              ),
            OutlinedButton.icon(
              onPressed: busy ? null : onPreview,
              icon: const Icon(Icons.visibility_outlined, size: 18),
              label: const Text('Visualizar'),
            ),
            if (order.permissions.canSendEmail)
              OutlinedButton.icon(
                onPressed: busy ? null : onEmail,
                icon: const Icon(Icons.mail_outline_rounded, size: 18),
                label: const Text('Enviar por e-mail'),
              ),
            if (order.isPersisted)
              PopupMenuButton<String>(
                enabled: !busy,
                onSelected: (value) {
                  if (value == 'duplicate') onDuplicate();
                  if (value == 'cancel') onCancel();
                },
                itemBuilder: (_) => [
                  if (order.permissions.canDuplicate)
                    const PopupMenuItem(
                      value: 'duplicate',
                      child: ListTile(
                        leading: Icon(Icons.content_copy_rounded),
                        title: Text('Duplicar pedido'),
                      ),
                    ),
                  if (order.permissions.canCancel && order.status != 'cancelled')
                    const PopupMenuItem(
                      value: 'cancel',
                      child: ListTile(
                        leading: Icon(
                          Icons.cancel_outlined,
                          color: AppColors.danger,
                        ),
                        title: Text('Cancelar pedido'),
                      ),
                    ),
                ],
                child: const _PopupButtonVisual(),
              ),
          ],
        ),
      );
    });
  }
}

class _PopupButtonVisual extends StatelessWidget {
  const _PopupButtonVisual();
  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: OutlinedButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.more_horiz_rounded),
        label: const Text('Mais opções'),
      ),
    );
  }
}

class _ClientSection extends StatelessWidget {
  const _ClientSection({
    required this.controller,
    required this.searchController,
    required this.onSelected,
  });

  final OrdersController controller;
  final TextEditingController searchController;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final order = controller.editingOrder.value!;
      final client = order.customer;
      return OrderSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OrderSectionTitle(
              icon: Icons.business_center_outlined,
              title: 'Cliente',
              description: 'Selecione quem receberá o pedido.',
              trailing: client == null
                  ? null
                  : IconButton(
                      tooltip: 'Trocar cliente',
                      onPressed:
                          order.permissions.canEdit ? controller.clearClient : null,
                      icon: const Icon(Icons.swap_horiz_rounded),
                    ),
            ),
            const SizedBox(height: 16),
            if (client != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.canvas,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: AppColors.border),
                ),
                child: Wrap(
                  spacing: 24,
                  runSpacing: 10,
                  children: [
                    _InfoBlock(
                      label: 'Cliente',
                      value: client.displayName,
                      detail: client.name,
                    ),
                    _InfoBlock(
                      label: 'Documento',
                      value: client.document,
                      detail: client.phone,
                    ),
                    _InfoBlock(
                      label: 'Contato',
                      value: client.email,
                      detail: order.deliveryAddress,
                    ),
                  ],
                ),
              )
            else ...[
              TextField(
                controller: searchController,
                enabled: order.permissions.canEdit,
                onChanged: controller.searchClients,
                decoration: InputDecoration(
                  hintText: 'Digite nome, CPF/CNPJ, e-mail ou telefone',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: controller.clientSearchLoading.value
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : null,
                ),
              ),
              if (controller.clientResults.value.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 270),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: controller.clientResults.value.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = controller.clientResults.value[index];
                      return ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: AppColors.field,
                          child: Icon(Icons.business_outlined),
                        ),
                        title: Text(item.displayName),
                        subtitle: Text('${item.document} · ${item.email}'),
                        onTap: () {
                          controller.selectClient(item);
                          onSelected();
                        },
                      );
                    },
                  ),
                ),
              ],
            ],
          ],
        ),
      );
    });
  }
}

class _CompanySection extends StatelessWidget {
  const _CompanySection({required this.order});
  final OrderDetail order;

  @override
  Widget build(BuildContext context) {
    final company = order.representedCompany;
    return OrderSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const OrderSectionTitle(
            icon: Icons.domain_outlined,
            title: 'Representada',
            description: 'Empresa responsável por este pedido.',
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 28,
            runSpacing: 10,
            children: [
              _InfoBlock(
                label: 'Empresa',
                value: company.name,
                detail: company.legalName,
              ),
              _InfoBlock(
                label: 'Documento',
                value: company.document,
                detail: company.phone,
              ),
              _InfoBlock(
                label: 'E-mail',
                value: company.email,
                detail: '',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProductsSection extends StatelessWidget {
  const _ProductsSection({
    required this.controller,
    required this.searchController,
  });

  final OrdersController controller;
  final TextEditingController searchController;

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final order = controller.editingOrder.value!;
      return OrderSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OrderSectionTitle(
              icon: Icons.inventory_2_outlined,
              title: 'Produtos',
              description: 'Adicione itens e ajuste quantidades e descontos.',
              trailing: Text(
                '${order.items.length} ${order.items.length == 1 ? 'item' : 'itens'}',
                style: const TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (order.permissions.canEdit) ...[
              const SizedBox(height: 16),
              TextField(
                controller: searchController,
                onChanged: controller.searchProducts,
                decoration: InputDecoration(
                  hintText: 'Código, nome ou descrição do produto',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: controller.productSearchLoading.value
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : null,
                ),
              ),
              if (controller.productResults.value.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 290),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: controller.productResults.value.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final product = controller.productResults.value[index];
                      return ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: AppColors.field,
                          child: Icon(Icons.inventory_2_outlined),
                        ),
                        title: Text(product.name),
                        subtitle: Text(
                          '${product.code} · ${product.unit}${product.availableStock == null ? '' : ' · Estoque ${orderQuantity(product.availableStock!)}'}',
                        ),
                        trailing: Text(
                          orderCurrency(product.listPrice),
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        onTap: () {
                          controller.addProduct(product);
                          searchController.clear();
                        },
                      );
                    },
                  ),
                ),
              ],
            ],
            const SizedBox(height: 14),
            if (order.items.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppColors.canvas,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.add_shopping_cart_outlined,
                      color: AppColors.muted,
                      size: 34,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Pesquise um produto para começar o pedido.',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  ],
                ),
              )
            else
              _OrderItems(controller: controller, order: order),
          ],
        ),
      );
    });
  }
}

class _OrderItems extends StatelessWidget {
  const _OrderItems({required this.controller, required this.order});
  final OrdersController controller;
  final OrderDetail order;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 720) {
          return Column(
            children: [
              for (var index = 0; index < order.items.length; index++) ...[
                _MobileOrderItem(
                  item: order.items[index],
                  index: index,
                  controller: controller,
                  editable: order.permissions.canEdit,
                ),
                if (index < order.items.length - 1) const SizedBox(height: 9),
              ],
            ],
          );
        }
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Produto')),
              DataColumn(label: Text('Quantidade')),
              DataColumn(label: Text('Preço tabela')),
              DataColumn(label: Text('Desconto')),
              DataColumn(label: Text('Subtotal')),
              DataColumn(label: SizedBox.shrink()),
            ],
            rows: [
              for (var index = 0; index < order.items.length; index++)
                _itemRow(order.items[index], index),
            ],
          ),
        );
      },
    );
  }

  DataRow _itemRow(OrderLineItem item, int index) {
    final editable = order.permissions.canEdit;
    return DataRow(
      cells: [
        DataCell(
          SizedBox(
            width: 240,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  '${item.code} · ${item.unit}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 10),
                ),
              ],
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: 110,
            child: TextFormField(
              key: ValueKey('quantity-${item.productId}'),
              initialValue: orderQuantity(item.quantity),
              enabled: editable,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (value) => controller.updateItem(
                index,
                quantity: _parseNumber(value),
              ),
              decoration: const InputDecoration(isDense: true),
            ),
          ),
        ),
        DataCell(Text(orderCurrency(item.listPrice))),
        DataCell(
          SizedBox(
            width: 100,
            child: TextFormField(
              key: ValueKey('discount-${item.productId}'),
              initialValue: item.discountPercent.toStringAsFixed(1),
              enabled: editable,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (value) => controller.updateItem(
                index,
                discountPercent: _parseNumber(value),
              ),
              decoration: const InputDecoration(suffixText: '%', isDense: true),
            ),
          ),
        ),
        DataCell(
          Text(
            orderCurrency(item.subtotal),
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        DataCell(
          IconButton(
            tooltip: 'Remover produto',
            onPressed: editable ? () => controller.removeItem(index) : null,
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ),
      ],
    );
  }
}

class _MobileOrderItem extends StatelessWidget {
  const _MobileOrderItem({
    required this.item,
    required this.index,
    required this.controller,
    required this.editable,
  });
  final OrderLineItem item;
  final int index;
  final OrdersController controller;
  final bool editable;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    Text(
                      '${item.code} · ${item.unit}',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: editable ? () => controller.removeItem(index) : null,
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                '${item.unit} · ${orderCurrency(item.netPrice)} por unidade',
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                orderCurrency(item.subtotal),
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  key: ValueKey('mobile-quantity-${item.productId}'),
                  initialValue: orderQuantity(item.quantity),
                  enabled: editable,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (value) => controller.updateItem(
                    index,
                    quantity: _parseNumber(value),
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Quantidade',
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  key: ValueKey('mobile-discount-${item.productId}'),
                  initialValue: item.discountPercent.toStringAsFixed(1),
                  enabled: editable,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (value) => controller.updateItem(
                    index,
                    discountPercent: _parseNumber(value),
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Desconto',
                    suffixText: '%',
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailsSection extends StatelessWidget {
  const _DetailsSection({
    required this.controller,
    required this.shippingController,
    required this.trackingController,
    required this.addressController,
    required this.contactController,
    required this.notesController,
  });

  final OrdersController controller;
  final TextEditingController shippingController;
  final TextEditingController trackingController;
  final TextEditingController addressController;
  final TextEditingController contactController;
  final TextEditingController notesController;

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final order = controller.editingOrder.value!;
      final options = controller.formOptions.value;
      final editable = order.permissions.canEdit;
      final paymentTerms = <OrderSelectOption>[
        ...?options?.paymentTerms,
      ];
      if (order.paymentTerm != null &&
          !paymentTerms.any((item) => item.id == order.paymentTerm!.id)) {
        paymentTerms.add(order.paymentTerm!);
      }
      final carriers = <OrderSelectOption>[...?options?.carriers];
      if (order.carrier != null &&
          !carriers.any((item) => item.id == order.carrier!.id)) {
        carriers.add(order.carrier!);
      }
      return OrderSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const OrderSectionTitle(
              icon: Icons.tune_rounded,
              title: 'Detalhes do pedido',
              description: 'Pagamento, entrega, transporte e observações.',
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth < 700 ? 1 : 2;
                final width = columns == 1
                    ? constraints.maxWidth
                    : (constraints.maxWidth - 12) / 2;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: width,
                      child: DropdownButtonFormField<String>(
                        value: order.paymentTerm?.id,
                        decoration:
                            const InputDecoration(labelText: 'Pagamento *'),
                        items: [
                          for (final item in paymentTerms)
                            DropdownMenuItem(
                              value: item.id,
                              child: Text(item.label),
                            ),
                        ],
                        onChanged: !editable
                            ? null
                            : (id) {
                                final matches = paymentTerms
                                    .where((item) => item.id == id);
                                controller.updateDetails(
                                  paymentTerm:
                                      matches.isEmpty ? null : matches.first,
                                  clearPaymentTerm: id == null,
                                );
                              },
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: TextField(
                        controller: shippingController,
                        enabled: editable,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (value) => controller.updateDetails(
                          shippingCost: _parseNumber(value),
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Valor do frete',
                          prefixText: 'R\$ ',
                        ),
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: DropdownButtonFormField<String>(
                        value: order.carrier?.id,
                        decoration:
                            const InputDecoration(labelText: 'Transportadora'),
                        items: [
                          for (final item in carriers)
                            DropdownMenuItem(
                              value: item.id,
                              child: Text(item.label),
                            ),
                        ],
                        onChanged: !editable
                            ? null
                            : (id) {
                                final matches =
                                    carriers.where((item) => item.id == id);
                                controller.updateDetails(
                                  carrier: matches.isEmpty ? null : matches.first,
                                  clearCarrier: id == null,
                                );
                              },
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: TextField(
                        controller: trackingController,
                        enabled: editable,
                        onChanged: (value) =>
                            controller.updateDetails(trackingCode: value),
                        decoration:
                            const InputDecoration(labelText: 'Rastreamento'),
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: OutlinedButton.icon(
                        onPressed: editable
                            ? () => _pickDeliveryDate(context, order)
                            : null,
                        icon: const Icon(Icons.event_outlined),
                        label: Text(
                          order.expectedDeliveryDate == null
                              ? 'Previsão de entrega'
                              : 'Entrega: ${orderDate(order.expectedDeliveryDate)}',
                        ),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(56),
                          alignment: Alignment.centerLeft,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: TextField(
                        controller: contactController,
                        enabled: editable,
                        onChanged: (value) =>
                            controller.updateDetails(customerContact: value),
                        decoration:
                            const InputDecoration(labelText: 'Contato no cliente'),
                      ),
                    ),
                    SizedBox(
                      width: constraints.maxWidth,
                      child: TextField(
                        controller: addressController,
                        enabled: editable,
                        onChanged: (value) =>
                            controller.updateDetails(deliveryAddress: value),
                        decoration:
                            const InputDecoration(labelText: 'Endereço de entrega'),
                      ),
                    ),
                    SizedBox(
                      width: constraints.maxWidth,
                      child: TextField(
                        controller: notesController,
                        enabled: editable,
                        minLines: 3,
                        maxLines: 6,
                        onChanged: (value) =>
                            controller.updateDetails(notes: value),
                        decoration: const InputDecoration(
                          labelText: 'Informações adicionais',
                          alignLabelWithHint: true,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      );
    });
  }

  Future<void> _pickDeliveryDate(
    BuildContext context,
    OrderDetail order,
  ) async {
    final now = DateTime.now();
    final value = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: DateTime(now.year + 3),
      initialDate: order.expectedDeliveryDate ?? now,
      helpText: 'Previsão de entrega',
    );
    if (value != null) controller.updateDetails(expectedDeliveryDate: value);
  }
}

class _OrderSummaryCard extends StatelessWidget {
  const _OrderSummaryCard({
    required this.controller,
    required this.onPreview,
    required this.onConfirm,
  });

  final OrdersController controller;
  final VoidCallback onPreview;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final order = controller.editingOrder.value!;
      final busy = controller.saving.value || controller.actionLoading.value;
      return OrderSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resumo do pedido',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 16),
            _SummaryLine(
              label: 'Produtos',
              value: orderCurrency(order.totals.itemsSubtotal),
            ),
            _SummaryLine(
              label: 'Descontos',
              value: '- ${orderCurrency(order.totals.discountTotal)}',
            ),
            _SummaryLine(
              label: 'Frete',
              value: orderCurrency(order.totals.shippingCost),
            ),
            const Divider(height: 24),
            _SummaryLine(
              label: 'Total',
              value: orderCurrency(order.totals.grandTotal),
              strong: true,
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: busy ||
                        !order.permissions.canConfirm ||
                        order.status != 'draft'
                    ? null
                    : onConfirm,
                icon: controller.actionLoading.value
                    ? const SizedBox.square(
                        dimension: 17,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.task_alt_rounded),
                label: const Text('Gerar pedido'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppColors.navy,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: busy ? null : onPreview,
                icon: const Icon(Icons.visibility_outlined),
                label: const Text('Visualizar documento'),
              ),
            ),
            if (controller.lastSavedAt.value != null) ...[
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'Salvo às ${_time(controller.lastSavedAt.value!)}',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 10.5,
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  String _time(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({
    required this.label,
    required this.value,
    this.strong = false,
  });
  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: strong ? AppColors.ink : AppColors.muted,
              fontWeight: strong ? FontWeight.w900 : FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: AppColors.ink,
              fontSize: strong ? 19 : 12,
              fontWeight: strong ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({
    required this.label,
    required this.value,
    required this.detail,
  });
  final String label;
  final String value;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: .5,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value.isEmpty ? '—' : value,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (detail.isNotEmpty)
            Text(
              detail,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.muted, fontSize: 10.5),
            ),
        ],
      ),
    );
  }
}

double _parseNumber(String value) {
  final trimmed = value.trim();
  final normalized = trimmed.contains(',')
      ? trimmed.replaceAll('.', '').replaceAll(',', '.')
      : trimmed;
  return double.tryParse(normalized) ?? 0;
}

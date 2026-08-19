import 'dart:async';

import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';
import 'package:sistem_cormex/Src/Config/appColors.dart';
import 'package:sistem_cormex/Src/Models/logisticsModels.dart';
import 'package:sistem_cormex/Src/Pages/Logistics/Controller/logisticsController.dart';

Future<bool?> showCarrierEditorDialog(
  BuildContext context, {
  required LogisticsController controller,
  Carrier? carrier,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _CarrierEditorDialog(
      controller: controller,
      carrier: carrier,
    ),
  );
}

class _CarrierEditorDialog extends StatefulWidget {
  const _CarrierEditorDialog({required this.controller, this.carrier});

  final LogisticsController controller;
  final Carrier? carrier;

  @override
  State<_CarrierEditorDialog> createState() => _CarrierEditorDialogState();
}

class _CarrierEditorDialogState extends State<_CarrierEditorDialog> {
  late final TextEditingController nameController;
  late final TextEditingController documentController;
  late final TextEditingController phoneController;
  late final TextEditingController emailController;
  late final TextEditingController websiteController;
  late final TextEditingController trackingUrlController;
  late final TextEditingController providerSlugController;
  late String provider;
  late bool active;

  @override
  void initState() {
    super.initState();
    final carrier = widget.carrier;
    nameController = TextEditingController(text: carrier?.name ?? '');
    documentController = TextEditingController(text: carrier?.document ?? '');
    phoneController = TextEditingController(text: carrier?.phone ?? '');
    emailController = TextEditingController(text: carrier?.email ?? '');
    websiteController = TextEditingController(text: carrier?.website ?? '');
    trackingUrlController = TextEditingController(
      text: carrier?.trackingUrlTemplate ?? '',
    );
    providerSlugController = TextEditingController(
      text: carrier?.providerSlug ?? '',
    );
    provider = carrier?.provider ?? 'manual';
    active = carrier?.active ?? true;
  }

  @override
  void dispose() {
    nameController.dispose();
    documentController.dispose();
    phoneController.dispose();
    emailController.dispose();
    websiteController.dispose();
    trackingUrlController.dispose();
    providerSlugController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.carrier == null ? 'Nova transportadora' : 'Editar transportadora'),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Cadastre os dados da transportadora e defina como o rastreamento será consultado.',
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: nameController,
                maxLength: 120,
                decoration: const InputDecoration(
                  labelText: 'Nome da transportadora *',
                ),
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  final fields = [
                    TextField(
                      controller: documentController,
                      decoration: const InputDecoration(labelText: 'CNPJ'),
                    ),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Telefone'),
                    ),
                  ];
                  if (constraints.maxWidth < 480) {
                    return Column(
                      children: [
                        fields[0],
                        const SizedBox(height: 12),
                        fields[1],
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: fields[0]),
                      const SizedBox(width: 12),
                      Expanded(child: fields[1]),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'E-mail'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: websiteController,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(labelText: 'Site'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: provider,
                decoration: const InputDecoration(
                  labelText: 'Integração de rastreamento',
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'aftership',
                    child: Text('AfterShip — rastreamento automático'),
                  ),
                  DropdownMenuItem(
                    value: 'melhor_envio',
                    child: Text('Melhor Envio — etiquetas da plataforma'),
                  ),
                  DropdownMenuItem(
                    value: 'manual',
                    child: Text('Link personalizado'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => provider = value);
                },
              ),
              const SizedBox(height: 12),
              if (provider != 'manual')
                TextField(
                  controller: providerSlugController,
                  decoration: InputDecoration(
                    labelText: provider == 'aftership'
                        ? 'Código da transportadora no AfterShip'
                        : 'Código do serviço no Melhor Envio',
                    hintText: provider == 'aftership' ? 'Ex.: jadlog' : null,
                  ),
                )
              else
                TextField(
                  controller: trackingUrlController,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'URL de rastreamento',
                    hintText: 'https://transportadora.com/rastreio/{codigo}',
                    helperText: 'Use {codigo} no local em que o código deve aparecer.',
                  ),
                ),
              const SizedBox(height: 6),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: active,
                title: const Text(
                  'Transportadora ativa',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                onChanged: (value) => setState(() => active = value),
              ),
              Watch(
                (context) => widget.controller.error.value == null
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          widget.controller.error.value!,
                          style: const TextStyle(
                            color: AppColors.danger,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        Watch((context) {
          final saving = widget.controller.savingCarrier.value;
          return FilledButton.icon(
            onPressed: saving ? null : _save,
            icon: saving
                ? const SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined, size: 17),
            label: const Text('Salvar'),
          );
        }),
      ],
    );
  }

  Future<void> _save() async {
    final current = widget.carrier;
    final carrier = Carrier(
      id: current?.id,
      name: nameController.text,
      document: documentController.text,
      phone: phoneController.text,
      email: emailController.text,
      website: websiteController.text,
      trackingUrlTemplate: trackingUrlController.text,
      provider: provider,
      providerSlug: providerSlugController.text,
      active: active,
      supportsAutomaticTracking: provider != 'manual',
    );
    final saved = await widget.controller.saveCarrier(carrier);
    if (!mounted || saved == null) return;
    Navigator.pop(context, true);
  }
}

Future<bool?> showTrackingEditorDialog(
  BuildContext context, {
  required LogisticsController controller,
}) {
  controller.clearTrackingOrderSearch();
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _TrackingEditorDialog(controller: controller),
  );
}

class _TrackingEditorDialog extends StatefulWidget {
  const _TrackingEditorDialog({required this.controller});

  final LogisticsController controller;

  @override
  State<_TrackingEditorDialog> createState() => _TrackingEditorDialogState();
}

class _TrackingEditorDialogState extends State<_TrackingEditorDialog> {
  late final TextEditingController orderSearchController;
  late final TextEditingController trackingCodeController;
  Timer? debounce;
  TrackingOrderOption? selectedOrder;
  String? carrierId;
  DateTime? postedAt;
  DateTime? estimatedDeliveryAt;

  @override
  void initState() {
    super.initState();
    orderSearchController = TextEditingController();
    trackingCodeController = TextEditingController();
    final activeCarriers = widget.controller.carriers.value
        .where((carrier) => carrier.active && carrier.id != null)
        .toList();
    carrierId = activeCarriers.isEmpty ? null : activeCarriers.first.id;
  }

  @override
  void dispose() {
    debounce?.cancel();
    orderSearchController.dispose();
    trackingCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final carriers = widget.controller.carriers.value
        .where((carrier) => carrier.active && carrier.id != null)
        .toList();
    return AlertDialog(
      title: const Text('Adicionar rastreamento'),
      content: SizedBox(
        width: 620,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Vincule o código ao pedido para acompanhar a entrega dentro do Comerx.',
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              const SizedBox(height: 18),
              if (selectedOrder == null) ...[
                TextField(
                  controller: orderSearchController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Pedido *',
                    hintText: 'Pesquise pelo número ou cliente',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                  onChanged: (value) {
                    debounce?.cancel();
                    debounce = Timer(
                      const Duration(milliseconds: 400),
                      () => widget.controller.searchTrackingOrders(value),
                    );
                  },
                ),
                Watch((context) {
                  final loading = widget.controller.trackingOrdersLoading.value;
                  final orders = widget.controller.trackingOrderResults.value;
                  if (loading) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (orders.isEmpty) return const SizedBox.shrink();
                  return Container(
                    constraints: const BoxConstraints(maxHeight: 190),
                    margin: const EdgeInsets.only(top: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: orders.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final order = orders[index];
                        return ListTile(
                          dense: true,
                          title: Text(
                            order.label,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: order.city.isEmpty
                              ? null
                              : Text(order.city, style: const TextStyle(fontSize: 10)),
                          onTap: () {
                            setState(() => selectedOrder = order);
                            widget.controller.clearTrackingOrderSearch();
                          },
                        );
                      },
                    ),
                  );
                }),
              ] else
                Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: AppColors.cyan.withOpacity(.08),
                    border: Border.all(color: AppColors.cyan.withOpacity(.35)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.receipt_long_outlined, color: AppColors.cyan),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selectedOrder!.label,
                              style: const TextStyle(
                                color: AppColors.ink,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (selectedOrder!.city.isNotEmpty)
                              Text(
                                selectedOrder!.city,
                                style: const TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 10.5,
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Trocar pedido',
                        onPressed: () => setState(() => selectedOrder = null),
                        icon: const Icon(Icons.close_rounded, size: 18),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: carrierId,
                decoration: const InputDecoration(labelText: 'Transportadora *'),
                items: carriers
                    .map(
                      (carrier) => DropdownMenuItem(
                        value: carrier.id,
                        child: Text(carrier.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => carrierId = value),
              ),
              if (carriers.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 7),
                  child: Text(
                    'Cadastre uma transportadora ativa antes de adicionar o rastreamento.',
                    style: TextStyle(color: AppColors.danger, fontSize: 10.5),
                  ),
                ),
              const SizedBox(height: 14),
              TextField(
                controller: trackingCodeController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Código de rastreamento *',
                  hintText: 'Código informado pela transportadora',
                ),
              ),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, constraints) {
                  final posted = _DateField(
                    label: 'Data da postagem',
                    value: postedAt,
                    onTap: () => _pickDate(isEstimated: false),
                  );
                  final estimated = _DateField(
                    label: 'Previsão de entrega',
                    value: estimatedDeliveryAt,
                    onTap: () => _pickDate(isEstimated: true),
                  );
                  if (constraints.maxWidth < 460) {
                    return Column(
                      children: [posted, const SizedBox(height: 12), estimated],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: posted),
                      const SizedBox(width: 12),
                      Expanded(child: estimated),
                    ],
                  );
                },
              ),
              Watch(
                (context) => widget.controller.error.value == null
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          widget.controller.error.value!,
                          style: const TextStyle(
                            color: AppColors.danger,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        Watch((context) {
          final saving = widget.controller.savingTracking.value;
          return FilledButton.icon(
            onPressed: saving || carriers.isEmpty ? null : _save,
            icon: saving
                ? const SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add_location_alt_outlined, size: 17),
            label: const Text('Adicionar'),
          );
        }),
      ],
    );
  }

  Future<void> _pickDate({required bool isEstimated}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isEstimated
          ? estimatedDeliveryAt ?? DateTime.now().add(const Duration(days: 5))
          : postedAt ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isEstimated) {
        estimatedDeliveryAt = picked;
      } else {
        postedAt = picked;
      }
    });
  }

  Future<void> _save() async {
    final order = selectedOrder;
    final result = await widget.controller.saveTracking({
      'orderId': order?.id,
      'carrierId': carrierId,
      'trackingCode': trackingCodeController.text.trim().toUpperCase(),
      'postedAt': postedAt?.toUtc().toIso8601String(),
      'estimatedDeliveryAt': estimatedDeliveryAt?.toUtc().toIso8601String(),
    });
    if (!mounted || result == null) return;
    Navigator.pop(context, true);
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.label, required this.value, required this.onTap});

  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
        ),
        child: Text(value == null
            ? 'Selecionar'
            : '${value!.day.toString().padLeft(2, '0')}/${value!.month.toString().padLeft(2, '0')}/${value!.year}'),
      ),
    );
  }
}

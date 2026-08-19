import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';
import 'package:sistem_cormex/Src/Config/appColors.dart';
import 'package:sistem_cormex/Src/Models/orderModels.dart';
import 'package:sistem_cormex/Src/Pages/Orders/Components/orderCommon.dart';
import 'package:sistem_cormex/Src/Pages/Orders/Controller/ordersController.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

Future<void> showOrderPreviewDialog(
  BuildContext context,
  OrdersController controller,
) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _OrderPreviewDialog(controller: controller),
  );
}

class _OrderPreviewDialog extends StatelessWidget {
  const _OrderPreviewDialog({required this.controller});
  final OrdersController controller;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    return Dialog(
      insetPadding: EdgeInsets.all(screen.width < 650 ? 8 : 20),
      child: SizedBox(
        width: screen.width > 1120 ? 1060 : screen.width - 40,
        height: screen.height > 850 ? 800 : screen.height - 40,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 8, 10),
              child: Row(
                children: [
                  const Icon(
                    Icons.receipt_long_outlined,
                    color: AppColors.cyan,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Visualizar pedido',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
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
            _PreviewActions(controller: controller),
            const Divider(height: 1),
            Expanded(
              child: Watch((context) {
                final loading = controller.previewLoading.value;
                final error = controller.previewError.value;
                final preview = controller.preview.value;
                if (loading && preview == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (preview == null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: OrderInlineError(
                        message: error ?? 'A prévia não está disponível.',
                        onRetry: controller.loadPreview,
                      ),
                    ),
                  );
                }
                return Column(
                  children: [
                    if (error != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: OrderInlineError(message: error),
                      ),
                    Expanded(child: _OrderDocument(preview: preview)),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewActions extends StatelessWidget {
  const _PreviewActions({required this.controller});
  final OrdersController controller;

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final documentLoading = controller.documentLoading.value;
      final emailSending = controller.emailSending.value;
      final permissions = controller.preview.value?.order.permissions ??
          controller.editingOrder.value?.permissions ??
          OrderPermissions.all;
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (permissions.canDownloadPdf)
                FilledButton.icon(
                  onPressed: documentLoading
                      ? null
                      : () => _generateAndOpenPdf(context, controller),
                  icon: documentLoading
                      ? const SizedBox.square(
                          dimension: 17,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.picture_as_pdf_outlined, size: 18),
                  label: Text(
                    documentLoading ? 'Gerando PDF…' : 'Baixar PDF',
                  ),
                ),
              if (permissions.canSendEmail)
                OutlinedButton.icon(
                  onPressed: emailSending
                      ? null
                      : () => showOrderEmailDialog(context, controller),
                  icon: emailSending
                      ? const SizedBox.square(
                          dimension: 17,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.mail_outline_rounded, size: 18),
                  label: const Text('Enviar por e-mail'),
                ),
              OutlinedButton.icon(
                onPressed: documentLoading
                    ? null
                    : () => _generateAndOpenPdf(context, controller),
                icon: const Icon(Icons.print_outlined, size: 18),
                label: const Text('Abrir para imprimir'),
              ),
            ],
          ),
        ),
      );
    });
  }
}

Future<void> _generateAndOpenPdf(
  BuildContext context,
  OrdersController controller,
) async {
  final job = await controller.generatePdf();
  final url = job?.downloadUrl;
  if (job?.status != 'ready' || url == null) return;
  final uri = Uri.tryParse(url);
  final opened = uri != null &&
      await url_launcher.launchUrl(
        uri,
        mode: url_launcher.LaunchMode.externalApplication,
      );
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Não foi possível abrir o PDF.')),
    );
  }
}

Future<void> showOrderEmailDialog(
  BuildContext context,
  OrdersController controller,
) async {
  final pageMessenger = ScaffoldMessenger.maybeOf(context);
  final preview = controller.preview.value;
  if (preview == null) return;
  final order = preview.order;
  final recipientController = TextEditingController(
    text: preview.defaultEmail.isNotEmpty
        ? preview.defaultEmail
        : order.customer?.email ?? '',
  );
  final subjectController = TextEditingController(
    text: '${preview.documentTitle} #${order.number}',
  );
  final messageController = TextEditingController(
    text: 'Olá, segue em anexo o pedido #${order.number}.',
  );

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Enviar pedido por e-mail'),
      content: Watch((watchContext) {
        final error = controller.previewError.value;
        return SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: recipientController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Destinatário',
                  prefixIcon: Icon(Icons.alternate_email_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: subjectController,
                decoration: const InputDecoration(labelText: 'Assunto'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: messageController,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(labelText: 'Mensagem'),
              ),
              const SizedBox(height: 10),
              const Row(
                children: [
                  Icon(
                    Icons.attach_file_rounded,
                    size: 16,
                    color: AppColors.muted,
                  ),
                  SizedBox(width: 5),
                  Text(
                    'O PDF será gerado e anexado pelo servidor.',
                    style: TextStyle(color: AppColors.muted, fontSize: 11),
                  ),
                ],
              ),
              if (error != null) ...[
                const SizedBox(height: 10),
                OrderInlineError(message: error),
              ],
            ],
          ),
        );
      }),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cancelar'),
        ),
        Watch((watchContext) {
          final sending = controller.emailSending.value;
          return FilledButton.icon(
            onPressed: sending
                ? null
                : () async {
                    final sent = await controller.sendOrderEmail(
                      recipient: recipientController.text,
                      subject: subjectController.text,
                      message: messageController.text,
                    );
                    if (sent && dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                      pageMessenger?.showSnackBar(
                        SnackBar(
                          content: Text(
                            'Pedido enviado para ${recipientController.text.trim()}.',
                          ),
                        ),
                      );
                    }
                  },
            icon: sending
                ? const SizedBox.square(
                    dimension: 17,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_rounded, size: 17),
            label: Text(sending ? 'Enviando…' : 'Enviar com PDF'),
          );
        }),
      ],
    ),
  );
  recipientController.dispose();
  subjectController.dispose();
  messageController.dispose();
}

class _OrderDocument extends StatelessWidget {
  const _OrderDocument({required this.preview});
  final OrderPreview preview;

  @override
  Widget build(BuildContext context) {
    final order = preview.order;
    return Scrollbar(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 860),
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.border),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.navy,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(
                        Icons.trending_up_rounded,
                        color: AppColors.lime,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.representedCompany.name,
                            style: const TextStyle(
                              color: AppColors.ink,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            order.representedCompany.legalName,
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 10.5,
                            ),
                          ),
                          Text(
                            order.representedCompany.document,
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 10.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          preview.documentTitle.toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: .7,
                          ),
                        ),
                        Text(
                          '#${order.number}',
                          style: const TextStyle(
                            color: AppColors.navy,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        OrderStatusBadge(
                          status: order.status,
                          label: order.statusLabel,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 30,
                  runSpacing: 18,
                  children: [
                    _DocumentInfo(
                      label: 'CLIENTE',
                      value: order.customer?.displayName ?? '—',
                      detail: order.customer?.document ?? '',
                    ),
                    _DocumentInfo(
                      label: 'EMISSÃO',
                      value: orderDate(order.issueDate),
                      detail: 'Vendedor: ${order.sellerName}',
                    ),
                    _DocumentInfo(
                      label: 'PAGAMENTO',
                      value: order.paymentTerm?.label ?? '—',
                      detail: order.customerContact,
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                _DocumentItems(order: order),
                const SizedBox(height: 18),
                Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    width: 310,
                    child: Column(
                      children: [
                        _TotalLine(
                          label: 'Produtos',
                          value: orderCurrency(order.totals.itemsSubtotal),
                        ),
                        _TotalLine(
                          label: 'Descontos',
                          value: '- ${orderCurrency(order.totals.discountTotal)}',
                        ),
                        _TotalLine(
                          label: 'Frete',
                          value: orderCurrency(order.totals.shippingCost),
                        ),
                        const Divider(),
                        _TotalLine(
                          label: 'Total do pedido',
                          value: orderCurrency(order.totals.grandTotal),
                          strong: true,
                        ),
                      ],
                    ),
                  ),
                ),
                if (order.notes.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(13),
                    color: AppColors.canvas,
                    child: Text(
                      'Observações: ${order.notes}',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                ],
                if (preview.portalUrl != null) ...[
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.navy,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.storefront_outlined, color: AppColors.lime),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'O cliente pode acompanhar este pedido pelo Portal B2B.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DocumentItems extends StatelessWidget {
  const _DocumentItems({required this.order});
  final OrderDetail order;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: MaterialStateProperty.all(AppColors.field),
        columns: const [
          DataColumn(label: Text('Código')),
          DataColumn(label: Text('Produto')),
          DataColumn(label: Text('Qtd.')),
          DataColumn(label: Text('Preço')),
          DataColumn(label: Text('Desc.')),
          DataColumn(label: Text('Subtotal')),
        ],
        rows: [
          for (final item in order.items)
            DataRow(
              cells: [
                DataCell(Text(item.code)),
                DataCell(SizedBox(width: 220, child: Text(item.name))),
                DataCell(Text('${orderQuantity(item.quantity)} ${item.unit}')),
                DataCell(Text(orderCurrency(item.listPrice))),
                DataCell(Text('${item.discountPercent.toStringAsFixed(1)}%')),
                DataCell(Text(orderCurrency(item.subtotal))),
              ],
            ),
        ],
      ),
    );
  }
}

class _DocumentInfo extends StatelessWidget {
  const _DocumentInfo({
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
      width: 230,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: .5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (detail.isNotEmpty)
            Text(
              detail,
              style: const TextStyle(color: AppColors.muted, fontSize: 10),
            ),
        ],
      ),
    );
  }
}

class _TotalLine extends StatelessWidget {
  const _TotalLine({
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
      padding: const EdgeInsets.symmetric(vertical: 5),
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
              fontSize: strong ? 16 : 12,
              fontWeight: strong ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

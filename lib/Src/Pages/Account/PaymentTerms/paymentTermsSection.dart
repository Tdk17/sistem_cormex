import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';
import 'package:sistem_cormex/Src/Config/appColors.dart';
import 'package:sistem_cormex/Src/Models/accountModels.dart';
import 'package:sistem_cormex/Src/Pages/Account/Components/accountCommon.dart';
import 'package:sistem_cormex/Src/Pages/Account/Controller/accountController.dart';
import 'package:sistem_cormex/Src/Pages/Orders/Components/orderCommon.dart';

class PaymentTermsSection extends StatelessWidget {
  const PaymentTermsSection({
    super.key,
    required this.controller,
    required this.workspace,
  });

  final AccountController controller;
  final AccountWorkspace workspace;

  @override
  Widget build(BuildContext context) {
    if (workspace.company == null) {
      return const OrderSurface(
        child: AccountEmptyState(
          icon: Icons.apartment_rounded,
          title: 'Cadastre a empresa primeiro',
          message: 'As condições de pagamento pertencem à empresa e serão usadas nos pedidos.',
        ),
      );
    }
    return Watch((context) {
      final loading = controller.paymentTermsLoading.value;
      final terms = controller.paymentTerms.value;
      final error = controller.error.value;
      return Column(
        children: [
          if (!workspace.permissions.canManagePaymentTerms) ...[
            const AccountPermissionNotice(),
            const SizedBox(height: 14),
          ],
          OrderSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OrderSectionTitle(
                  icon: Icons.payments_outlined,
                  title: 'Condições de pagamento',
                  description: 'Opções disponíveis ao criar ou editar um pedido.',
                  trailing: workspace.permissions.canManagePaymentTerms
                      ? FilledButton.icon(
                          onPressed: () => _edit(context),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Nova condição'),
                          style: FilledButton.styleFrom(backgroundColor: AppColors.navy),
                        )
                      : null,
                ),
                const SizedBox(height: 20),
                if (loading && terms.isEmpty)
                  const Padding(padding: EdgeInsets.all(45), child: Center(child: CircularProgressIndicator()))
                else if (terms.isEmpty)
                  AccountEmptyState(
                    icon: Icons.request_quote_outlined,
                    title: 'Nenhuma condição cadastrada',
                    message: error ?? 'Crie opções como À vista, 28 dias ou 28/35/42.',
                  )
                else ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
                    child: const Row(children: [
                      Expanded(child: Text('DESCRIÇÃO', style: TextStyle(color: AppColors.muted, fontSize: 11, fontWeight: FontWeight.w900))),
                      SizedBox(width: 110, child: Text('PARCELAS', style: TextStyle(color: AppColors.muted, fontSize: 11, fontWeight: FontWeight.w900))),
                      SizedBox(width: 90),
                    ]),
                  ),
                  ...terms.map((term) => _TermRow(
                        term: term,
                        canManage: workspace.permissions.canManagePaymentTerms,
                        onEdit: () => _edit(context, term: term),
                        onDelete: () => _delete(context, term),
                      )),
                ],
                if (error != null && terms.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  OrderInlineError(message: error, onRetry: controller.loadPaymentTerms),
                ],
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.canvas, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                  child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Icon(Icons.info_outline_rounded, color: AppColors.cyan),
                    SizedBox(width: 10),
                    Expanded(child: Text('O vendedor também poderá informar uma condição livre no pedido. Uma condição já usada não deve ser apagada: a API retornará o erro 9306 e ela poderá apenas ser desativada.')),
                  ]),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }

  Future<void> _edit(BuildContext context, {PaymentTerm? term}) async {
    final label = TextEditingController(text: term?.label ?? '');
    final installments = TextEditingController(text: (term?.installments ?? 1).toString());
    var active = term?.active ?? true;
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(term == null ? 'Nova condição de pagamento' : 'Editar condição'),
          content: SizedBox(
            width: 470,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: label, autofocus: true, decoration: const InputDecoration(labelText: 'Descrição', hintText: 'Ex.: 28/35/42')),
              const SizedBox(height: 11),
              TextField(controller: installments, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Número de parcelas')),
              const SizedBox(height: 6),
              SwitchListTile.adaptive(contentPadding: EdgeInsets.zero, title: const Text('Disponível nos pedidos'), value: active, onChanged: (value) => setDialogState(() => active = value)),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancelar')),
            Watch((context) => FilledButton(
                  onPressed: controller.paymentTermActionLoading.value
                      ? null
                      : () async {
                          final value = PaymentTerm(id: term?.id, label: label.text, active: active, installments: int.tryParse(installments.text) ?? 1, usageCount: term?.usageCount ?? 0);
                          final ok = await controller.savePaymentTerm(value);
                          if (ok && dialogContext.mounted) {
                            Navigator.pop(dialogContext, true);
                          } else if (dialogContext.mounted) {
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              SnackBar(content: Text(controller.error.value ?? 'Não foi possível salvar a condição.')),
                            );
                          }
                        },
                  child: controller.paymentTermActionLoading.value
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Salvar'),
                )),
          ],
        ),
      ),
    );
    label.dispose();
    installments.dispose();
    if (saved == true && context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Condição de pagamento salva.')));
  }

  Future<void> _delete(BuildContext context, PaymentTerm term) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir condição?'),
        content: Text('Deseja excluir “${term.label}”? Se já houver pedidos vinculados, a API impedirá a exclusão.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), style: FilledButton.styleFrom(backgroundColor: AppColors.danger), child: const Text('Excluir')),
        ],
      ),
    );
    if (confirmed != true) return;
    final ok = await controller.deletePaymentTerm(term);
    if (ok && context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Condição excluída.')));
  }
}

class _TermRow extends StatelessWidget {
  const _TermRow({required this.term, required this.canManage, required this.onEdit, required this.onDelete});
  final PaymentTerm term;
  final bool canManage;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
      child: Row(children: [
        Expanded(child: Row(children: [
          Flexible(child: Text(term.label, style: TextStyle(fontWeight: FontWeight.w700, color: term.active ? AppColors.ink : AppColors.muted))),
          if (!term.active) const Padding(padding: EdgeInsets.only(left: 8), child: Chip(label: Text('Inativa'), visualDensity: VisualDensity.compact)),
        ])),
        SizedBox(width: 110, child: Text('${term.installments}x')),
        SizedBox(width: 90, child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          IconButton(onPressed: canManage ? onEdit : null, tooltip: 'Editar', icon: const Icon(Icons.edit_outlined, size: 19)),
          IconButton(onPressed: canManage ? onDelete : null, tooltip: 'Excluir', color: AppColors.danger, icon: const Icon(Icons.delete_outline_rounded, size: 19)),
        ])),
      ]),
    );
  }
}

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:signals/signals_flutter.dart';
import 'package:sistem_cormex/Src/Config/appColors.dart';
import 'package:sistem_cormex/Src/Models/accountModels.dart';
import 'package:sistem_cormex/Src/Pages/Account/Components/accountCommon.dart';
import 'package:sistem_cormex/Src/Pages/Account/Controller/accountController.dart';
import 'package:sistem_cormex/Src/Pages/Orders/Components/orderCommon.dart';
import 'package:sistem_cormex/Src/Routes/appRouter.dart';

class CompanySection extends StatelessWidget {
  const CompanySection({
    super.key,
    required this.controller,
    required this.workspace,
  });

  final AccountController controller;
  final AccountWorkspace workspace;

  @override
  Widget build(BuildContext context) {
    final company = workspace.company ?? CompanyProfile.empty(workspace.user);
    return Column(
      children: [
        if (workspace.setupRequired) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF071D2B), Color(0xFF0D3948)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.rocket_launch_outlined, color: AppColors.lime),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Última etapa para liberar o sistema', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                      SizedBox(height: 4),
                      Text('Cadastre a empresa. A API vinculará esta empresa e o vendedor responsável ao seu usuário.', style: TextStyle(color: Color(0xFFC8D5DA))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (!workspace.permissions.canManageCompany) ...[
          const AccountPermissionNotice(),
          const SizedBox(height: 14),
        ],
        _CompanyForm(
          key: ValueKey('${company.id}-${company.legalName}'),
          controller: controller,
          workspace: workspace,
          initial: company,
        ),
      ],
    );
  }
}

class _CompanyForm extends StatefulWidget {
  const _CompanyForm({
    super.key,
    required this.controller,
    required this.workspace,
    required this.initial,
  });

  final AccountController controller;
  final AccountWorkspace workspace;
  final CompanyProfile initial;

  @override
  State<_CompanyForm> createState() => _CompanyFormState();
}

class _CompanyFormState extends State<_CompanyForm> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController legalName;
  late final TextEditingController tradeName;
  late final TextEditingController document;
  late final TextEditingController email;
  late final TextEditingController phone;
  late final TextEditingController additionalInfo;
  late bool includeFreightInIpiBase;
  late bool commissionOnIpi;
  late bool commissionOnFreight;
  late bool stockControlEnabled;
  late String commissionSettlement;
  late List<CompanyContact> contacts;

  bool get canEdit => widget.workspace.permissions.canManageCompany || widget.workspace.setupRequired;

  @override
  void initState() {
    super.initState();
    final value = widget.initial;
    legalName = TextEditingController(text: value.legalName);
    tradeName = TextEditingController(text: value.tradeName);
    document = TextEditingController(text: value.document);
    email = TextEditingController(text: value.email);
    phone = TextEditingController(text: value.phone);
    additionalInfo = TextEditingController(text: value.additionalInfo);
    includeFreightInIpiBase = value.includeFreightInIpiBase;
    commissionOnIpi = value.commissionOnIpi;
    commissionOnFreight = value.commissionOnFreight;
    stockControlEnabled = value.stockControlEnabled;
    commissionSettlement = value.commissionSettlement;
    contacts = List<CompanyContact>.from(value.contacts);
  }

  @override
  void dispose() {
    legalName.dispose();
    tradeName.dispose();
    document.dispose();
    email.dispose();
    phone.dispose();
    additionalInfo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          OrderSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const OrderSectionTitle(
                  icon: Icons.apartment_rounded,
                  title: 'Dados da empresa',
                  description: 'Informações que aparecerão nos pedidos e documentos comerciais.',
                ),
                const SizedBox(height: 22),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final form = Column(
                      children: [
                        _responsiveFields(constraints.maxWidth, [
                          _CompanyField(controller: legalName, label: 'Razão social *', enabled: canEdit, validator: _required),
                          _CompanyField(controller: tradeName, label: 'Nome fantasia *', enabled: canEdit, validator: _required),
                          _CompanyField(controller: document, label: 'CPF/CNPJ *', enabled: canEdit, validator: _documentValidator),
                          _CompanyField(controller: phone, label: 'Telefone', enabled: canEdit, keyboardType: TextInputType.phone),
                          _CompanyField(controller: email, label: 'E-mail comercial', enabled: canEdit, keyboardType: TextInputType.emailAddress),
                        ]),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: additionalInfo,
                          enabled: canEdit,
                          minLines: 3,
                          maxLines: 5,
                          decoration: const InputDecoration(labelText: 'Informações adicionais'),
                        ),
                      ],
                    );
                    final logo = _LogoPicker(
                      controller: widget.controller,
                      logoUrl: widget.initial.logoUrl,
                      enabled: canEdit && widget.initial.isPersisted,
                    );
                    if (constraints.maxWidth < 820) {
                      return Column(children: [logo, const SizedBox(height: 20), form]);
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [Expanded(child: form), const SizedBox(width: 28), logo],
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          OrderSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const OrderSectionTitle(
                  icon: Icons.tune_rounded,
                  title: 'Regras da operação',
                  description: 'Defina impostos, comissão e estoque usados nos cálculos.',
                ),
                const SizedBox(height: 18),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Considerar o frete na base de cálculo do IPI'),
                  value: includeFreightInIpiBase,
                  onChanged: canEdit ? (value) => setState(() => includeFreightInIpiBase = value) : null,
                ),
                const Divider(),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Pagar comissão sobre IPI'),
                  value: commissionOnIpi,
                  onChanged: canEdit ? (value) => setState(() => commissionOnIpi = value) : null,
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Pagar comissão sobre frete'),
                  value: commissionOnFreight,
                  onChanged: canEdit ? (value) => setState(() => commissionOnFreight = value) : null,
                ),
                const SizedBox(height: 8),
                const Text('Liquidação da comissão', style: TextStyle(fontWeight: FontWeight.w800)),
                RadioListTile<String>(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Na liquidez do pedido'),
                  value: 'order_liquidity',
                  groupValue: commissionSettlement,
                  onChanged: canEdit ? (value) => setState(() => commissionSettlement = value!) : null,
                ),
                RadioListTile<String>(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Na parcela única'),
                  value: 'single_installment',
                  groupValue: commissionSettlement,
                  onChanged: canEdit ? (value) => setState(() => commissionSettlement = value!) : null,
                ),
                const Divider(),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Controle de estoque'),
                  subtitle: const Text('A disponibilidade também depende do plano contratado.'),
                  value: stockControlEnabled,
                  onChanged: canEdit ? (value) => setState(() => stockControlEnabled = value) : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          OrderSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OrderSectionTitle(
                  icon: Icons.contact_phone_outlined,
                  title: 'Contatos da empresa',
                  description: 'Pessoas responsáveis por compras, financeiro ou administração.',
                  trailing: canEdit
                      ? OutlinedButton.icon(onPressed: () => _openContact(), icon: const Icon(Icons.add_rounded), label: const Text('Adicionar'))
                      : null,
                ),
                const SizedBox(height: 16),
                if (contacts.isEmpty)
                  const AccountEmptyState(icon: Icons.person_add_alt_outlined, title: 'Nenhum contato', message: 'Adicione ao menos uma pessoa responsável pela empresa.')
                else
                  ...contacts.asMap().entries.map((entry) => _ContactRow(
                        contact: entry.value,
                        enabled: canEdit,
                        onEdit: () => _openContact(index: entry.key),
                        onDelete: () => setState(() => contacts.removeAt(entry.key)),
                      )),
              ],
            ),
          ),
          if (canEdit) ...[
            const SizedBox(height: 18),
            Watch((context) {
              final saving = widget.controller.saving.value;
              final error = widget.controller.error.value;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (error != null) ...[
                    OrderInlineError(message: error),
                    const SizedBox(height: 12),
                  ],
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: saving ? null : _save,
                      icon: saving
                          ? const SizedBox(width: 17, height: 17, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.save_outlined),
                      label: Text(widget.initial.isPersisted ? 'Salvar alterações' : 'Cadastrar empresa e continuar'),
                      style: FilledButton.styleFrom(backgroundColor: AppColors.navy, padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 17)),
                    ),
                  ),
                ],
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _responsiveFields(double width, List<Widget> children) {
    final fieldWidth = width < 620 ? width : (width - 12) / 2;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: children.map((child) => SizedBox(width: fieldWidth, child: child)).toList(),
    );
  }

  String? _required(String? value) => value == null || value.trim().length < 2 ? 'Campo obrigatório' : null;

  String? _documentValidator(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    return digits.length == 11 || digits.length == 14 ? null : 'Informe CPF ou CNPJ válido';
  }

  Future<void> _save() async {
    widget.controller.clearError();
    if (!(formKey.currentState?.validate() ?? false)) return;
    final wasSetup = widget.workspace.setupRequired;
    final value = widget.initial.copyWith(
      legalName: legalName.text,
      tradeName: tradeName.text,
      document: document.text,
      email: email.text,
      phone: phone.text,
      additionalInfo: additionalInfo.text,
      includeFreightInIpiBase: includeFreightInIpiBase,
      commissionOnIpi: commissionOnIpi,
      commissionOnFreight: commissionOnFreight,
      commissionSettlement: commissionSettlement,
      stockControlEnabled: stockControlEnabled,
      contacts: contacts,
    );
    final ok = await widget.controller.saveCompany(value);
    if (!mounted || !ok) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Empresa salva e vinculada à conta.')));
    if (wasSetup) context.go(AppRoutes.dashboard);
  }

  Future<void> _openContact({int? index}) async {
    final current = index == null ? null : contacts[index];
    final name = TextEditingController(text: current?.name ?? '');
    final position = TextEditingController(text: current?.position ?? '');
    final phone = TextEditingController(text: current?.phone ?? '');
    final email = TextEditingController(text: current?.email ?? '');
    final result = await showDialog<CompanyContact>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(index == null ? 'Novo contato' : 'Editar contato'),
        content: SizedBox(
          width: 470,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: name, decoration: const InputDecoration(labelText: 'Nome')),
              const SizedBox(height: 10),
              TextField(controller: position, decoration: const InputDecoration(labelText: 'Cargo')),
              const SizedBox(height: 10),
              TextField(controller: phone, decoration: const InputDecoration(labelText: 'Telefone')),
              const SizedBox(height: 10),
              TextField(controller: email, decoration: const InputDecoration(labelText: 'E-mail')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              if (name.text.trim().isEmpty) return;
              Navigator.pop(dialogContext, CompanyContact(id: current?.id, name: name.text, position: position.text, phone: phone.text, email: email.text));
            },
            child: const Text('Salvar contato'),
          ),
        ],
      ),
    );
    name.dispose();
    position.dispose();
    phone.dispose();
    email.dispose();
    if (result == null || !mounted) return;
    setState(() {
      if (index == null) {
        contacts.add(result);
      } else {
        contacts[index] = result;
      }
    });
  }
}

class _CompanyField extends StatelessWidget {
  const _CompanyField({required this.controller, required this.label, required this.enabled, this.validator, this.keyboardType});
  final TextEditingController controller;
  final String label;
  final bool enabled;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) => TextFormField(controller: controller, enabled: enabled, validator: validator, keyboardType: keyboardType, decoration: InputDecoration(labelText: label));
}

class _LogoPicker extends StatelessWidget {
  const _LogoPicker({required this.controller, required this.logoUrl, required this.enabled});
  final AccountController controller;
  final String? logoUrl;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      child: Column(
        children: [
          Container(
            width: 132,
            height: 132,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(color: AppColors.field, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border)),
            child: logoUrl == null
                ? const Icon(Icons.add_photo_alternate_outlined, size: 44, color: AppColors.muted)
                : Image.network(logoUrl!, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined, color: AppColors.muted)),
          ),
          const SizedBox(height: 10),
          Watch((context) => OutlinedButton.icon(
                onPressed: !enabled || controller.logoUploading.value ? null : () => _pick(context),
                icon: controller.logoUploading.value
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.upload_outlined, size: 18),
                label: const Text('Alterar logo'),
              )),
          if (!enabled) const Padding(padding: EdgeInsets.only(top: 5), child: Text('Salve a empresa antes de enviar a logo.', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: AppColors.muted))),
        ],
      ),
    );
  }

  Future<void> _pick(BuildContext context) async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1400, imageQuality: 88);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (bytes.length > 2 * 1024 * 1024) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('A imagem deve ter no máximo 2 MB.')));
      return;
    }
    final lower = file.name.toLowerCase();
    final mime = file.mimeType ?? (lower.endsWith('.png') ? 'image/png' : lower.endsWith('.webp') ? 'image/webp' : 'image/jpeg');
    final ok = await controller.uploadLogo(mimeType: mime, base64: base64Encode(bytes));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Logo atualizada.' : controller.error.value ?? 'Não foi possível enviar a logo.')),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({required this.contact, required this.enabled, required this.onEdit, required this.onDelete});
  final CompanyContact contact;
  final bool enabled;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(color: AppColors.canvas, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: AppColors.navy, foregroundColor: AppColors.lime, child: Text(accountInitials(contact.name))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(contact.name, style: const TextStyle(fontWeight: FontWeight.w800)), Text([contact.position, contact.email, contact.phone].where((item) => item.isNotEmpty).join(' • '), style: const TextStyle(color: AppColors.muted, fontSize: 12))])),
          if (enabled) ...[
            IconButton(onPressed: onEdit, tooltip: 'Editar', icon: const Icon(Icons.edit_outlined)),
            IconButton(onPressed: onDelete, tooltip: 'Excluir', color: AppColors.danger, icon: const Icon(Icons.delete_outline_rounded)),
          ],
        ],
      ),
    );
  }
}

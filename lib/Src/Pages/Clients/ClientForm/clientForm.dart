import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals/signals_flutter.dart';
import 'package:sistem_cormex/Src/Config/appColors.dart';
import 'package:sistem_cormex/Src/Dependencies/dependencies.dart';
import 'package:sistem_cormex/Src/Models/clientModels.dart';
import 'package:sistem_cormex/Src/Pages/Clients/Controller/clientsController.dart';
import 'package:sistem_cormex/Src/Pages/Orders/Components/orderCommon.dart';
import 'package:sistem_cormex/Src/Routes/appRouter.dart';

class ClientFormPage extends StatefulWidget {
  const ClientFormPage({super.key, this.clientId});

  final String? clientId;

  @override
  State<ClientFormPage> createState() => _ClientFormPageState();
}

class _ClientFormPageState extends State<ClientFormPage> {
  late final ClientsController controller;

  @override
  void initState() {
    super.initState();
    controller = getIt<ClientsController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.initializeForm(widget.clientId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return OrdersScaffold(
      child: Watch((context) {
        final loading = controller.formLoading.value;
        final error = controller.formError.value;
        final options = controller.formOptions.value;
        final client = controller.editingClient.value;
        if (loading || (client == null && error == null)) {
          return const Center(child: CircularProgressIndicator());
        }
        if (client == null || options == null) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: OrderSurface(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.error_outline_rounded, size: 44, color: AppColors.danger),
                  const SizedBox(height: 12),
                  Text(error ?? 'Não foi possível abrir o cadastro.'),
                  const SizedBox(height: 14),
                  FilledButton.icon(onPressed: () => controller.initializeForm(widget.clientId), icon: const Icon(Icons.refresh_rounded), label: const Text('Tentar novamente')),
                ]),
              ),
            ),
          );
        }
        return _ClientEditor(
          key: ValueKey('${client.id}-${identityHashCode(client)}'),
          controller: controller,
          options: options,
          initial: client,
        );
      }),
    );
  }
}

class _ClientEditor extends StatefulWidget {
  const _ClientEditor({super.key, required this.controller, required this.options, required this.initial});

  final ClientsController controller;
  final ClientFormOptions options;
  final ClientDetail initial;

  @override
  State<_ClientEditor> createState() => _ClientEditorState();
}

class _ClientEditorState extends State<_ClientEditor> {
  final formKey = GlobalKey<FormState>();
  late String type;
  late final TextEditingController document;
  late final TextEditingController legalName;
  late final TextEditingController tradeName;
  late final TextEditingController stateRegistration;
  late final TextEditingController suframa;
  late final TextEditingController additionalInfo;
  late List<TextEditingController> phones;
  late List<TextEditingController> emails;
  late String? fiscalExceptionId;
  late String? segmentId;
  late String? networkId;
  late bool blocked;
  late final TextEditingController postalCode;
  late final TextEditingController street;
  late final TextEditingController number;
  late final TextEditingController complement;
  late final TextEditingController district;
  late final TextEditingController city;
  late String state;
  late List<ClientAddress> additionalAddresses;
  late List<ClientContact> contacts;

  bool get canEdit => widget.initial.isPersisted
      ? widget.options.permissions.canEdit
      : widget.options.permissions.canCreate;

  @override
  void initState() {
    super.initState();
    final value = widget.initial;
    type = value.type;
    document = TextEditingController(text: value.document);
    legalName = TextEditingController(text: value.legalName);
    tradeName = TextEditingController(text: value.tradeName);
    stateRegistration = TextEditingController(text: value.stateRegistration);
    suframa = TextEditingController(text: value.suframa);
    additionalInfo = TextEditingController(text: value.additionalInfo);
    phones = _controllers(value.phones);
    emails = _controllers(value.emails);
    fiscalExceptionId = value.fiscalExceptionId;
    segmentId = value.segmentId;
    networkId = value.networkId;
    blocked = value.blocked;
    final address = value.primaryAddress;
    postalCode = TextEditingController(text: address.postalCode);
    street = TextEditingController(text: address.street);
    number = TextEditingController(text: address.number);
    complement = TextEditingController(text: address.complement);
    district = TextEditingController(text: address.district);
    city = TextEditingController(text: address.city);
    state = address.state;
    additionalAddresses = List<ClientAddress>.from(value.additionalAddresses);
    contacts = List<ClientContact>.from(value.contacts);
  }

  List<TextEditingController> _controllers(List<String> values) {
    final source = values.isEmpty ? [''] : values;
    return source.map((value) => TextEditingController(text: value)).toList();
  }

  @override
  void dispose() {
    for (final controller in [document, legalName, tradeName, stateRegistration, suframa, additionalInfo, postalCode, street, number, complement, district, city, ...phones, ...emails]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Scrollbar(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 22, 18, 112),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1450),
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        OrdersPageHeader(
                          title: widget.initial.isPersisted ? 'Alterar cliente' : 'Novo cliente',
                          description: 'Preencha os dados comerciais, endereço e contatos.',
                          leading: IconButton.outlined(onPressed: () => context.go(AppRoutes.clients), icon: const Icon(Icons.arrow_back_rounded)),
                          actions: widget.initial.isPersisted
                              ? [Chip(label: Text(blocked ? 'Cliente bloqueado' : 'Cliente ativo'), avatar: Icon(blocked ? Icons.block_rounded : Icons.check_circle_outline_rounded, size: 17))]
                              : const [],
                        ),
                        const SizedBox(height: 18),
                        if (!canEdit) ...[const OrderInlineError(message: 'Você pode visualizar este cliente, mas não possui permissão para alterá-lo.'), const SizedBox(height: 14)],
                        _buildGeneral(),
                        const SizedBox(height: 16),
                        _buildPrimaryAddress(),
                        const SizedBox(height: 16),
                        _buildAdditionalAddresses(),
                        const SizedBox(height: 16),
                        _buildContacts(),
                        const SizedBox(height: 16),
                        if (widget.initial.isPersisted)
                          OrderSurface(
                            child: SwitchListTile.adaptive(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Bloquear cliente', style: TextStyle(fontWeight: FontWeight.w800)),
                              subtitle: const Text('O histórico será preservado, mas o cliente não poderá ser usado em novos pedidos.'),
                              value: blocked,
                              onChanged: canEdit ? (value) => setState(() => blocked = value) : null,
                            ),
                          ),
                        Watch((context) {
                          final error = widget.controller.formError.value;
                          return error == null ? const SizedBox.shrink() : Padding(padding: const EdgeInsets.only(top: 16), child: OrderInlineError(message: error));
                        }),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Align(alignment: Alignment.bottomCenter, child: _bottomBar()),
      ],
    );
  }

  Widget _buildGeneral() {
    return OrderSurface(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const OrderSectionTitle(icon: Icons.store_outlined, title: 'Dados do cliente', description: 'Informações fiscais e comerciais usadas nos pedidos.'),
        const SizedBox(height: 20),
        SegmentedButton<String>(
          segments: const [ButtonSegment(value: 'business', label: Text('Pessoa Jurídica'), icon: Icon(Icons.apartment_rounded)), ButtonSegment(value: 'individual', label: Text('Pessoa Física'), icon: Icon(Icons.person_outline_rounded))],
          selected: {type},
          onSelectionChanged: canEdit ? (value) => setState(() => type = value.first) : null,
        ),
        const SizedBox(height: 18),
        _FieldGrid(children: [
          TextFormField(controller: document, enabled: canEdit, keyboardType: TextInputType.number, validator: _documentValidator, decoration: InputDecoration(labelText: type == 'business' ? 'CNPJ *' : 'CPF *', hintText: 'Obrigatório')),
          TextFormField(controller: legalName, enabled: canEdit, validator: _required, decoration: InputDecoration(labelText: type == 'business' ? 'Razão social *' : 'Nome completo *', hintText: 'Obrigatório')),
          TextFormField(controller: tradeName, enabled: canEdit, decoration: InputDecoration(labelText: type == 'business' ? 'Nome fantasia' : 'Nome social')),
        ]),
        const SizedBox(height: 16),
        _MultiInput(
          label: 'Telefones *',
          controllers: phones,
          enabled: canEdit,
          keyboardType: TextInputType.phone,
          validator: _required,
          onAdd: () => setState(() => phones.add(TextEditingController())),
          onRemove: (index) => _removeController(phones, index),
        ),
        const SizedBox(height: 16),
        _MultiInput(
          label: 'E-mails *',
          controllers: emails,
          enabled: canEdit,
          keyboardType: TextInputType.emailAddress,
          validator: _emailValidator,
          onAdd: () => setState(() => emails.add(TextEditingController())),
          onRemove: (index) => _removeController(emails, index),
        ),
        const SizedBox(height: 16),
        _FieldGrid(children: [
          if (type == 'business') ...[
            TextFormField(controller: stateRegistration, enabled: canEdit, decoration: const InputDecoration(labelText: 'Inscrição estadual *', hintText: 'Obrigatório')),
            TextFormField(controller: suframa, enabled: canEdit, decoration: const InputDecoration(labelText: 'SUFRAMA')),
            _optionField('Exceção fiscal', fiscalExceptionId, widget.options.fiscalExceptions, (value) => setState(() => fiscalExceptionId = value)),
          ],
          _optionField('Segmento *', segmentId, widget.options.segments, (value) => setState(() => segmentId = value)),
          _optionField('Rede', networkId, widget.options.networks, (value) => setState(() => networkId = value)),
        ]),
        if (type == 'business')
          const Padding(padding: EdgeInsets.only(top: 7), child: Text('Clientes com SUFRAMA preenchido poderão receber a regra fiscal configurada pela API.', style: TextStyle(color: AppColors.muted, fontSize: 11.5))),
        const SizedBox(height: 16),
        TextFormField(controller: additionalInfo, enabled: canEdit, minLines: 3, maxLines: 6, decoration: const InputDecoration(labelText: 'Informações adicionais', hintText: 'Adicione observações importantes sobre este cliente.')),
      ]),
    );
  }

  Widget _buildPrimaryAddress() {
    return OrderSurface(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const OrderSectionTitle(icon: Icons.location_on_outlined, title: 'Endereço principal', description: 'Usado como endereço padrão nos pedidos.'),
        const SizedBox(height: 20),
        _FieldGrid(children: [
          Watch((context) => TextFormField(
                controller: postalCode,
                enabled: canEdit,
                keyboardType: TextInputType.number,
                validator: _postalValidator,
                decoration: InputDecoration(
                  labelText: 'CEP *',
                  hintText: 'Obrigatório',
                  suffixIcon: widget.controller.postalCodeLoading.value
                      ? const Padding(padding: EdgeInsets.all(14), child: CircularProgressIndicator(strokeWidth: 2))
                      : IconButton(onPressed: canEdit ? _lookupPostalCode : null, tooltip: 'Buscar CEP', icon: const Icon(Icons.search_rounded)),
                ),
                onFieldSubmitted: (_) => _lookupPostalCode(),
              )),
          TextFormField(controller: street, enabled: canEdit, validator: _required, decoration: const InputDecoration(labelText: 'Endereço *')),
          TextFormField(controller: number, enabled: canEdit, validator: _required, decoration: const InputDecoration(labelText: 'Número *')),
          TextFormField(controller: complement, enabled: canEdit, decoration: const InputDecoration(labelText: 'Complemento')),
          TextFormField(controller: district, enabled: canEdit, decoration: const InputDecoration(labelText: 'Bairro')),
          TextFormField(controller: city, enabled: canEdit, validator: _required, decoration: const InputDecoration(labelText: 'Cidade *')),
          _stateField(state, (value) => setState(() => state = value ?? '')),
        ]),
      ]),
    );
  }

  Widget _buildAdditionalAddresses() {
    return OrderSurface(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        OrderSectionTitle(
          icon: Icons.add_location_alt_outlined,
          title: 'Endereços adicionais',
          description: 'Filiais, depósitos ou locais alternativos de entrega.',
          trailing: canEdit ? OutlinedButton.icon(onPressed: () => _editAddress(), icon: const Icon(Icons.add_rounded), label: const Text('Adicionar endereço')) : null,
        ),
        if (additionalAddresses.isEmpty)
          const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Center(child: Text('Nenhum endereço adicional.', style: TextStyle(color: AppColors.muted))))
        else ...[
          const SizedBox(height: 15),
          ...additionalAddresses.asMap().entries.map((entry) {
            final address = entry.value;
            return _DataRowCard(
              icon: Icons.location_on_outlined,
              title: address.label.isEmpty ? 'Endereço ${entry.key + 1}' : address.label,
              subtitle: _addressText(address),
              enabled: canEdit,
              onEdit: () => _editAddress(index: entry.key),
              onDelete: () => setState(() => additionalAddresses.removeAt(entry.key)),
            );
          }),
        ],
      ]),
    );
  }

  Widget _buildContacts() {
    return OrderSurface(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        OrderSectionTitle(
          icon: Icons.contact_phone_outlined,
          title: 'Contatos',
          description: 'Compradores, gerentes, recepcionistas e responsáveis.',
          trailing: canEdit ? OutlinedButton.icon(onPressed: () => _editContact(), icon: const Icon(Icons.person_add_alt_rounded), label: const Text('Adicionar contato')) : null,
        ),
        if (contacts.isEmpty)
          const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Center(child: Text('Nenhum contato cadastrado.', style: TextStyle(color: AppColors.muted))))
        else ...[
          const SizedBox(height: 15),
          ...contacts.asMap().entries.map((entry) {
            final contact = entry.value;
            final details = [...contact.phones, ...contact.emails].where((item) => item.isNotEmpty).join(' • ');
            return _DataRowCard(
              icon: Icons.person_outline_rounded,
              title: contact.name,
              subtitle: [contact.position, details].where((item) => item.isNotEmpty).join(' — '),
              enabled: canEdit,
              onEdit: () => _editContact(index: entry.key),
              onDelete: () => setState(() => contacts.removeAt(entry.key)),
            );
          }),
        ],
      ]),
    );
  }

  Widget _bottomBar() {
    return Material(
      elevation: 12,
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))),
          child: Watch((context) {
            final saving = widget.controller.saving.value;
            return Wrap(spacing: 9, runSpacing: 9, children: [
              FilledButton(onPressed: !canEdit || saving ? null : () => _save(false), style: FilledButton.styleFrom(backgroundColor: AppColors.navy), child: saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Salvar')),
              if (!widget.initial.isPersisted)
                FilledButton.tonal(onPressed: !canEdit || saving ? null : () => _save(true), child: const Text('Salvar e cadastrar outro')),
              OutlinedButton(onPressed: saving ? null : () => context.go(AppRoutes.clients), child: const Text('Cancelar')),
            ]);
          }),
        ),
      ),
    );
  }

  Widget _optionField(String label, String? value, List<ClientOption> options, ValueChanged<String?> onChanged) {
    final validValue = options.any((item) => item.id == value) ? value : null;
    return DropdownButtonFormField<String>(
      value: validValue,
      decoration: InputDecoration(labelText: label),
      items: options.map((item) => DropdownMenuItem(value: item.id, child: Text(item.label))).toList(),
      onChanged: canEdit ? onChanged : null,
    );
  }

  Widget _stateField(String value, ValueChanged<String?> onChanged) {
    final states = widget.options.states.isEmpty ? _brazilStates : widget.options.states;
    final validValue = states.any((item) => item.id == value) ? value : null;
    return DropdownButtonFormField<String>(
      value: validValue,
      validator: (value) => value == null || value.isEmpty ? 'Campo obrigatório' : null,
      decoration: const InputDecoration(labelText: 'Estado *'),
      items: states.map((item) => DropdownMenuItem(value: item.id, child: Text(item.label))).toList(),
      onChanged: canEdit ? onChanged : null,
    );
  }

  String? _required(String? value) => value == null || value.trim().isEmpty ? 'Campo obrigatório' : null;
  String? _emailValidator(String? value) => value == null || !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value.trim()) ? 'E-mail inválido' : null;
  String? _documentValidator(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    return digits.length == (type == 'business' ? 14 : 11) ? null : (type == 'business' ? 'CNPJ inválido' : 'CPF inválido');
  }
  String? _postalValidator(String? value) => (value ?? '').replaceAll(RegExp(r'\D'), '').length == 8 ? null : 'CEP inválido';

  void _removeController(List<TextEditingController> values, int index) {
    if (values.length == 1) return;
    final removed = values.removeAt(index);
    removed.dispose();
    setState(() {});
  }

  Future<void> _lookupPostalCode() async {
    final address = await widget.controller.lookupPostalCode(postalCode.text);
    if (address == null || !mounted) return;
    setState(() {
      street.text = address.street;
      district.text = address.district;
      city.text = address.city;
      state = address.state;
    });
  }

  ClientDetail _value() {
    return ClientDetail(
      id: widget.initial.id,
      type: type,
      document: document.text,
      legalName: legalName.text,
      tradeName: tradeName.text,
      phones: phones.map((item) => item.text).toList(),
      emails: emails.map((item) => item.text).toList(),
      stateRegistration: stateRegistration.text,
      suframa: suframa.text,
      fiscalExceptionId: fiscalExceptionId,
      segmentId: segmentId,
      networkId: networkId,
      additionalInfo: additionalInfo.text,
      blocked: blocked,
      primaryAddress: ClientAddress(id: widget.initial.primaryAddress.id, label: 'Principal', postalCode: postalCode.text, street: street.text, number: number.text, complement: complement.text, district: district.text, city: city.text, state: state, primary: true),
      additionalAddresses: additionalAddresses,
      contacts: contacts,
    );
  }

  Future<void> _save(bool another) async {
    widget.controller.clearFormError();
    if (!(formKey.currentState?.validate() ?? false)) return;
    final saved = await widget.controller.saveClient(_value());
    if (!mounted || saved == null) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cliente salvo com sucesso.')));
    if (another) {
      widget.controller.prepareAnotherClient();
    } else {
      context.go(AppRoutes.clients);
    }
  }

  Future<void> _editAddress({int? index}) async {
    final result = await showDialog<ClientAddress>(
      context: context,
      builder: (_) => _AddressDialog(initial: index == null ? const ClientAddress.empty() : additionalAddresses[index], states: widget.options.states.isEmpty ? _brazilStates : widget.options.states),
    );
    if (result == null || !mounted) return;
    setState(() { if (index == null) additionalAddresses.add(result); else additionalAddresses[index] = result; });
  }

  Future<void> _editContact({int? index}) async {
    final result = await showDialog<ClientContact>(context: context, builder: (_) => _ContactDialog(initial: index == null ? null : contacts[index]));
    if (result == null || !mounted) return;
    setState(() { if (index == null) contacts.add(result); else contacts[index] = result; });
  }

  String _addressText(ClientAddress address) => '${address.street}, ${address.number}${address.complement.isEmpty ? '' : ' - ${address.complement}'} · ${address.district} · ${address.city}/${address.state} · ${address.postalCode}';
}

class _FieldGrid extends StatelessWidget {
  const _FieldGrid({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1050 ? 3 : constraints.maxWidth >= 650 ? 2 : 1;
        final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
        return Wrap(spacing: 12, runSpacing: 12, children: children.map((child) => SizedBox(width: width, child: child)).toList());
      });
}

class _MultiInput extends StatelessWidget {
  const _MultiInput({required this.label, required this.controllers, required this.enabled, required this.keyboardType, required this.validator, required this.onAdd, required this.onRemove});
  final String label;
  final List<TextEditingController> controllers;
  final bool enabled;
  final TextInputType keyboardType;
  final FormFieldValidator<String>? validator;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
        const SizedBox(height: 8),
        ...controllers.asMap().entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SizedBox(
                width: 480,
                child: TextFormField(controller: entry.value, enabled: enabled, keyboardType: keyboardType, validator: entry.key == 0 ? validator : null, decoration: InputDecoration(hintText: entry.key == 0 ? 'Obrigatório' : 'Opcional', suffixIcon: controllers.length > 1 ? IconButton(onPressed: enabled ? () => onRemove(entry.key) : null, icon: const Icon(Icons.close_rounded)) : null)),
              ),
            )),
        TextButton.icon(onPressed: enabled ? onAdd : null, icon: const Icon(Icons.add_rounded, size: 17), label: Text(label.startsWith('Telefone') ? 'Adicionar telefone' : 'Adicionar e-mail')),
      ]);
}

class _DataRowCard extends StatelessWidget {
  const _DataRowCard({required this.icon, required this.title, required this.subtitle, required this.enabled, required this.onEdit, required this.onDelete});
  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(color: AppColors.canvas, borderRadius: BorderRadius.circular(13), border: Border.all(color: AppColors.border)),
        child: Row(children: [Icon(icon, color: AppColors.cyan), const SizedBox(width: 11), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w800)), Text(subtitle, style: const TextStyle(color: AppColors.muted, fontSize: 12))])), if (enabled) IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_outlined)), if (enabled) IconButton(onPressed: onDelete, color: AppColors.danger, icon: const Icon(Icons.delete_outline_rounded))]),
      );
}

class _AddressDialog extends StatefulWidget {
  const _AddressDialog({required this.initial, required this.states});
  final ClientAddress initial;
  final List<ClientOption> states;
  @override
  State<_AddressDialog> createState() => _AddressDialogState();
}

class _AddressDialogState extends State<_AddressDialog> {
  late final List<TextEditingController> values;
  late String state;
  @override
  void initState() { super.initState(); final a = widget.initial; values = [a.label, a.postalCode, a.street, a.number, a.complement, a.district, a.city].map((item) => TextEditingController(text: item)).toList(); state = a.state; }
  @override
  void dispose() { for (final value in values) { value.dispose(); } super.dispose(); }
  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.initial.id == null ? 'Adicionar endereço' : 'Editar endereço'),
        content: SizedBox(width: 650, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: values[0], decoration: const InputDecoration(labelText: 'Identificação', hintText: 'Ex.: Filial ou Depósito')),
          const SizedBox(height: 10),
          TextField(controller: values[1], decoration: const InputDecoration(labelText: 'CEP *')),
          const SizedBox(height: 10),
          TextField(controller: values[2], decoration: const InputDecoration(labelText: 'Endereço *')),
          const SizedBox(height: 10),
          Row(children: [Expanded(child: TextField(controller: values[3], decoration: const InputDecoration(labelText: 'Número *'))), const SizedBox(width: 10), Expanded(child: TextField(controller: values[4], decoration: const InputDecoration(labelText: 'Complemento')))]),
          const SizedBox(height: 10),
          TextField(controller: values[5], decoration: const InputDecoration(labelText: 'Bairro')),
          const SizedBox(height: 10),
          Row(children: [Expanded(child: TextField(controller: values[6], decoration: const InputDecoration(labelText: 'Cidade *'))), const SizedBox(width: 10), Expanded(child: DropdownButtonFormField<String>(value: widget.states.any((item) => item.id == state) ? state : null, decoration: const InputDecoration(labelText: 'Estado *'), items: widget.states.map((item) => DropdownMenuItem(value: item.id, child: Text(item.label))).toList(), onChanged: (value) => setState(() => state = value ?? '')))]),
        ]))),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')), FilledButton(onPressed: _save, child: const Text('Salvar endereço'))],
      );
  void _save() { if (values[1].text.trim().isEmpty || values[2].text.trim().isEmpty || values[3].text.trim().isEmpty || values[6].text.trim().isEmpty || state.isEmpty) return; Navigator.pop(context, ClientAddress(id: widget.initial.id, label: values[0].text, postalCode: values[1].text, street: values[2].text, number: values[3].text, complement: values[4].text, district: values[5].text, city: values[6].text, state: state, primary: false)); }
}

class _ContactDialog extends StatefulWidget {
  const _ContactDialog({this.initial});
  final ClientContact? initial;
  @override
  State<_ContactDialog> createState() => _ContactDialogState();
}

class _ContactDialogState extends State<_ContactDialog> {
  late final TextEditingController name;
  late final TextEditingController position;
  late List<TextEditingController> phones;
  late List<TextEditingController> emails;
  @override
  void initState() { super.initState(); final value = widget.initial; name = TextEditingController(text: value?.name ?? ''); position = TextEditingController(text: value?.position ?? ''); phones = (value?.phones.isNotEmpty == true ? value!.phones : ['']).map((item) => TextEditingController(text: item)).toList(); emails = (value?.emails.isNotEmpty == true ? value!.emails : ['']).map((item) => TextEditingController(text: item)).toList(); }
  @override
  void dispose() { name.dispose(); position.dispose(); for (final value in [...phones, ...emails]) { value.dispose(); } super.dispose(); }
  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.initial == null ? 'Adicionar contato' : 'Editar contato'),
        content: SizedBox(width: 600, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          TextField(controller: name, decoration: const InputDecoration(labelText: 'Nome *')),
          const SizedBox(height: 10),
          TextField(controller: position, decoration: const InputDecoration(labelText: 'Cargo', hintText: 'Ex.: Gerente de compras ou Recepcionista')),
          const SizedBox(height: 14),
          const Text('Telefones', style: TextStyle(fontWeight: FontWeight.w800)),
          ...phones.asMap().entries.map((entry) => Padding(padding: const EdgeInsets.only(top: 8), child: TextField(controller: entry.value, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: 'Telefone ${entry.key + 1}', suffixIcon: phones.length > 1 ? IconButton(onPressed: () => _remove(phones, entry.key), icon: const Icon(Icons.close_rounded)) : null)))),
          TextButton.icon(onPressed: () => setState(() => phones.add(TextEditingController())), icon: const Icon(Icons.add_rounded), label: const Text('Adicionar telefone')),
          const SizedBox(height: 8),
          const Text('E-mails', style: TextStyle(fontWeight: FontWeight.w800)),
          ...emails.asMap().entries.map((entry) => Padding(padding: const EdgeInsets.only(top: 8), child: TextField(controller: entry.value, keyboardType: TextInputType.emailAddress, decoration: InputDecoration(labelText: 'E-mail ${entry.key + 1}', suffixIcon: emails.length > 1 ? IconButton(onPressed: () => _remove(emails, entry.key), icon: const Icon(Icons.close_rounded)) : null)))),
          TextButton.icon(onPressed: () => setState(() => emails.add(TextEditingController())), icon: const Icon(Icons.add_rounded), label: const Text('Adicionar e-mail')),
        ]))),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')), FilledButton(onPressed: _save, child: const Text('Salvar contato'))],
      );
  void _remove(List<TextEditingController> list, int index) { final value = list.removeAt(index); value.dispose(); setState(() {}); }
  void _save() { if (name.text.trim().isEmpty) return; Navigator.pop(context, ClientContact(id: widget.initial?.id, name: name.text, position: position.text, phones: phones.map((item) => item.text).toList(), emails: emails.map((item) => item.text).toList())); }
}

const _brazilStates = <ClientOption>[
  ClientOption(id: 'AC', label: 'Acre'), ClientOption(id: 'AL', label: 'Alagoas'), ClientOption(id: 'AP', label: 'Amapá'), ClientOption(id: 'AM', label: 'Amazonas'), ClientOption(id: 'BA', label: 'Bahia'), ClientOption(id: 'CE', label: 'Ceará'), ClientOption(id: 'DF', label: 'Distrito Federal'), ClientOption(id: 'ES', label: 'Espírito Santo'), ClientOption(id: 'GO', label: 'Goiás'), ClientOption(id: 'MA', label: 'Maranhão'), ClientOption(id: 'MT', label: 'Mato Grosso'), ClientOption(id: 'MS', label: 'Mato Grosso do Sul'), ClientOption(id: 'MG', label: 'Minas Gerais'), ClientOption(id: 'PA', label: 'Pará'), ClientOption(id: 'PB', label: 'Paraíba'), ClientOption(id: 'PR', label: 'Paraná'), ClientOption(id: 'PE', label: 'Pernambuco'), ClientOption(id: 'PI', label: 'Piauí'), ClientOption(id: 'RJ', label: 'Rio de Janeiro'), ClientOption(id: 'RN', label: 'Rio Grande do Norte'), ClientOption(id: 'RS', label: 'Rio Grande do Sul'), ClientOption(id: 'RO', label: 'Rondônia'), ClientOption(id: 'RR', label: 'Roraima'), ClientOption(id: 'SC', label: 'Santa Catarina'), ClientOption(id: 'SP', label: 'São Paulo'), ClientOption(id: 'SE', label: 'Sergipe'), ClientOption(id: 'TO', label: 'Tocantins'),
];

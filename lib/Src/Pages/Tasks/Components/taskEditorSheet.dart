import 'dart:async';

import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';
import 'package:sistem_cormex/Src/Config/appColors.dart';
import 'package:sistem_cormex/Src/Models/taskModels.dart';
import 'package:sistem_cormex/Src/Pages/Orders/Components/orderCommon.dart';
import 'package:sistem_cormex/Src/Pages/Tasks/Controller/tasksController.dart';

Future<bool?> showTaskEditorSheet(
  BuildContext context, {
  required TasksController controller,
  String? taskId,
  String entryKind = 'task',
}) {
  return showGeneralDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Fechar painel de tarefa',
    barrierColor: Colors.black38,
    transitionDuration: const Duration(milliseconds: 230),
    pageBuilder: (_, __, ___) => _TaskEditorSheet(
      controller: controller,
      taskId: taskId,
      entryKind: entryKind,
    ),
    transitionBuilder: (_, animation, __, child) {
      final offset = Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
      return SlideTransition(position: offset, child: child);
    },
  );
}

class _TaskEditorSheet extends StatefulWidget {
  const _TaskEditorSheet({
    required this.controller,
    required this.taskId,
    required this.entryKind,
  });

  final TasksController controller;
  final String? taskId;
  final String entryKind;

  @override
  State<_TaskEditorSheet> createState() => _TaskEditorSheetState();
}

class _TaskEditorSheetState extends State<_TaskEditorSheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.initializeForm(
        taskId: widget.taskId,
        entryKind: widget.entryKind,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return SafeArea(
      child: Align(
        alignment: Alignment.centerRight,
        child: Material(
          color: Colors.white,
          elevation: 24,
          child: SizedBox(
            width: width < 600 ? width : 470,
            height: double.infinity,
            child: Watch((context) {
              final loading = widget.controller.formLoading.value;
              final error = widget.controller.formError.value;
              final options = widget.controller.formOptions.value;
              final task = widget.controller.editingTask.value;
              if (loading || (task == null && error == null)) {
                return const Center(child: CircularProgressIndicator());
              }
              if (task == null || options == null) {
                return _TaskSheetFailure(
                  message: error ?? 'Não foi possível abrir a tarefa.',
                  onRetry: () => widget.controller.initializeForm(
                    taskId: widget.taskId,
                    entryKind: widget.entryKind,
                  ),
                );
              }
              return _TaskEditorForm(
                key: ValueKey('${task.id}-${identityHashCode(task)}'),
                controller: widget.controller,
                options: options,
                initial: task,
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _TaskEditorForm extends StatefulWidget {
  const _TaskEditorForm({
    super.key,
    required this.controller,
    required this.options,
    required this.initial,
  });

  final TasksController controller;
  final TaskFormOptions options;
  final TaskDetail initial;

  @override
  State<_TaskEditorForm> createState() => _TaskEditorFormState();
}

class _TaskEditorFormState extends State<_TaskEditorForm> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController client;
  late final TextEditingController subject;
  late final TextEditingController notes;
  late final TextEditingController date;
  late final TextEditingController time;
  late DateTime scheduledAt;
  late String contactMethod;
  late String assignedUserId;
  String? clientId;
  Timer? clientDebounce;

  bool get canEdit => widget.initial.isPersisted
      ? widget.options.permissions.canEdit
      : widget.initial.isActivity
          ? widget.options.permissions.canRegisterActivity
          : widget.options.permissions.canCreate;

  List<TaskOption> get contactMethods => widget.options.contactMethods.isEmpty
      ? _defaultContactMethods
      : widget.options.contactMethods;

  @override
  void initState() {
    super.initState();
    final value = widget.initial;
    client = TextEditingController(text: value.clientName);
    subject = TextEditingController(text: value.subject);
    notes = TextEditingController(text: value.notes);
    scheduledAt = value.scheduledAt;
    date = TextEditingController(text: _shortDate(scheduledAt));
    time = TextEditingController(text: _shortTime(scheduledAt));
    contactMethod = value.contactMethod;
    if (!contactMethods.any((item) => item.id == contactMethod) &&
        contactMethods.isNotEmpty) {
      contactMethod = contactMethods.first.id;
    }
    assignedUserId = value.assignedUserId;
    if (!widget.options.sellers.any((item) => item.id == assignedUserId) &&
        widget.options.sellers.isNotEmpty) {
      assignedUserId = widget.options.sellers.first.id;
    }
    clientId = value.clientId;
  }

  @override
  void dispose() {
    clientDebounce?.cancel();
    client.dispose();
    subject.dispose();
    notes.dispose();
    date.dispose();
    time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.initial.isPersisted
        ? (widget.initial.isActivity ? 'Editar atividade' : 'Editar tarefa')
        : (widget.initial.isActivity ? 'Registrar atividade' : 'Criar tarefa');
    return Column(
      children: [
        Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              Icon(
                widget.initial.isActivity
                    ? Icons.history_toggle_off_rounded
                    : Icons.task_alt_rounded,
                color: AppColors.cyan,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Fechar',
                onPressed: () => Navigator.pop(context, false),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ),
        Expanded(
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!canEdit) ...[
                    const OrderInlineError(
                      message: 'Você pode visualizar, mas não possui permissão para alterar.',
                    ),
                    const SizedBox(height: 16),
                  ],
                  _sectionLabel(
                    widget.initial.isActivity
                        ? 'DATA DA ATIVIDADE'
                        : 'DATA DA TAREFA',
                  ),
                  const SizedBox(height: 9),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          readOnly: true,
                          enabled: canEdit,
                          controller: date,
                          decoration: const InputDecoration(
                            labelText: 'Data *',
                            prefixIcon: Icon(Icons.calendar_today_outlined),
                          ),
                          onTap: _pickDate,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          readOnly: true,
                          enabled: canEdit,
                          controller: time,
                          decoration: const InputDecoration(
                            labelText: 'Horário *',
                            prefixIcon: Icon(Icons.schedule_rounded),
                          ),
                          onTap: _pickTime,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _sectionLabel('MEIO DE CONTATO'),
                  const SizedBox(height: 9),
                  DropdownButtonFormField<String>(
                    value: contactMethods.any((item) => item.id == contactMethod)
                        ? contactMethod
                        : null,
                    decoration: const InputDecoration(
                      labelText: 'Meio de contato *',
                      prefixIcon: Icon(Icons.forum_outlined),
                    ),
                    items: contactMethods
                        .map(
                          (item) => DropdownMenuItem(
                            value: item.id,
                            child: Text(item.label),
                          ),
                        )
                        .toList(),
                    onChanged: canEdit
                        ? (value) {
                            if (value != null) {
                              setState(() => contactMethod = value);
                            }
                          }
                        : null,
                  ),
                  const SizedBox(height: 18),
                  _sectionLabel('CLIENTE'),
                  const SizedBox(height: 9),
                  TextFormField(
                    controller: client,
                    enabled: canEdit,
                    validator: (_) => clientId == null ? 'Selecione o cliente' : null,
                    decoration: InputDecoration(
                      labelText: 'Selecione ou pesquise pelo nome *',
                      prefixIcon: const Icon(Icons.business_outlined),
                      suffixIcon: client.text.isEmpty
                          ? null
                          : IconButton(
                              onPressed: canEdit
                                  ? () {
                                      setState(() {
                                        client.clear();
                                        clientId = null;
                                      });
                                      widget.controller.clearClientResults();
                                    }
                                  : null,
                              icon: const Icon(Icons.close_rounded),
                            ),
                    ),
                    onChanged: _scheduleClientSearch,
                  ),
                  Watch((context) {
                    final loading = widget.controller.clientsLoading.value;
                    final clients = widget.controller.clientResults.value;
                    if (loading) {
                      return const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: LinearProgressIndicator(minHeight: 2),
                      );
                    }
                    if (clients.isEmpty) return const SizedBox.shrink();
                    return Container(
                      constraints: const BoxConstraints(maxHeight: 230),
                      margin: const EdgeInsets.only(top: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x14000000),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: clients.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, index) {
                          final item = clients[index];
                          return ListTile(
                            dense: true,
                            title: Text(
                              item.label,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            subtitle: item.city.isEmpty ? null : Text(item.city),
                            onTap: () => _selectClient(item),
                          );
                        },
                      ),
                    );
                  }),
                  const SizedBox(height: 18),
                  _sectionLabel('VENDEDOR RESPONSÁVEL'),
                  const SizedBox(height: 9),
                  DropdownButtonFormField<String>(
                    value: widget.options.sellers
                            .any((item) => item.id == assignedUserId)
                        ? assignedUserId
                        : null,
                    decoration: const InputDecoration(
                      labelText: 'Vendedor *',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                    items: widget.options.sellers
                        .map(
                          (item) => DropdownMenuItem(
                            value: item.id,
                            child: Text(item.label),
                          ),
                        )
                        .toList(),
                    validator: (value) => value == null ? 'Selecione o vendedor' : null,
                    onChanged: canEdit
                        ? (value) {
                            if (value != null) {
                              setState(() => assignedUserId = value);
                            }
                          }
                        : null,
                  ),
                  const SizedBox(height: 18),
                  _sectionLabel('DETALHES'),
                  const SizedBox(height: 9),
                  TextFormField(
                    controller: subject,
                    enabled: canEdit,
                    maxLength: 160,
                    decoration: const InputDecoration(
                      labelText: 'Assunto',
                      hintText: 'Ex.: Apresentar nova tabela de preços',
                      prefixIcon: Icon(Icons.title_rounded),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: notes,
                    enabled: canEdit,
                    minLines: 4,
                    maxLines: 8,
                    maxLength: 4000,
                    decoration: const InputDecoration(
                      labelText: 'Observações',
                      hintText: 'Registre o objetivo, contexto ou resultado do contato.',
                      alignLabelWithHint: true,
                    ),
                  ),
                  Watch((context) {
                    final error = widget.controller.formError.value;
                    return error == null
                        ? const SizedBox.shrink()
                        : Padding(
                            padding: const EdgeInsets.only(top: 14),
                            child: OrderInlineError(message: error),
                          );
                  }),
                ],
              ),
            ),
          ),
        ),
        _footer(),
      ],
    );
  }

  Widget _footer() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Watch((context) {
          final saving = widget.controller.saving.value;
          final deleting = widget.controller.deleting.value;
          return Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: !canEdit || saving || deleting ? null : _save,
                  style: FilledButton.styleFrom(backgroundColor: AppColors.navy),
                  child: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Salvar'),
                ),
              ),
              if (widget.initial.isPersisted &&
                  widget.options.permissions.canDelete) ...[
                const SizedBox(width: 9),
                IconButton.outlined(
                  tooltip: 'Excluir tarefa',
                  onPressed: saving || deleting ? null : _delete,
                  color: AppColors.danger,
                  icon: deleting
                      ? const SizedBox(
                          width: 17,
                          height: 17,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.delete_outline_rounded),
                ),
              ],
              const SizedBox(width: 9),
              OutlinedButton(
                onPressed: saving || deleting
                    ? null
                    : () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
            ],
          );
        }),
      ),
    );
  }

  Future<void> _pickDate() async {
    final value = await showDatePicker(
      context: context,
      initialDate: scheduledAt,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      locale: const Locale('pt', 'BR'),
    );
    if (value == null || !mounted) return;
    setState(() {
      scheduledAt = DateTime(
        value.year,
        value.month,
        value.day,
        scheduledAt.hour,
        scheduledAt.minute,
      );
      date.text = _shortDate(scheduledAt);
    });
  }

  Future<void> _pickTime() async {
    final value = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(scheduledAt),
    );
    if (value == null || !mounted) return;
    setState(() {
      scheduledAt = DateTime(
        scheduledAt.year,
        scheduledAt.month,
        scheduledAt.day,
        value.hour,
        value.minute,
      );
      time.text = _shortTime(scheduledAt);
    });
  }

  void _scheduleClientSearch(String value) {
    setState(() => clientId = null);
    clientDebounce?.cancel();
    clientDebounce = Timer(
      const Duration(milliseconds: 350),
      () => widget.controller.searchClients(value),
    );
  }

  void _selectClient(TaskClientOption value) {
    setState(() {
      clientId = value.id;
      client.text = value.label;
      client.selection = TextSelection.collapsed(offset: client.text.length);
    });
    widget.controller.clearClientResults();
  }

  TaskDetail _value() {
    return TaskDetail(
      id: widget.initial.id,
      entryKind: widget.initial.entryKind,
      scheduledAt: scheduledAt,
      contactMethod: contactMethod,
      clientId: clientId,
      clientName: client.text,
      assignedUserId: assignedUserId,
      subject: subject.text,
      notes: notes.text,
      status: widget.initial.status,
    );
  }

  Future<void> _save() async {
    widget.controller.clearFormError();
    if (!(formKey.currentState?.validate() ?? false)) return;
    final saved = await widget.controller.saveTask(_value());
    if (!mounted || saved == null) return;
    Navigator.pop(context, true);
  }

  Future<void> _delete() async {
    final taskId = widget.initial.id;
    if (taskId == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir registro?'),
        content: const Text(
          'A tarefa ou atividade será removida permanentemente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final deleted = await widget.controller.deleteTask(taskId);
    if (!mounted || !deleted) return;
    Navigator.pop(context, true);
  }
}

class _TaskSheetFailure extends StatelessWidget {
  const _TaskSheetFailure({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 46,
            color: AppColors.danger,
          ),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Tentar novamente'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }
}

Widget _sectionLabel(String value) {
  return Text(
    value,
    style: const TextStyle(
      color: AppColors.muted,
      fontSize: 10.5,
      fontWeight: FontWeight.w900,
      letterSpacing: .45,
    ),
  );
}

String _two(int value) => value.toString().padLeft(2, '0');
String _shortDate(DateTime value) => '${_two(value.day)}/${_two(value.month)}/${value.year}';
String _shortTime(DateTime value) => '${_two(value.hour)}:${_two(value.minute)}';

const _defaultContactMethods = <TaskOption>[
  TaskOption(id: 'visit', label: 'Visita'),
  TaskOption(id: 'call', label: 'Ligação'),
  TaskOption(id: 'email', label: 'E-mail'),
  TaskOption(id: 'whatsapp', label: 'WhatsApp'),
  TaskOption(id: 'skype', label: 'Skype'),
  TaskOption(id: 'other', label: 'Outro'),
];

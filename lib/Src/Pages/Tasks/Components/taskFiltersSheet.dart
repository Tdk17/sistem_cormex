import 'package:flutter/material.dart';
import 'package:sistem_cormex/Src/Config/appColors.dart';
import 'package:sistem_cormex/Src/Models/taskModels.dart';
import 'package:sistem_cormex/Src/Pages/Tasks/Controller/tasksController.dart';

Future<bool?> showTaskFiltersSheet(
  BuildContext context, {
  required TasksController controller,
  required TaskFormOptions options,
}) {
  return showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Fechar filtros',
    barrierColor: Colors.black38,
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (_, __, ___) => _TaskFiltersSheet(
      controller: controller,
      options: options,
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

class _TaskFiltersSheet extends StatefulWidget {
  const _TaskFiltersSheet({required this.controller, required this.options});

  final TasksController controller;
  final TaskFormOptions options;

  @override
  State<_TaskFiltersSheet> createState() => _TaskFiltersSheetState();
}

class _TaskFiltersSheetState extends State<_TaskFiltersSheet> {
  late String status;
  late DateTime? from;
  late DateTime? to;
  late String? contactMethod;
  late String? sellerId;

  @override
  void initState() {
    super.initState();
    status = widget.controller.status.value;
    from = widget.controller.from.value;
    to = widget.controller.to.value;
    contactMethod = widget.controller.contactMethod.value;
    sellerId = widget.controller.sellerId.value;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final contacts = widget.options.contactMethods.isEmpty
        ? _defaultContactMethods
        : widget.options.contactMethods;
    return SafeArea(
      child: Align(
        alignment: Alignment.centerRight,
        child: Material(
          color: Colors.white,
          elevation: 24,
          child: SizedBox(
            width: width < 600 ? width : 430,
            height: double.infinity,
            child: Column(
              children: [
                Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.border)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.filter_alt_outlined, color: AppColors.cyan),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Filtros de tarefas',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context, false),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DropdownButtonFormField<String>(
                          value: status,
                          decoration: const InputDecoration(
                            labelText: 'Situação',
                            prefixIcon: Icon(Icons.fact_check_outlined),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'pending', child: Text('Pendentes')),
                            DropdownMenuItem(value: 'today', child: Text('Ocorrem hoje')),
                            DropdownMenuItem(value: 'overdue', child: Text('Atrasadas')),
                            DropdownMenuItem(value: 'completed', child: Text('Concluídas e atividades')),
                            DropdownMenuItem(value: 'all', child: Text('Todas')),
                          ],
                          onChanged: (value) {
                            if (value != null) setState(() => status = value);
                          },
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _DateFilterField(
                                label: 'Data inicial',
                                value: from,
                                onTap: () => _pickDate(isFrom: true),
                                onClear: from == null
                                    ? null
                                    : () => setState(() => from = null),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _DateFilterField(
                                label: 'Data final',
                                value: to,
                                onTap: () => _pickDate(isFrom: false),
                                onClear: to == null
                                    ? null
                                    : () => setState(() => to = null),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          value: contactMethod ?? '',
                          decoration: const InputDecoration(
                            labelText: 'Meio de contato',
                            prefixIcon: Icon(Icons.forum_outlined),
                          ),
                          items: [
                            const DropdownMenuItem(value: '', child: Text('Todos')),
                            ...contacts.map(
                              (item) => DropdownMenuItem(
                                value: item.id,
                                child: Text(item.label),
                              ),
                            ),
                          ],
                          onChanged: (value) => setState(
                            () => contactMethod = value == null || value.isEmpty
                                ? null
                                : value,
                          ),
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          value: sellerId ?? '',
                          decoration: const InputDecoration(
                            labelText: 'Vendedor',
                            prefixIcon: Icon(Icons.person_outline_rounded),
                          ),
                          items: [
                            const DropdownMenuItem(value: '', child: Text('Todos disponíveis')),
                            ...widget.options.sellers.map(
                              (item) => DropdownMenuItem(
                                value: item.id,
                                child: Text(item.label),
                              ),
                            ),
                          ],
                          onChanged: (value) => setState(
                            () => sellerId = value == null || value.isEmpty
                                ? null
                                : value,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: AppColors.border)),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _apply,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.navy,
                            ),
                            icon: const Icon(Icons.check_rounded),
                            label: const Text('Aplicar filtros'),
                          ),
                        ),
                        const SizedBox(width: 9),
                        OutlinedButton(
                          onPressed: _clear,
                          child: const Text('Limpar'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final initial = isFrom ? from : to;
    final value = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      locale: const Locale('pt', 'BR'),
    );
    if (value == null || !mounted) return;
    setState(() {
      if (isFrom) {
        from = DateTime(value.year, value.month, value.day);
      } else {
        to = DateTime(value.year, value.month, value.day, 23, 59, 59);
      }
    });
  }

  Future<void> _apply() async {
    if (from != null && to != null && from!.isAfter(to!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A data inicial deve ser anterior à data final.')),
      );
      return;
    }
    Navigator.pop(context, true);
    await widget.controller.applyFilters(
      nextStatus: status,
      nextFrom: from,
      nextTo: to,
      nextContactMethod: contactMethod,
      nextSellerId: sellerId,
    );
  }

  Future<void> _clear() async {
    Navigator.pop(context, true);
    await widget.controller.clearFilters();
  }
}

class _DateFilterField extends StatelessWidget {
  const _DateFilterField({
    required this.label,
    required this.value,
    required this.onTap,
    required this.onClear,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today_outlined, size: 19),
          suffixIcon: onClear == null
              ? null
              : IconButton(
                  onPressed: onClear,
                  icon: const Icon(Icons.close_rounded, size: 18),
                ),
        ),
        child: Text(value == null ? 'Qualquer data' : _shortDate(value!)),
      ),
    );
  }
}

String _two(int value) => value.toString().padLeft(2, '0');
String _shortDate(DateTime value) => '${_two(value.day)}/${_two(value.month)}/${value.year}';

const _defaultContactMethods = <TaskOption>[
  TaskOption(id: 'visit', label: 'Visita'),
  TaskOption(id: 'call', label: 'Ligação'),
  TaskOption(id: 'email', label: 'E-mail'),
  TaskOption(id: 'whatsapp', label: 'WhatsApp'),
  TaskOption(id: 'skype', label: 'Skype'),
  TaskOption(id: 'other', label: 'Outro'),
];

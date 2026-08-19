import 'dart:async';

import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';
import 'package:sistem_cormex/Src/Config/appColors.dart';
import 'package:sistem_cormex/Src/Dependencies/dependencies.dart';
import 'package:sistem_cormex/Src/Models/taskModels.dart';
import 'package:sistem_cormex/Src/Pages/Orders/Components/orderCommon.dart';
import 'package:sistem_cormex/Src/Pages/Tasks/Components/taskEditorSheet.dart';
import 'package:sistem_cormex/Src/Pages/Tasks/Components/taskFiltersSheet.dart';
import 'package:sistem_cormex/Src/Pages/Tasks/Controller/tasksController.dart';
import 'package:url_launcher/url_launcher.dart';

class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  late final TasksController controller;
  late final TextEditingController searchController;
  Timer? debounce;

  @override
  void initState() {
    super.initState();
    controller = getIt<TasksController>();
    searchController = TextEditingController(text: controller.query.value);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.initializeList();
    });
  }

  @override
  void dispose() {
    debounce?.cancel();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OrdersScaffold(
      floatingActionButton: MediaQuery.sizeOf(context).width < 650
          ? Watch(
              (context) => FloatingActionButton.extended(
                onPressed: controller.permissions.value.canCreate
                    ? () => _openEditor()
                    : null,
                icon: const Icon(Icons.add_task_rounded),
                label: const Text('Criar tarefa'),
              ),
            )
          : null,
      child: Scrollbar(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 22, 18, 42),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1580),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OrdersPageHeader(
                    title: 'Tarefas e atividades',
                    description:
                        'Acompanhe contatos agendados e registre o histórico comercial da equipe.',
                    actions: [
                      OutlinedButton.icon(
                        onPressed: controller.loadTasks,
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Atualizar'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _TaskTabs(controller: controller),
                  const SizedBox(height: 12),
                  Watch(
                    (context) => _TaskToolbar(
                      controller: controller,
                      searchController: searchController,
                      onSearchChanged: _scheduleSearch,
                      onCreate: controller.permissions.value.canCreate
                          ? () => _openEditor()
                          : null,
                      onRegisterActivity:
                          controller.permissions.value.canRegisterActivity
                              ? () => _openEditor(entryKind: 'activity')
                              : null,
                      onFilters: _openFilters,
                      onExport: controller.permissions.value.canExport
                          ? _export
                          : null,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _TasksContent(
                    controller: controller,
                    onEdit: (task) => _openEditor(
                      taskId: task.id,
                      entryKind: task.entryKind,
                    ),
                    onComplete: _complete,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _scheduleSearch(String value) {
    debounce?.cancel();
    debounce = Timer(
      const Duration(milliseconds: 450),
      () => controller.applySearch(value),
    );
  }

  Future<void> _openEditor({
    String? taskId,
    String entryKind = 'task',
  }) async {
    final changed = await showTaskEditorSheet(
      context,
      controller: controller,
      taskId: taskId,
      entryKind: entryKind,
    );
    if (!mounted || changed != true) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          entryKind == 'activity'
              ? 'Atividade registrada com sucesso.'
              : 'Tarefa salva com sucesso.',
        ),
      ),
    );
  }

  Future<void> _openFilters() async {
    final options = await controller.ensureFormOptions();
    if (!mounted) return;
    if (options == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            controller.formError.value ??
                'Não foi possível carregar as opções de filtro.',
          ),
        ),
      );
      return;
    }
    await showTaskFiltersSheet(
      context,
      controller: controller,
      options: options,
    );
  }

  Future<void> _complete(TaskSummary task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Concluir tarefa?'),
        content: Text(
          'Confirma que o contato com ${task.clientName} foi realizado?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.check_rounded),
            label: const Text('Concluir'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final completed = await controller.completeTask(task);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          completed
              ? 'Tarefa concluída.'
              : controller.listError.value ?? 'Não foi possível concluir.',
        ),
      ),
    );
  }

  Future<void> _export() async {
    final result = await controller.exportTasks();
    if (!mounted) return;
    final url = result?.downloadUrl;
    final opened = url != null &&
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            controller.listError.value ??
                'O arquivo ainda não está disponível.',
          ),
        ),
      );
    }
  }
}

class _TaskTabs extends StatelessWidget {
  const _TaskTabs({required this.controller});

  final TasksController controller;

  @override
  Widget build(BuildContext context) {
    return OrderSurface(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
            decoration: BoxDecoration(
              color: AppColors.navy,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.task_alt_rounded, size: 17, color: AppColors.lime),
                SizedBox(width: 7),
                Text(
                  'Tarefas',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Watch(
            (context) => Text(
              '${controller.pagination.value?.totalItems ?? controller.tasks.value.length} registros',
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskToolbar extends StatelessWidget {
  const _TaskToolbar({
    required this.controller,
    required this.searchController,
    required this.onSearchChanged,
    required this.onCreate,
    required this.onRegisterActivity,
    required this.onFilters,
    required this.onExport,
  });

  final TasksController controller;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback? onCreate;
  final VoidCallback? onRegisterActivity;
  final VoidCallback onFilters;
  final VoidCallback? onExport;

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final activeFilterCount = controller.activeFilterCount;
      final exporting = controller.exporting.value;
      return OrderSurface(
        padding: const EdgeInsets.all(14),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final actions = Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (constraints.maxWidth >= 600)
                  FilledButton.icon(
                    onPressed: onCreate,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.navy,
                    ),
                    icon: const Icon(Icons.add_task_rounded, size: 18),
                    label: const Text('Criar tarefa'),
                  ),
                OutlinedButton.icon(
                  onPressed: onRegisterActivity,
                  icon: const Icon(
                    Icons.history_toggle_off_rounded,
                    size: 18,
                  ),
                  label: const Text('Registrar atividade'),
                ),
                Badge(
                  isLabelVisible: activeFilterCount > 0,
                  label: Text('$activeFilterCount'),
                  child: OutlinedButton.icon(
                    onPressed: onFilters,
                    icon: const Icon(Icons.filter_alt_outlined, size: 18),
                    label: const Text('Filtros'),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: onExport,
                  icon: exporting
                      ? const SizedBox(
                          width: 17,
                          height: 17,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.table_view_outlined, size: 18),
                  label: const Text('Excel'),
                ),
              ],
            );
            final search = ValueListenableBuilder<TextEditingValue>(
              valueListenable: searchController,
              builder: (context, value, _) => TextField(
                controller: searchController,
                onChanged: onSearchChanged,
                onSubmitted: controller.applySearch,
                decoration: InputDecoration(
                  hintText: 'Pesquise por cliente, assunto ou vendedor',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: value.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            searchController.clear();
                            controller.applySearch('');
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                ),
              ),
            );
            if (constraints.maxWidth < 940) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  actions,
                  const SizedBox(height: 12),
                  search,
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: actions),
                const SizedBox(width: 14),
                SizedBox(width: 390, child: search),
              ],
            );
          },
        ),
      );
    });
  }
}

class _TasksContent extends StatelessWidget {
  const _TasksContent({
    required this.controller,
    required this.onEdit,
    required this.onComplete,
  });

  final TasksController controller;
  final ValueChanged<TaskSummary> onEdit;
  final ValueChanged<TaskSummary> onComplete;

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final loading = controller.listLoading.value;
      final error = controller.listError.value;
      final tasks = controller.tasks.value;
      final pagination = controller.pagination.value;
      final permissions = controller.permissions.value;
      final groups = _groupTasks(tasks);
      return Column(
        children: [
          if (loading) const LinearProgressIndicator(minHeight: 2),
          if (error != null) ...[
            OrderInlineError(message: error, onRetry: controller.loadTasks),
            const SizedBox(height: 12),
          ],
          if (!loading && tasks.isEmpty)
            const OrderSurface(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 34),
                child: Column(
                  children: [
                    Icon(
                      Icons.event_available_outlined,
                      size: 50,
                      color: AppColors.muted,
                    ),
                    SizedBox(height: 11),
                    Text(
                      'Nenhuma tarefa encontrada',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Ajuste os filtros ou crie uma nova tarefa.',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            )
          else
            ...groups.map(
              (group) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _TaskDateGroup(
                  date: group.key,
                  tasks: group.value,
                  canEdit: permissions.canEdit,
                  canComplete: permissions.canComplete,
                  onEdit: onEdit,
                  onComplete: onComplete,
                ),
              ),
            ),
          if (pagination != null && pagination.totalPages > 1)
            OrderSurface(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${pagination.totalItems} registros',
                    style: const TextStyle(color: AppColors.muted),
                  ),
                  Row(
                    children: [
                      IconButton.outlined(
                        onPressed: loading || pagination.page <= 1
                            ? null
                            : () => controller.loadTasks(
                                  page: pagination.page - 1,
                                ),
                        icon: const Icon(Icons.chevron_left_rounded),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          '${pagination.page} de ${pagination.totalPages}',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      IconButton.outlined(
                        onPressed: loading || !pagination.hasNextPage
                            ? null
                            : () => controller.loadTasks(
                                  page: pagination.page + 1,
                                ),
                        icon: const Icon(Icons.chevron_right_rounded),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      );
    });
  }
}

class _TaskDateGroup extends StatelessWidget {
  const _TaskDateGroup({
    required this.date,
    required this.tasks,
    required this.canEdit,
    required this.canComplete,
    required this.onEdit,
    required this.onComplete,
  });

  final DateTime date;
  final List<TaskSummary> tasks;
  final bool canEdit;
  final bool canComplete;
  final ValueChanged<TaskSummary> onEdit;
  final ValueChanged<TaskSummary> onComplete;

  @override
  Widget build(BuildContext context) {
    return OrderSurface(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 11),
            child: Text(
              _groupTitle(date),
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: .3,
              ),
            ),
          ),
          const Divider(height: 1),
          ...tasks.map(
            (task) => _TaskRow(
              task: task,
              canEdit: canEdit,
              canComplete: canComplete,
              onEdit: () => onEdit(task),
              onComplete: () => onComplete(task),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({
    required this.task,
    required this.canEdit,
    required this.canComplete,
    required this.onEdit,
    required this.onComplete,
  });

  final TaskSummary task;
  final bool canEdit;
  final bool canComplete;
  final VoidCallback onEdit;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 790;
    final status = _statusStyle(task);
    return InkWell(
      onTap: canEdit ? onEdit : null,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 12 : 16,
          vertical: 14,
        ),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 42,
              height: 42,
              child: Checkbox(
                value: task.isCompleted,
                onChanged: task.status == 'pending' && canComplete
                    ? (_) => onComplete()
                    : null,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.cyan.withOpacity(.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _contactIcon(task.contactMethod),
                color: AppColors.cyan,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 5,
                    runSpacing: 3,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        task.contactMethodLabel,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          decoration:
                              task.isCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const Text('para', style: TextStyle(color: AppColors.muted)),
                      Text(
                        task.clientName,
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  if (task.subject.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      task.subject,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 12,
                    runSpacing: 5,
                    children: [
                      _Meta(
                        icon: Icons.schedule_rounded,
                        text: _dateTimeLabel(task.scheduledAt),
                      ),
                      _Meta(
                        icon: Icons.person_outline_rounded,
                        text: 'Responsável: ${task.assignedUserName}',
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: status.$2,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          status.$1,
                          style: TextStyle(
                            color: status.$3,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (!compact)
              IconButton(
                tooltip: 'Editar',
                onPressed: canEdit ? onEdit : null,
                icon: const Icon(Icons.edit_outlined, size: 19),
              ),
          ],
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.muted),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(color: AppColors.muted, fontSize: 11.5),
        ),
      ],
    );
  }
}

List<MapEntry<DateTime, List<TaskSummary>>> _groupTasks(
  List<TaskSummary> tasks,
) {
  final groups = <DateTime, List<TaskSummary>>{};
  for (final task in tasks) {
    final value = task.scheduledAt;
    final date = DateTime(value.year, value.month, value.day);
    groups.putIfAbsent(date, () => []).add(task);
  }
  final entries = groups.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
  return entries;
}

(String, Color, Color) _statusStyle(TaskSummary task) {
  if (task.isCompleted || task.entryKind == 'activity') {
    return ('Concluída', const Color(0xFFDFF4D2), const Color(0xFF35751B));
  }
  if (task.status == 'cancelled') {
    return ('Cancelada', const Color(0xFFE8E9EA), AppColors.muted);
  }
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final taskDate = DateTime(
    task.scheduledAt.year,
    task.scheduledAt.month,
    task.scheduledAt.day,
  );
  if (taskDate.isAtSameMomentAs(today)) {
    return ('Ocorre hoje', const Color(0xFFFFF1BF), const Color(0xFF8A6700));
  }
  if (task.scheduledAt.isBefore(now)) {
    return ('Atrasada', const Color(0xFFF9DDDD), AppColors.danger);
  }
  return ('Agendada', const Color(0xFFDDEEF7), const Color(0xFF216A8A));
}

IconData _contactIcon(String method) {
  switch (method) {
    case 'visit':
      return Icons.location_on_outlined;
    case 'email':
      return Icons.email_outlined;
    case 'whatsapp':
      return Icons.chat_outlined;
    case 'video_call':
    case 'skype':
      return Icons.video_call_outlined;
    case 'call':
      return Icons.phone_outlined;
    default:
      return Icons.forum_outlined;
  }
}

String _groupTitle(DateTime value) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final date = DateTime(value.year, value.month, value.day);
  if (date.isAtSameMomentAs(today)) {
    return 'HOJE — ${_fullDate(value).toUpperCase()}';
  }
  if (date.isAtSameMomentAs(today.add(const Duration(days: 1)))) {
    return 'AMANHÃ — ${_fullDate(value).toUpperCase()}';
  }
  return _fullDate(value).toUpperCase();
}

String _fullDate(DateTime value) {
  const weekdays = [
    'segunda-feira',
    'terça-feira',
    'quarta-feira',
    'quinta-feira',
    'sexta-feira',
    'sábado',
    'domingo',
  ];
  const months = [
    'janeiro',
    'fevereiro',
    'março',
    'abril',
    'maio',
    'junho',
    'julho',
    'agosto',
    'setembro',
    'outubro',
    'novembro',
    'dezembro',
  ];
  return '${weekdays[value.weekday - 1]}, ${value.day} de ${months[value.month - 1]} de ${value.year}';
}

String _dateTimeLabel(DateTime value) {
  final date = '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
  final time = '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  return '$date às $time';
}

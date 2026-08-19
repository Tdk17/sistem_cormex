import 'package:signals/signals.dart';
import 'package:sistem_cormex/Src/Connection/apiException.dart';
import 'package:sistem_cormex/Src/Models/taskModels.dart';
import 'package:sistem_cormex/Src/Pages/Auth/Controller/authController.dart';
import 'package:sistem_cormex/Src/Pages/Tasks/Repository/tasksRepository.dart';

class TasksController {
  TasksController(this._repository, this._authController);

  final TasksRepository _repository;
  final AuthController _authController;
  String? _dataSessionToken;
  int _listRequestId = 0;
  int _clientRequestId = 0;

  final listLoading = signal(false);
  final listError = signal<String?>(null);
  final tasks = signal<List<TaskSummary>>([]);
  final pagination = signal<TaskPagination?>(null);
  final permissions = signal(TaskPermissions.initial);
  final query = signal('');
  final status = signal('pending');
  final from = signal<DateTime?>(null);
  final to = signal<DateTime?>(null);
  final contactMethod = signal<String?>(null);
  final sellerId = signal<String?>(null);

  final formLoading = signal(false);
  final formError = signal<String?>(null);
  final formOptions = signal<TaskFormOptions?>(null);
  final editingTask = signal<TaskDetail?>(null);
  final clientResults = signal<List<TaskClientOption>>([]);
  final clientsLoading = signal(false);
  final saving = signal(false);
  final completing = signal(false);
  final deleting = signal(false);
  final exporting = signal(false);

  int get activeFilterCount {
    var count = status.value == 'pending' ? 0 : 1;
    if (from.value != null) count++;
    if (to.value != null) count++;
    if (contactMethod.value != null) count++;
    if (sellerId.value != null) count++;
    return count;
  }

  Future<void> initializeList() async {
    _synchronizeSession();
    if (tasks.value.isEmpty) await loadTasks();
  }

  Future<void> loadTasks({int page = 1}) async {
    final requestId = ++_listRequestId;
    batch(() {
      listLoading.value = true;
      listError.value = null;
    });
    try {
      final result = await _repository.listTasks(
        sessionToken: _sessionToken,
        page: page,
        pageSize: 25,
        query: query.value,
        status: status.value,
        from: from.value,
        to: to.value,
        contactMethod: contactMethod.value,
        sellerId: sellerId.value,
      );
      if (requestId != _listRequestId) return;
      batch(() {
        tasks.value = result.tasks;
        pagination.value = result.pagination;
        permissions.value = result.permissions;
      });
    } catch (error) {
      if (requestId == _listRequestId) listError.value = _messageFor(error);
    } finally {
      if (requestId == _listRequestId) listLoading.value = false;
    }
  }

  Future<void> applySearch(String value) async {
    query.value = value.trim();
    await loadTasks();
  }

  Future<void> applyFilters({
    required String nextStatus,
    DateTime? nextFrom,
    DateTime? nextTo,
    String? nextContactMethod,
    String? nextSellerId,
  }) async {
    batch(() {
      status.value = nextStatus;
      from.value = nextFrom;
      to.value = nextTo;
      contactMethod.value = _emptyToNull(nextContactMethod);
      sellerId.value = _emptyToNull(nextSellerId);
    });
    await loadTasks();
  }

  Future<void> clearFilters() async {
    await applyFilters(nextStatus: 'pending');
  }

  Future<void> initializeForm({
    String? taskId,
    required String entryKind,
  }) async {
    _synchronizeSession();
    batch(() {
      formLoading.value = true;
      formError.value = null;
      editingTask.value = null;
      clientResults.value = [];
    });
    try {
      final optionsFuture = _repository.getFormOptions(
        sessionToken: _sessionToken,
      );
      final taskFuture = taskId == null
          ? Future<TaskDetail?>.value(null)
          : _repository
              .getTask(sessionToken: _sessionToken, taskId: taskId)
              .then<TaskDetail?>((value) => value);
      final results = await Future.wait<dynamic>([optionsFuture, taskFuture]);
      final options = results[0] as TaskFormOptions;
      final task = results[1] as TaskDetail?;
      batch(() {
        formOptions.value = options;
        permissions.value = options.permissions;
        editingTask.value = task ??
            TaskDetail.empty(
              entryKind: entryKind,
              assignedUserId: options.currentUserId,
            );
      });
    } catch (error) {
      formError.value = _messageFor(error);
    } finally {
      formLoading.value = false;
    }
  }

  Future<TaskFormOptions?> ensureFormOptions() async {
    _synchronizeSession();
    final current = formOptions.value;
    if (current != null) return current;
    batch(() {
      formLoading.value = true;
      formError.value = null;
    });
    try {
      final options = await _repository.getFormOptions(
        sessionToken: _sessionToken,
      );
      batch(() {
        formOptions.value = options;
        permissions.value = options.permissions;
      });
      return options;
    } catch (error) {
      formError.value = _messageFor(error);
      return null;
    } finally {
      formLoading.value = false;
    }
  }

  Future<void> searchClients(String value) async {
    final query = value.trim();
    final requestId = ++_clientRequestId;
    if (query.length < 2) {
      batch(() {
        clientsLoading.value = false;
        clientResults.value = [];
      });
      return;
    }
    clientsLoading.value = true;
    try {
      final result = await _repository.searchClients(
        sessionToken: _sessionToken,
        query: query,
      );
      if (requestId == _clientRequestId) clientResults.value = result;
    } catch (error) {
      if (requestId == _clientRequestId) formError.value = _messageFor(error);
    } finally {
      if (requestId == _clientRequestId) clientsLoading.value = false;
    }
  }

  void clearClientResults() {
    _clientRequestId++;
    batch(() {
      clientsLoading.value = false;
      clientResults.value = [];
    });
  }

  Future<TaskDetail?> saveTask(TaskDetail task) async {
    if (saving.value) return null;
    final validation = _validate(task);
    if (validation != null) {
      formError.value = validation;
      return null;
    }
    batch(() {
      saving.value = true;
      formError.value = null;
    });
    try {
      final saved = await _repository.saveTask(
        sessionToken: _sessionToken,
        task: task.toRequest(),
      );
      await loadTasks();
      return saved;
    } catch (error) {
      formError.value = _messageFor(error);
      return null;
    } finally {
      saving.value = false;
    }
  }

  Future<bool> completeTask(TaskSummary task) async {
    if (task.isCompleted || completing.value) return false;
    batch(() {
      completing.value = true;
      listError.value = null;
    });
    try {
      await _repository.completeTask(
        sessionToken: _sessionToken,
        taskId: task.id,
      );
      await loadTasks(page: pagination.value?.page ?? 1);
      return true;
    } catch (error) {
      listError.value = _messageFor(error);
      return false;
    } finally {
      completing.value = false;
    }
  }

  Future<bool> deleteTask(String taskId) async {
    if (deleting.value) return false;
    batch(() {
      deleting.value = true;
      formError.value = null;
    });
    try {
      await _repository.deleteTask(
        sessionToken: _sessionToken,
        taskId: taskId,
      );
      await loadTasks();
      return true;
    } catch (error) {
      formError.value = _messageFor(error);
      return false;
    } finally {
      deleting.value = false;
    }
  }

  Future<TaskExport?> exportTasks() async {
    if (exporting.value) return null;
    batch(() {
      exporting.value = true;
      listError.value = null;
    });
    try {
      return await _repository.exportTasks(
        sessionToken: _sessionToken,
        filters: {
          'query': query.value,
          'status': status.value,
          'from': from.value?.toUtc().toIso8601String(),
          'to': to.value?.toUtc().toIso8601String(),
          'contactMethod': contactMethod.value,
          'sellerId': sellerId.value,
        },
      );
    } catch (error) {
      listError.value = _messageFor(error);
      return null;
    } finally {
      exporting.value = false;
    }
  }

  void clearFormError() => formError.value = null;

  String? _validate(TaskDetail task) {
    if (task.clientId == null || task.clientId!.isEmpty) {
      return 'Selecione o cliente.';
    }
    if (task.contactMethod.isEmpty) return 'Selecione o meio de contato.';
    if (task.assignedUserId.isEmpty) return 'Selecione o vendedor responsável.';
    if (task.subject.trim().length > 160) {
      return 'O assunto deve ter no máximo 160 caracteres.';
    }
    if (task.notes.trim().length > 4000) {
      return 'As observações devem ter no máximo 4.000 caracteres.';
    }
    return null;
  }

  void _synchronizeSession() {
    final token = _authController.sessionToken.value;
    if (_dataSessionToken == token) return;
    _dataSessionToken = token;
    _listRequestId++;
    _clientRequestId++;
    batch(() {
      listLoading.value = false;
      formLoading.value = false;
      tasks.value = [];
      pagination.value = null;
      permissions.value = TaskPermissions.initial;
      query.value = '';
      status.value = 'pending';
      from.value = null;
      to.value = null;
      contactMethod.value = null;
      sellerId.value = null;
      formOptions.value = null;
      editingTask.value = null;
      clientResults.value = [];
      clientsLoading.value = false;
      listError.value = null;
      formError.value = null;
    });
  }

  String get _sessionToken {
    final token = _authController.sessionToken.value;
    if (token == null || token.isEmpty) {
      throw const ApiException(
        message: 'Sua sessão expirou. Entre novamente.',
        code: 209,
      );
    }
    return token;
  }

  String? _emptyToNull(String? value) {
    final text = value?.trim() ?? '';
    return text.isEmpty ? null : text;
  }

  String _messageFor(Object error) {
    if (error is ApiException) {
      switch (error.code) {
        case 209:
          return 'Sua sessão expirou. Entre novamente.';
        case 9600:
          return 'Você não possui permissão para acessar as tarefas.';
        case 9601:
          return 'Tarefa não localizada.';
        case 9602:
          return 'Revise os dados informados.';
        case 9603:
          return 'O cliente informado não pertence à sua empresa.';
        case 9604:
          return 'O vendedor informado não pertence à sua empresa.';
        case 9605:
          return 'Esta tarefa já foi concluída.';
        case 9606:
          return 'Você não possui permissão para alterar esta tarefa.';
        case 9607:
          return 'Não foi possível gerar o arquivo de atividades.';
        default:
          return error.message;
      }
    }
    if (error is FormatException) return error.message.toString();
    return 'Não foi possível concluir a operação de tarefas.';
  }
}

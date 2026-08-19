import 'package:sistem_cormex/Src/Connection/endpoints.dart';
import 'package:sistem_cormex/Src/Connection/httpManager.dart';
import 'package:sistem_cormex/Src/Models/taskModels.dart';

abstract interface class TasksRepository {
  Future<TaskListResult> listTasks({
    required String sessionToken,
    required int page,
    required int pageSize,
    required String query,
    required String status,
    DateTime? from,
    DateTime? to,
    String? contactMethod,
    String? sellerId,
  });

  Future<TaskFormOptions> getFormOptions({required String sessionToken});

  Future<List<TaskClientOption>> searchClients({
    required String sessionToken,
    required String query,
  });

  Future<TaskDetail> getTask({
    required String sessionToken,
    required String taskId,
  });

  Future<TaskDetail> saveTask({
    required String sessionToken,
    required Map<String, dynamic> task,
  });

  Future<void> completeTask({
    required String sessionToken,
    required String taskId,
  });

  Future<void> deleteTask({
    required String sessionToken,
    required String taskId,
  });

  Future<TaskExport> exportTasks({
    required String sessionToken,
    required Map<String, dynamic> filters,
  });
}

class ParseTasksRepository implements TasksRepository {
  const ParseTasksRepository(this._httpManager);

  final HttpManager _httpManager;

  @override
  Future<TaskListResult> listTasks({
    required String sessionToken,
    required int page,
    required int pageSize,
    required String query,
    required String status,
    DateTime? from,
    DateTime? to,
    String? contactMethod,
    String? sellerId,
  }) async {
    final result = await _post(
      Endpoints.tasksList,
      sessionToken,
      {
        'page': page,
        'pageSize': pageSize,
        'query': query.trim(),
        'status': status,
        'from': from?.toUtc().toIso8601String(),
        'to': to?.toUtc().toIso8601String(),
        'contactMethod': contactMethod,
        'sellerId': sellerId,
      },
    );
    return TaskListResult.fromMap(result);
  }

  @override
  Future<TaskFormOptions> getFormOptions({
    required String sessionToken,
  }) async {
    final result = await _post(
      Endpoints.tasksFormOptions,
      sessionToken,
      const {},
    );
    return TaskFormOptions.fromMap(result);
  }

  @override
  Future<List<TaskClientOption>> searchClients({
    required String sessionToken,
    required String query,
  }) async {
    final result = await _post(
      Endpoints.tasksSearchClients,
      sessionToken,
      {'query': query.trim(), 'limit': 20},
    );
    final clients = result['clients'];
    if (clients is! List) return const [];
    return clients
        .whereType<Map>()
        .map((item) => TaskClientOption.fromMap(Map<String, dynamic>.from(item)))
        .toList();
  }

  @override
  Future<TaskDetail> getTask({
    required String sessionToken,
    required String taskId,
  }) async {
    final result = await _post(
      Endpoints.tasksGet,
      sessionToken,
      {'taskId': taskId},
    );
    return TaskDetail.fromMap(_taskMap(result));
  }

  @override
  Future<TaskDetail> saveTask({
    required String sessionToken,
    required Map<String, dynamic> task,
  }) async {
    final result = await _post(Endpoints.tasksSave, sessionToken, task);
    return TaskDetail.fromMap(_taskMap(result));
  }

  @override
  Future<void> completeTask({
    required String sessionToken,
    required String taskId,
  }) async {
    await _post(
      Endpoints.tasksComplete,
      sessionToken,
      {
        'taskId': taskId,
        'completedAt': DateTime.now().toUtc().toIso8601String(),
      },
    );
  }

  @override
  Future<void> deleteTask({
    required String sessionToken,
    required String taskId,
  }) async {
    await _post(
      Endpoints.tasksDelete,
      sessionToken,
      {'taskId': taskId},
    );
  }

  @override
  Future<TaskExport> exportTasks({
    required String sessionToken,
    required Map<String, dynamic> filters,
  }) async {
    final result = await _post(
      Endpoints.tasksExport,
      sessionToken,
      {'format': 'xlsx', ...filters},
    );
    return TaskExport.fromMap(result);
  }

  Future<Map<String, dynamic>> _post(
    String endpoint,
    String sessionToken,
    Map<String, dynamic> body,
  ) async {
    final response = await _httpManager.restRequest(
      url: endpoint,
      method: HttpMethod.post,
      sessionToken: sessionToken,
      body: body,
    );
    final result = response['result'];
    if (result is Map) return Map<String, dynamic>.from(result);
    throw const FormatException(
      'O servidor retornou uma resposta inválida para Tarefas.',
    );
  }

  Map<String, dynamic> _taskMap(Map<String, dynamic> result) {
    final task = result['task'];
    return task is Map ? Map<String, dynamic>.from(task) : result;
  }
}

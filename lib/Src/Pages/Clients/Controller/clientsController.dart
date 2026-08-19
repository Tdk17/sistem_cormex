import 'package:signals/signals.dart';
import 'package:sistem_cormex/Src/Connection/apiException.dart';
import 'package:sistem_cormex/Src/Models/clientModels.dart';
import 'package:sistem_cormex/Src/Pages/Auth/Controller/authController.dart';
import 'package:sistem_cormex/Src/Pages/Clients/Repository/clientsRepository.dart';

class ClientsController {
  ClientsController(this._repository, this._authController);

  final ClientsRepository _repository;
  final AuthController _authController;
  String? _dataSessionToken;
  int _listRequestId = 0;

  final listLoading = signal(false);
  final listError = signal<String?>(null);
  final clients = signal<List<ClientSummary>>([]);
  final pagination = signal<ClientPagination?>(null);
  final portfolio = signal(ClientPortfolio.empty);
  final permissions = signal(ClientPermissions.all);
  final query = signal('');
  final visibility = signal('unblocked');

  final formLoading = signal(false);
  final formError = signal<String?>(null);
  final formOptions = signal<ClientFormOptions?>(null);
  final editingClient = signal<ClientDetail?>(null);
  final saving = signal(false);
  final deleting = signal(false);
  final postalCodeLoading = signal(false);
  final importing = signal(false);
  final importResult = signal<ClientImportResult?>(null);

  Future<void> initializeList() async {
    _synchronizeSession();
    if (clients.value.isEmpty) await loadClients();
  }

  Future<void> loadClients({int page = 1}) async {
    final requestId = ++_listRequestId;
    batch(() {
      listLoading.value = true;
      listError.value = null;
    });
    try {
      final result = await _repository.listClients(
        sessionToken: _sessionToken,
        page: page,
        pageSize: 25,
        query: query.value,
        visibility: visibility.value,
      );
      if (requestId != _listRequestId) return;
      batch(() {
        clients.value = result.clients;
        pagination.value = result.pagination;
        portfolio.value = result.portfolio;
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
    await loadClients();
  }

  Future<void> changeVisibility(String value) async {
    visibility.value = value;
    await loadClients();
  }

  Future<void> initializeForm(String? clientId) async {
    _synchronizeSession();
    batch(() {
      formLoading.value = true;
      formError.value = null;
      editingClient.value = null;
    });
    try {
      final optionsFuture = _repository.getFormOptions(
        sessionToken: _sessionToken,
      );
      final clientFuture = clientId == null
          ? Future<ClientDetail?>.value(null)
          : _repository
              .getClient(sessionToken: _sessionToken, clientId: clientId)
              .then<ClientDetail?>((value) => value);
      final results = await Future.wait<dynamic>([optionsFuture, clientFuture]);
      final options = results[0] as ClientFormOptions;
      final client = results[1] as ClientDetail?;
      batch(() {
        formOptions.value = options;
        permissions.value = options.permissions;
        editingClient.value = client ?? ClientDetail.empty();
      });
    } catch (error) {
      formError.value = _messageFor(error);
    } finally {
      formLoading.value = false;
    }
  }

  Future<ClientDetail?> saveClient(ClientDetail client) async {
    if (saving.value) return null;
    final validation = _validate(client);
    if (validation != null) {
      formError.value = validation;
      return null;
    }
    batch(() {
      saving.value = true;
      formError.value = null;
    });
    try {
      final saved = await _repository.saveClient(
        sessionToken: _sessionToken,
        client: client.toRequest(),
      );
      await loadClients();
      return saved;
    } catch (error) {
      formError.value = _messageFor(error);
      return null;
    } finally {
      saving.value = false;
    }
  }

  Future<bool> deleteClient(ClientSummary client) async {
    if (deleting.value) return false;
    batch(() {
      deleting.value = true;
      listError.value = null;
    });
    try {
      await _repository.deleteClient(
        sessionToken: _sessionToken,
        clientId: client.id,
      );
      await loadClients();
      return true;
    } catch (error) {
      listError.value = _messageFor(error);
      return false;
    } finally {
      deleting.value = false;
    }
  }

  Future<ClientAddress?> lookupPostalCode(String value) async {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 8 || postalCodeLoading.value) return null;
    postalCodeLoading.value = true;
    try {
      return await _repository.lookupPostalCode(
        sessionToken: _sessionToken,
        postalCode: digits,
      );
    } catch (error) {
      formError.value = _messageFor(error);
      return null;
    } finally {
      postalCodeLoading.value = false;
    }
  }

  Future<ClientImportResult?> importClients({
    required String fileName,
    required String base64,
  }) async {
    if (importing.value) return null;
    batch(() {
      importing.value = true;
      listError.value = null;
      importResult.value = null;
    });
    try {
      final result = await _repository.importClients(
        sessionToken: _sessionToken,
        fileName: fileName,
        base64: base64,
      );
      importResult.value = result;
      await loadClients();
      return result;
    } catch (error) {
      listError.value = _messageFor(error);
      return null;
    } finally {
      importing.value = false;
    }
  }

  void prepareAnotherClient() {
    batch(() {
      editingClient.value = ClientDetail.empty();
      formError.value = null;
      importResult.value = null;
    });
  }

  void clearFormError() => formError.value = null;

  String? _validate(ClientDetail client) {
    final digits = client.document.replaceAll(RegExp(r'\D'), '');
    final expectedLength = client.type == 'business' ? 14 : 11;
    if (digits.length != expectedLength) {
      return client.type == 'business'
          ? 'Informe um CNPJ válido.'
          : 'Informe um CPF válido.';
    }
    if (client.legalName.trim().length < 2) {
      return client.type == 'business'
          ? 'Informe a razão social.'
          : 'Informe o nome completo.';
    }
    if (client.phones.where((item) => item.trim().isNotEmpty).isEmpty) {
      return 'Informe ao menos um telefone.';
    }
    final emails = client.emails.where((item) => item.trim().isNotEmpty);
    if (emails.isEmpty ||
        emails.any((item) =>
            !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(item.trim()))) {
      return 'Informe ao menos um e-mail válido.';
    }
    if (client.type == 'business' &&
        client.stateRegistration.trim().isEmpty &&
        client.fiscalExceptionId == null) {
      return 'Informe a inscrição estadual ou marque a exceção fiscal correspondente.';
    }
    if (client.segmentId == null || client.segmentId!.isEmpty) {
      return 'Selecione o segmento do cliente.';
    }
    final address = client.primaryAddress;
    if (address.postalCode.replaceAll(RegExp(r'\D'), '').length != 8 ||
        address.street.trim().isEmpty ||
        address.number.trim().isEmpty ||
        address.city.trim().isEmpty ||
        address.state.isEmpty) {
      return 'Preencha CEP, endereço, número, cidade e estado.';
    }
    return null;
  }

  void _synchronizeSession() {
    final token = _authController.sessionToken.value;
    if (_dataSessionToken == token) return;
    _dataSessionToken = token;
    _listRequestId++;
    batch(() {
      listLoading.value = false;
      formLoading.value = false;
      clients.value = [];
      pagination.value = null;
      portfolio.value = ClientPortfolio.empty;
      permissions.value = ClientPermissions.all;
      query.value = '';
      visibility.value = 'unblocked';
      formOptions.value = null;
      editingClient.value = null;
      listError.value = null;
      formError.value = null;
      importResult.value = null;
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

  String _messageFor(Object error) {
    if (error is ApiException) {
      switch (error.code) {
        case 209:
          return 'Sua sessão expirou. Entre novamente.';
        case 9400:
          return 'Você não possui permissão para acessar os clientes.';
        case 9401:
          return 'Cliente não localizado.';
        case 9402:
          return 'Já existe um cliente com este CPF ou CNPJ.';
        case 9403:
          return 'Revise os dados informados.';
        case 9404:
          return 'Este cliente possui pedidos e não pode ser excluído. Bloqueie-o para impedir novas vendas.';
        case 9405:
          return 'CEP não localizado.';
        case 9406:
          return 'A planilha é inválida. Use CSV ou XLSX com até 5 MB.';
        default:
          return error.message;
      }
    }
    if (error is FormatException) return error.message.toString();
    return 'Não foi possível concluir a operação de clientes.';
  }
}

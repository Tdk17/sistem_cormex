import 'package:sistem_cormex/Src/Connection/endpoints.dart';
import 'package:sistem_cormex/Src/Connection/httpManager.dart';
import 'package:sistem_cormex/Src/Models/clientModels.dart';

abstract interface class ClientsRepository {
  Future<ClientListResult> listClients({
    required String sessionToken,
    required int page,
    required int pageSize,
    required String query,
    required String visibility,
  });

  Future<ClientFormOptions> getFormOptions({required String sessionToken});

  Future<ClientDetail> getClient({
    required String sessionToken,
    required String clientId,
  });

  Future<ClientDetail> saveClient({
    required String sessionToken,
    required Map<String, dynamic> client,
  });

  Future<void> deleteClient({
    required String sessionToken,
    required String clientId,
  });

  Future<ClientAddress> lookupPostalCode({
    required String sessionToken,
    required String postalCode,
  });

  Future<ClientImportResult> importClients({
    required String sessionToken,
    required String fileName,
    required String base64,
  });
}

class ParseClientsRepository implements ClientsRepository {
  const ParseClientsRepository(this._httpManager);

  final HttpManager _httpManager;

  @override
  Future<ClientListResult> listClients({
    required String sessionToken,
    required int page,
    required int pageSize,
    required String query,
    required String visibility,
  }) async {
    final result = await _post(
      Endpoints.clientsList,
      sessionToken,
      {
        'page': page,
        'pageSize': pageSize,
        'query': query.trim(),
        'visibility': visibility,
      },
    );
    return ClientListResult.fromMap(result);
  }

  @override
  Future<ClientFormOptions> getFormOptions({
    required String sessionToken,
  }) async {
    final result = await _post(
      Endpoints.clientsFormOptions,
      sessionToken,
      const {},
    );
    return ClientFormOptions.fromMap(result);
  }

  @override
  Future<ClientDetail> getClient({
    required String sessionToken,
    required String clientId,
  }) async {
    final result = await _post(
      Endpoints.clientsGet,
      sessionToken,
      {'clientId': clientId},
    );
    return ClientDetail.fromMap(_clientMap(result));
  }

  @override
  Future<ClientDetail> saveClient({
    required String sessionToken,
    required Map<String, dynamic> client,
  }) async {
    final result = await _post(
      Endpoints.clientsSave,
      sessionToken,
      client,
    );
    return ClientDetail.fromMap(_clientMap(result));
  }

  @override
  Future<void> deleteClient({
    required String sessionToken,
    required String clientId,
  }) async {
    await _post(
      Endpoints.clientsDelete,
      sessionToken,
      {'clientId': clientId},
    );
  }

  @override
  Future<ClientAddress> lookupPostalCode({
    required String sessionToken,
    required String postalCode,
  }) async {
    final result = await _post(
      Endpoints.clientsPostalCodeLookup,
      sessionToken,
      {'postalCode': postalCode.replaceAll(RegExp(r'\D'), '')},
    );
    final address = result['address'];
    return ClientAddress.fromMap(
      address is Map ? Map<String, dynamic>.from(address) : result,
      primaryFallback: true,
    );
  }

  @override
  Future<ClientImportResult> importClients({
    required String sessionToken,
    required String fileName,
    required String base64,
  }) async {
    final result = await _post(
      Endpoints.clientsImport,
      sessionToken,
      {'fileName': fileName, 'base64': base64},
    );
    return ClientImportResult.fromMap(result);
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
      'O servidor retornou uma resposta inválida para Clientes.',
    );
  }

  Map<String, dynamic> _clientMap(Map<String, dynamic> result) {
    final client = result['client'];
    return client is Map ? Map<String, dynamic>.from(client) : result;
  }
}

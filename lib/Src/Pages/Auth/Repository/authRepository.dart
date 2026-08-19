import 'package:sistem_cormex/Src/Connection/endpoints.dart';
import 'package:sistem_cormex/Src/Connection/httpManager.dart';
import 'package:sistem_cormex/Src/Models/appUser.dart';
import 'package:sistem_cormex/Src/Models/authSession.dart';

abstract interface class AuthRepository {
  Future<AuthSession> logIn({
    required String email,
    required String password,
  });

  Future<AuthSession> signUp({
    required String fullname,
    required String email,
    required String password,
    required String document,
    required String phone,
  });

  Future<AppUser> getCurrentUser(String sessionToken);

  Future<void> logOut(String sessionToken);
}

class ParseAuthRepository implements AuthRepository {
  const ParseAuthRepository(this._httpManager);

  final HttpManager _httpManager;

  @override
  Future<AuthSession> logIn({
    required String email,
    required String password,
  }) async {
    final response = await _httpManager.restRequest(
      url: Endpoints.signIn,
      method: HttpMethod.post,
      body: {
        'email': email.trim().toLowerCase(),
        'password': password,
      },
    );

    return _sessionFromResponse(_cloudResult(response));
  }

  @override
  Future<AuthSession> signUp({
    required String fullname,
    required String email,
    required String password,
    required String document,
    required String phone,
  }) async {
    final requestData = <String, dynamic>{
      'fullname': fullname.trim(),
      'email': email.trim().toLowerCase(),
      'password': password,
      'document': document.trim(),
      'phone': phone.trim(),
    };

    final response = await _httpManager.restRequest(
      url: Endpoints.signUp,
      method: HttpMethod.post,
      body: requestData,
    );

    return _sessionFromResponse(_cloudResult(response));
  }

  @override
  Future<AppUser> getCurrentUser(String sessionToken) async {
    final response = await _httpManager.restRequest(
      url: Endpoints.getUser,
      method: HttpMethod.post,
      sessionToken: sessionToken,
    );
    return AppUser.fromMap(_cloudResult(response));
  }

  @override
  Future<void> logOut(String sessionToken) async {
    await _httpManager.restRequest(
      url: Endpoints.logout,
      method: HttpMethod.post,
      sessionToken: sessionToken,
    );
  }

  AuthSession _sessionFromResponse(Map<String, dynamic> response) {
    final token =
        response['token']?.toString() ?? response['sessionToken']?.toString() ?? '';
    if (token.isEmpty) {
      throw const FormatException(
        'O servidor não retornou uma sessão válida.',
      );
    }

    return AuthSession(
      user: AppUser.fromMap(response),
      sessionToken: token,
    );
  }

  Map<String, dynamic> _cloudResult(Map<String, dynamic> response) {
    final result = response['result'];
    if (result is Map) return Map<String, dynamic>.from(result);

    throw const FormatException(
      'O servidor retornou uma resposta inválida.',
    );
  }
}

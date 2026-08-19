import 'package:sistem_cormex/Src/Connection/apiException.dart';
import 'package:sistem_cormex/Src/Models/appUser.dart';
import 'package:sistem_cormex/Src/Models/authSession.dart';
import 'package:sistem_cormex/Src/Pages/Auth/Repository/authRepository.dart';
import 'package:flutter/foundation.dart';
import 'package:signals/signals.dart';

class AuthController extends ChangeNotifier {
  AuthController(this._repository);

  final AuthRepository _repository;

  final isLoading = signal(false);
  final errorMessage = signal<String?>(null);
  final user = signal<AppUser?>(null);
  final sessionToken = signal<String?>(null);
  final mustConfigureCompany = signal(false);

  bool get isAuthenticated => sessionToken.value?.isNotEmpty == true;

  Future<bool> logIn({
    required String email,
    required String password,
  }) async {
    return _runAuthentication(
      () => _repository.logIn(email: email, password: password),
      companySetupRequired: false,
    );
  }

  Future<bool> signUp({
    required String fullname,
    required String email,
    required String password,
    required String document,
    required String phone,
  }) async {
    return _runAuthentication(
      () => _repository.signUp(
        fullname: fullname,
        email: email,
        password: password,
        document: document,
        phone: phone,
      ),
      companySetupRequired: true,
    );
  }

  Future<void> logOut() async {
    final token = sessionToken.value;
    if (token == null) return;

    isLoading.value = true;
    errorMessage.value = null;
    try {
      await _repository.logOut(token);
    } catch (_) {
      // Mesmo sem rede, a sessão local precisa ser encerrada.
    } finally {
      batch(() {
        user.value = null;
        sessionToken.value = null;
        mustConfigureCompany.value = false;
        isLoading.value = false;
      });
      notifyListeners();
    }
  }

  void clearError() => errorMessage.value = null;

  void replaceCurrentUser(AppUser value) {
    user.value = value;
    notifyListeners();
  }

  void completeCompanySetup() {
    if (!mustConfigureCompany.value) return;
    mustConfigureCompany.value = false;
    notifyListeners();
  }

  void requireCompanySetup() {
    if (mustConfigureCompany.value) return;
    mustConfigureCompany.value = true;
    notifyListeners();
  }

  Future<bool> _runAuthentication(
    Future<AuthSession> Function() request, {
    required bool companySetupRequired,
  }) async {
    batch(() {
      isLoading.value = true;
      errorMessage.value = null;
    });

    try {
      final session = await request();
      batch(() {
        user.value = session.user;
        sessionToken.value = session.sessionToken;
        mustConfigureCompany.value = companySetupRequired;
      });
      notifyListeners();
      return true;
    } on ApiException catch (error) {
      errorMessage.value = _friendlyMessage(error);
      return false;
    } on FormatException catch (error) {
      errorMessage.value = error.message.toString();
      return false;
    } catch (_) {
      errorMessage.value = 'Não foi possível concluir a autenticação.';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  String _friendlyMessage(ApiException error) {
    switch (error.code) {
      case 101:
        return 'E-mail ou senha incorretos.';
      case 202:
      case 203:
        return 'Já existe uma conta cadastrada com este e-mail.';
      case 209:
        return 'Sua sessão expirou. Entre novamente.';
      case 142:
        return error.message;
      default:
        return error.message;
    }
  }
}

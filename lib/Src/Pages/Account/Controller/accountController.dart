import 'package:signals/signals.dart';
import 'package:sistem_cormex/Src/Connection/apiException.dart';
import 'package:sistem_cormex/Src/Models/accountModels.dart';
import 'package:sistem_cormex/Src/Models/appUser.dart';
import 'package:sistem_cormex/Src/Pages/Account/Repository/accountRepository.dart';
import 'package:sistem_cormex/Src/Pages/Auth/Controller/authController.dart';

class AccountController {
  AccountController(this._repository, this._authController);

  final AccountRepository _repository;
  final AuthController _authController;
  String? _dataSessionToken;

  final loading = signal(false);
  final saving = signal(false);
  final error = signal<String?>(null);
  final workspace = signal<AccountWorkspace?>(null);

  final usersLoading = signal(false);
  final users = signal<List<AccountUser>>([]);
  final userActionLoading = signal(false);

  final paymentTermsLoading = signal(false);
  final paymentTerms = signal<List<PaymentTerm>>([]);
  final paymentTermActionLoading = signal(false);

  final logoUploading = signal(false);

  Future<void> initialize({
    bool includeUsers = false,
    bool includePaymentTerms = false,
  }) async {
    _synchronizeSession();
    if (workspace.value == null) await loadWorkspace();
    if (includeUsers && users.value.isEmpty) await loadUsers();
    if (includePaymentTerms && paymentTerms.value.isEmpty) {
      await loadPaymentTerms();
    }
  }

  Future<bool> loadWorkspace() async {
    batch(() {
      loading.value = true;
      error.value = null;
    });
    try {
      final result = await _repository.getWorkspace(
        sessionToken: _sessionToken,
      );
      workspace.value = result;
      _syncAuthUser(result.user);
      if (result.setupRequired) {
        _authController.requireCompanySetup();
      } else {
        _authController.completeCompanySetup();
      }
      return true;
    } catch (exception) {
      error.value = _messageFor(exception);
      return false;
    } finally {
      loading.value = false;
    }
  }

  Future<bool> updateProfile({
    required String fullname,
    required String phone,
    required String document,
  }) async {
    if (saving.value) return false;
    if (fullname.trim().length < 2) {
      error.value = 'Informe seu nome completo.';
      return false;
    }
    batch(() {
      saving.value = true;
      error.value = null;
    });
    try {
      final updated = await _repository.updateProfile(
        sessionToken: _sessionToken,
        fullname: fullname,
        phone: phone,
        document: document,
      );
      final current = workspace.value;
      if (current != null) workspace.value = current.copyWith(user: updated);
      _syncAuthUser(updated);
      return true;
    } catch (exception) {
      error.value = _messageFor(exception);
      return false;
    } finally {
      saving.value = false;
    }
  }

  Future<bool> saveCompany(CompanyProfile company) async {
    if (saving.value) return false;
    if (company.legalName.trim().length < 2 ||
        company.tradeName.trim().length < 2) {
      error.value = 'Informe a razão social e o nome fantasia.';
      return false;
    }
    if (company.document.replaceAll(RegExp(r'\D'), '').length < 11) {
      error.value = 'Informe um CPF ou CNPJ válido para a empresa.';
      return false;
    }
    batch(() {
      saving.value = true;
      error.value = null;
    });
    try {
      final result = await _repository.saveCompany(
        sessionToken: _sessionToken,
        company: company.toRequest(),
      );
      workspace.value = result;
      _syncAuthUser(result.user);
      _authController.completeCompanySetup();
      return true;
    } catch (exception) {
      error.value = _messageFor(exception);
      return false;
    } finally {
      saving.value = false;
    }
  }

  Future<bool> uploadLogo({
    required String mimeType,
    required String base64,
  }) async {
    if (logoUploading.value) return false;
    if (!const {'image/png', 'image/jpeg', 'image/webp'}.contains(mimeType)) {
      error.value = 'A imagem deve ser PNG, JPG ou WEBP.';
      return false;
    }
    batch(() {
      logoUploading.value = true;
      error.value = null;
    });
    try {
      final company = await _repository.uploadCompanyLogo(
        sessionToken: _sessionToken,
        mimeType: mimeType,
        base64: base64,
      );
      final current = workspace.value;
      if (current != null) workspace.value = current.copyWith(company: company);
      return true;
    } catch (exception) {
      error.value = _messageFor(exception);
      return false;
    } finally {
      logoUploading.value = false;
    }
  }

  Future<void> loadUsers() async {
    if (workspace.value?.company == null) return;
    batch(() {
      usersLoading.value = true;
      error.value = null;
    });
    try {
      final result = await _repository.listUsers(
        sessionToken: _sessionToken,
      );
      users.value = result.users;
      final current = workspace.value;
      if (current != null) {
        workspace.value = AccountWorkspace(
          user: current.user,
          company: current.company,
          permissions: current.permissions,
          setupRequired: current.setupRequired,
          userLimit: result.userLimit,
          activeUserCount: result.activeUserCount,
          availableRoles: current.availableRoles,
        );
      }
    } catch (exception) {
      error.value = _messageFor(exception);
    } finally {
      usersLoading.value = false;
    }
  }

  Future<bool> inviteUser({
    required String fullname,
    required String email,
    required String phone,
    required String role,
  }) async {
    if (userActionLoading.value) return false;
    if (fullname.trim().length < 2 ||
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email.trim())) {
      error.value = 'Informe o nome e um e-mail válido para o usuário.';
      return false;
    }
    batch(() {
      userActionLoading.value = true;
      error.value = null;
    });
    try {
      await _repository.inviteUser(
        sessionToken: _sessionToken,
        fullname: fullname,
        email: email,
        phone: phone,
        role: role,
      );
      await loadUsers();
      return true;
    } catch (exception) {
      error.value = _messageFor(exception);
      return false;
    } finally {
      userActionLoading.value = false;
    }
  }

  Future<bool> updateManagedUser({
    required AccountUser user,
    required String fullname,
    required String phone,
    required String role,
    required bool active,
  }) async {
    if (userActionLoading.value) return false;
    if (fullname.trim().length < 2) {
      error.value = 'Informe o nome completo do usuário.';
      return false;
    }
    batch(() {
      userActionLoading.value = true;
      error.value = null;
    });
    try {
      await _repository.updateUser(
        sessionToken: _sessionToken,
        userId: user.id,
        fullname: fullname,
        phone: phone,
        role: role,
        active: active,
      );
      await loadUsers();
      return true;
    } catch (exception) {
      error.value = _messageFor(exception);
      return false;
    } finally {
      userActionLoading.value = false;
    }
  }

  Future<bool> deactivateUser(AccountUser user) async {
    if (userActionLoading.value || user.owner) return false;
    batch(() {
      userActionLoading.value = true;
      error.value = null;
    });
    try {
      await _repository.deactivateUser(
        sessionToken: _sessionToken,
        userId: user.id,
      );
      await loadUsers();
      return true;
    } catch (exception) {
      error.value = _messageFor(exception);
      return false;
    } finally {
      userActionLoading.value = false;
    }
  }

  Future<void> loadPaymentTerms() async {
    if (workspace.value?.company == null) return;
    batch(() {
      paymentTermsLoading.value = true;
      error.value = null;
    });
    try {
      paymentTerms.value = await _repository.listPaymentTerms(
        sessionToken: _sessionToken,
      );
    } catch (exception) {
      error.value = _messageFor(exception);
    } finally {
      paymentTermsLoading.value = false;
    }
  }

  Future<bool> savePaymentTerm(PaymentTerm paymentTerm) async {
    if (paymentTermActionLoading.value) return false;
    if (paymentTerm.label.trim().isEmpty) {
      error.value = 'Informe a descrição da condição de pagamento.';
      return false;
    }
    if (paymentTerm.installments < 1 || paymentTerm.installments > 120) {
      error.value = 'Informe entre 1 e 120 parcelas.';
      return false;
    }
    batch(() {
      paymentTermActionLoading.value = true;
      error.value = null;
    });
    try {
      await _repository.savePaymentTerm(
        sessionToken: _sessionToken,
        paymentTerm: paymentTerm.toRequest(),
      );
      await loadPaymentTerms();
      return true;
    } catch (exception) {
      error.value = _messageFor(exception);
      return false;
    } finally {
      paymentTermActionLoading.value = false;
    }
  }

  Future<bool> deletePaymentTerm(PaymentTerm paymentTerm) async {
    final id = paymentTerm.id;
    if (id == null || paymentTermActionLoading.value) return false;
    batch(() {
      paymentTermActionLoading.value = true;
      error.value = null;
    });
    try {
      await _repository.deletePaymentTerm(
        sessionToken: _sessionToken,
        paymentTermId: id,
      );
      await loadPaymentTerms();
      return true;
    } catch (exception) {
      error.value = _messageFor(exception);
      return false;
    } finally {
      paymentTermActionLoading.value = false;
    }
  }

  void clearError() => error.value = null;

  void _syncAuthUser(AccountUser user) {
    final current = _authController.user.value;
    _authController.replaceCurrentUser(
      AppUser(
        objectId: user.id,
        name: user.fullname,
        email: user.email,
        username: current?.username ?? user.email,
        document: user.document,
        phone: user.phone,
        role: user.role,
        roleLabel: user.roleLabel,
        companyId: user.companyId,
        companyName: workspace.value?.company?.tradeName ?? '',
        sellerId: user.sellerId,
        ordersAccess: user.companyId != null && user.active,
        createdAt: user.createdAt,
      ),
    );
  }

  void _synchronizeSession() {
    final token = _authController.sessionToken.value;
    if (_dataSessionToken == token) return;
    _dataSessionToken = token;
    batch(() {
      workspace.value = null;
      users.value = [];
      paymentTerms.value = [];
      error.value = null;
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

  String _messageFor(Object exception) {
    if (exception is ApiException) {
      switch (exception.code) {
        case 209:
          return 'Sua sessão expirou. Entre novamente.';
        case 9300:
          return 'Você não possui permissão para alterar estes dados.';
        case 9301:
          return 'Não foi possível localizar os dados da conta.';
        case 9302:
          return 'Já existe uma empresa cadastrada com este documento.';
        case 9303:
          return 'Revise os dados informados.';
        case 9304:
          return 'O limite de usuários da empresa foi atingido.';
        case 9305:
          return 'Já existe um usuário cadastrado com este e-mail.';
        case 9306:
          return 'Esta condição de pagamento está sendo usada em pedidos.';
        case 9307:
          return 'A imagem deve ser PNG, JPG ou WEBP e ter no máximo 2 MB.';
        default:
          return exception.message;
      }
    }
    if (exception is FormatException) return exception.message.toString();
    return 'Não foi possível concluir a operação da conta.';
  }
}

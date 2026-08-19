import 'package:sistem_cormex/Src/Connection/endpoints.dart';
import 'package:sistem_cormex/Src/Connection/httpManager.dart';
import 'package:sistem_cormex/Src/Models/accountModels.dart';

abstract interface class AccountRepository {
  Future<AccountWorkspace> getWorkspace({required String sessionToken});

  Future<AccountUser> updateProfile({
    required String sessionToken,
    required String fullname,
    required String phone,
    required String document,
  });

  Future<AccountWorkspace> saveCompany({
    required String sessionToken,
    required Map<String, dynamic> company,
  });

  Future<CompanyProfile> uploadCompanyLogo({
    required String sessionToken,
    required String mimeType,
    required String base64,
  });

  Future<ManagedUsersResult> listUsers({required String sessionToken});

  Future<AccountUser> inviteUser({
    required String sessionToken,
    required String fullname,
    required String email,
    required String phone,
    required String role,
  });

  Future<AccountUser> updateUser({
    required String sessionToken,
    required String userId,
    required String fullname,
    required String phone,
    required String role,
    required bool active,
  });

  Future<void> deactivateUser({
    required String sessionToken,
    required String userId,
  });

  Future<List<PaymentTerm>> listPaymentTerms({
    required String sessionToken,
  });

  Future<PaymentTerm> savePaymentTerm({
    required String sessionToken,
    required Map<String, dynamic> paymentTerm,
  });

  Future<void> deletePaymentTerm({
    required String sessionToken,
    required String paymentTermId,
  });
}

class ParseAccountRepository implements AccountRepository {
  const ParseAccountRepository(this._httpManager);

  final HttpManager _httpManager;

  @override
  Future<AccountWorkspace> getWorkspace({
    required String sessionToken,
  }) async {
    final result = await _post(
      Endpoints.accountBootstrap,
      sessionToken,
      const {},
    );
    return AccountWorkspace.fromMap(result);
  }

  @override
  Future<AccountUser> updateProfile({
    required String sessionToken,
    required String fullname,
    required String phone,
    required String document,
  }) async {
    final result = await _post(
      Endpoints.profileUpdate,
      sessionToken,
      {
        'fullname': fullname.trim(),
        'phone': phone.trim(),
        'document': document.trim(),
      },
    );
    return AccountUser.fromMap(_nestedMap(result, 'user'));
  }

  @override
  Future<AccountWorkspace> saveCompany({
    required String sessionToken,
    required Map<String, dynamic> company,
  }) async {
    final result = await _post(
      Endpoints.companySave,
      sessionToken,
      company,
    );
    return AccountWorkspace.fromMap(result);
  }

  @override
  Future<CompanyProfile> uploadCompanyLogo({
    required String sessionToken,
    required String mimeType,
    required String base64,
  }) async {
    final result = await _post(
      Endpoints.companyLogoUpload,
      sessionToken,
      {'mimeType': mimeType, 'base64': base64},
    );
    return CompanyProfile.fromMap(_nestedMap(result, 'company'));
  }

  @override
  Future<ManagedUsersResult> listUsers({
    required String sessionToken,
  }) async {
    final result = await _post(
      Endpoints.accountUsersList,
      sessionToken,
      const {},
    );
    return ManagedUsersResult.fromMap(result);
  }

  @override
  Future<AccountUser> inviteUser({
    required String sessionToken,
    required String fullname,
    required String email,
    required String phone,
    required String role,
  }) async {
    final result = await _post(
      Endpoints.accountUserInvite,
      sessionToken,
      {
        'fullname': fullname.trim(),
        'email': email.trim().toLowerCase(),
        'phone': phone.trim(),
        'role': role,
      },
    );
    return AccountUser.fromMap(_nestedMap(result, 'user'));
  }

  @override
  Future<AccountUser> updateUser({
    required String sessionToken,
    required String userId,
    required String fullname,
    required String phone,
    required String role,
    required bool active,
  }) async {
    final result = await _post(
      Endpoints.accountUserUpdate,
      sessionToken,
      {
        'userId': userId,
        'fullname': fullname.trim(),
        'phone': phone.trim(),
        'role': role,
        'active': active,
      },
    );
    return AccountUser.fromMap(_nestedMap(result, 'user'));
  }

  @override
  Future<void> deactivateUser({
    required String sessionToken,
    required String userId,
  }) async {
    await _post(
      Endpoints.accountUserDeactivate,
      sessionToken,
      {'userId': userId},
    );
  }

  @override
  Future<List<PaymentTerm>> listPaymentTerms({
    required String sessionToken,
  }) async {
    final result = await _post(
      Endpoints.paymentTermsList,
      sessionToken,
      const {},
    );
    final values = result['paymentTerms'];
    if (values is! List) return <PaymentTerm>[];
    return values
        .whereType<Map>()
        .map((item) => PaymentTerm.fromMap(Map<String, dynamic>.from(item)))
        .toList();
  }

  @override
  Future<PaymentTerm> savePaymentTerm({
    required String sessionToken,
    required Map<String, dynamic> paymentTerm,
  }) async {
    final result = await _post(
      Endpoints.paymentTermSave,
      sessionToken,
      paymentTerm,
    );
    return PaymentTerm.fromMap(_nestedMap(result, 'paymentTerm'));
  }

  @override
  Future<void> deletePaymentTerm({
    required String sessionToken,
    required String paymentTermId,
  }) async {
    await _post(
      Endpoints.paymentTermDelete,
      sessionToken,
      {'paymentTermId': paymentTermId},
    );
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
      'O servidor retornou uma resposta inválida para Minha conta.',
    );
  }

  Map<String, dynamic> _nestedMap(
    Map<String, dynamic> result,
    String key,
  ) {
    final value = result[key];
    return value is Map ? Map<String, dynamic>.from(value) : result;
  }
}

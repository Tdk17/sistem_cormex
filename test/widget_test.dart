import 'package:sistem_cormex/Src/Dependencies/dependencies.dart';
import 'package:sistem_cormex/Src/Models/appUser.dart';
import 'package:sistem_cormex/Src/Models/authSession.dart';
import 'package:sistem_cormex/Src/Pages/Auth/Controller/authController.dart';
import 'package:sistem_cormex/Src/Pages/Auth/Repository/authRepository.dart';
import 'package:sistem_cormex/Src/Routes/appRouter.dart';
import 'package:sistem_cormex/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  setUp(() async {
    await getIt.reset();
    getIt.registerSingleton<AuthRepository>(_FakeAuthRepository());
    getIt.registerLazySingleton<AuthController>(
      () => AuthController(getIt<AuthRepository>()),
    );
    getIt.registerLazySingleton<GoRouter>(
      () => createAppRouter(getIt<AuthController>()),
    );
  });

  tearDown(() async {
    await getIt.reset();
  });

  testWidgets('alterna entre login e cadastro com go_router', (tester) async {
    await tester.pumpWidget(const ComerxApp());

    expect(find.text('Acesse sua operação comercial'), findsOneWidget);
    await tester.tap(find.text('Criar conta grátis'));
    await tester.pumpAndSettle();

    expect(
      find.text('Organize suas vendas desde o primeiro pedido'),
      findsOneWidget,
    );
    expect(find.byType(CheckboxListTile), findsOneWidget);
  });

  testWidgets('autentica e protege o dashboard', (tester) async {
    await tester.pumpWidget(const ComerxApp());

    await tester.enterText(find.byType(TextFormField).at(0), 'teste@comerx.com');
    await tester.enterText(find.byType(TextFormField).at(1), '123456');
    await tester.tap(find.text('Entrar no Comerx'));
    await tester.pumpAndSettle();

    expect(find.text('Olá, Pedro'), findsOneWidget);
  });
}

class _FakeAuthRepository implements AuthRepository {
  static const user = AppUser(
    objectId: 'user-1',
    name: 'Pedro',
    email: 'teste@comerx.com',
    username: 'teste@comerx.com',
  );

  @override
  Future<AuthSession> logIn({
    required String email,
    required String password,
  }) async {
    return const AuthSession(user: user, sessionToken: 'session-token');
  }

  @override
  Future<AuthSession> signUp({
    required String fullname,
    required String email,
    required String password,
    required String document,
    required String phone,
  }) async {
    return const AuthSession(user: user, sessionToken: 'session-token');
  }

  @override
  Future<AppUser> getCurrentUser(String sessionToken) async => user;

  @override
  Future<void> logOut(String sessionToken) async {}
}

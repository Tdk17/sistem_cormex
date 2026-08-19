# Comerx — base Flutter Web e mobile

Login e cadastro responsivos conectados às Cloud Functions do Parse/Back4App.

## Tecnologias

- `go_router`: rotas e proteção do dashboard.
- `dio`: comunicação HTTP com o Back4App.
- `signals`: estados de carregamento, erro, usuário e sessão.
- `get_it`: injeção de Dio, manager, repository, controller e router.

## Estrutura

```text
lib/
├── main.dart
└── Src/
    ├── Config/
    │   ├── appColors.dart
    │   ├── appConfig.dart
    │   └── appTheme.dart
    ├── Connection/
    │   ├── apiException.dart
    │   ├── endpoints.dart
    │   └── httpManager.dart
    ├── Dependencies/
    │   └── dependencies.dart
    ├── Models/
    │   ├── appUser.dart
    │   └── authSession.dart
    ├── Routes/
    │   └── appRouter.dart
    └── Pages/
        ├── Auth/
        │   ├── Components/
        │   ├── Controller/
        │   │   └── authController.dart
        │   ├── Repository/
        │   │   └── authRepository.dart
        │   ├── LogIn/
        │   │   └── logIn.dart
        │   ├── SignUp/
        │   │   └── signUp.dart
        │   └── authShell.dart
        └── Dashboard/
            └── dashboard.dart
```

## Configurar o Back4App

1. Crie um aplicativo separado para o Comerx no Back4App.
2. No painel do aplicativo, copie o `Application ID`, a `JavaScript Key` e a
   `REST API Key`.
3. Duplique `config/dev.example.json` com o nome `config/dev.json`.
4. Preencha somente o novo `config/dev.json` com as chaves do Comerx.

O arquivo real `config/dev.json` está ignorado pelo Git. Nunca coloque a
`Master Key` dentro do aplicativo Flutter.

Use esta estrutura:

```json
{
  "PARSE_SERVER_URL": "https://parseapi.back4app.com/",
  "PARSE_APPLICATION_ID": "SEU_APPLICATION_ID",
  "PARSE_JAVASCRIPT_KEY": "SUA_JAVASCRIPT_KEY",
  "PARSE_REST_API_KEY": "SUA_REST_API_KEY"
}
```

No Flutter Web é enviada a `JavaScript Key`; no Android/iOS é enviada a
`REST API Key`.

## Executar

Se ainda não existirem as pastas Web, Android e iOS:

```bash
flutter create .
```

Depois execute:

```bash
flutter pub get
flutter run -d chrome --dart-define-from-file=config/dev.json
```

No VS Code, selecione `Comerx Web (debug)` na área **Executar e Depurar** e
pressione `F5`. O arquivo `.vscode/launch.json` já passa o `dev.json` com
`toolArgs`, mantendo breakpoints, hot reload e o Console de Depuração.

Para Android:

```bash
flutter run --dart-define-from-file=config/dev.json
```

## Funcionamento atual

- O login chama `POST /functions/v1-sign-in`.
- O cadastro chama `POST /functions/v1-sign-up` e envia `fullname`, `email`,
  `password`, `document` e `phone`.
- A restauração do usuário chama `POST /functions/v1-get-user` com o token.
- O e-mail é usado como `username` pela Cloud Function.
- Cadastro e login recebem um `sessionToken` real do Back4App.
- O GoRouter impede acesso ao dashboard sem autenticação.
- O botão sair encerra a sessão remota e limpa os Signals locais.
- A sessão ainda é mantida apenas enquanto o aplicativo estiver aberto. O
  armazenamento seguro entre reinicializações entra na próxima etapa.

O aviso do Dio sobre requisição CORS preflight no navegador é esperado para
requisições JSON com cabeçalhos do Parse. Se a resposta ainda for `403`, abra
DevTools > Network e confirme se falhou o `OPTIONS` ou o `POST`; depois valide
o Application ID e a JavaScript Key do mesmo aplicativo.

## Testes

Os testes usam um repository falso e não acessam o banco real:

```bash
flutter test
```

import 'package:sistem_cormex/Src/Config/appConfig.dart';
import 'package:sistem_cormex/Src/Connection/httpManager.dart';
import 'package:sistem_cormex/Src/Pages/Auth/Controller/authController.dart';
import 'package:sistem_cormex/Src/Pages/Auth/Repository/authRepository.dart';
import 'package:sistem_cormex/Src/Pages/Account/Controller/accountController.dart';
import 'package:sistem_cormex/Src/Pages/Account/Repository/accountRepository.dart';
import 'package:sistem_cormex/Src/Pages/Account/Plans/Controller/billingController.dart';
import 'package:sistem_cormex/Src/Pages/Account/Plans/Repository/billingRepository.dart';
import 'package:sistem_cormex/Src/Pages/Clients/Controller/clientsController.dart';
import 'package:sistem_cormex/Src/Pages/Clients/Repository/clientsRepository.dart';
import 'package:sistem_cormex/Src/Pages/Dashboard/Controller/dashboardController.dart';
import 'package:sistem_cormex/Src/Pages/Dashboard/Repository/dashboardRepository.dart';
import 'package:sistem_cormex/Src/Pages/Orders/Controller/ordersController.dart';
import 'package:sistem_cormex/Src/Pages/Orders/Repository/ordersRepository.dart';
import 'package:sistem_cormex/Src/Pages/Products/Controller/productsController.dart';
import 'package:sistem_cormex/Src/Pages/Products/Repository/productsRepository.dart';
import 'package:sistem_cormex/Src/Pages/Tasks/Controller/tasksController.dart';
import 'package:sistem_cormex/Src/Pages/Tasks/Repository/tasksRepository.dart';
import 'package:sistem_cormex/Src/Pages/Logistics/Controller/logisticsController.dart';
import 'package:sistem_cormex/Src/Pages/Logistics/Repository/logisticsRepository.dart';
import 'package:sistem_cormex/Src/Routes/appRouter.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

final getIt = GetIt.instance;

void setupDependencies() {
  if (getIt.isRegistered<GoRouter>()) return;

  getIt.registerLazySingleton<Dio>(
    () => Dio(
      BaseOptions(
        baseUrl: AppConfig.parseServerUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 20),
      ),
    ),
  );

  getIt.registerLazySingleton<HttpManager>(
    () => HttpManager(getIt<Dio>()),
  );

  getIt.registerLazySingleton<AuthRepository>(
    () => ParseAuthRepository(getIt<HttpManager>()),
  );

  getIt.registerLazySingleton<AuthController>(
    () => AuthController(getIt<AuthRepository>()),
  );

  getIt.registerLazySingleton<AccountRepository>(
    () => ParseAccountRepository(getIt<HttpManager>()),
  );

  getIt.registerLazySingleton<AccountController>(
    () => AccountController(
      getIt<AccountRepository>(),
      getIt<AuthController>(),
    ),
  );

  getIt.registerLazySingleton<BillingRepository>(
    () => ParseBillingRepository(getIt<HttpManager>()),
  );

  getIt.registerLazySingleton<BillingController>(
    () => BillingController(
      getIt<BillingRepository>(),
      getIt<AuthController>(),
    ),
  );

  getIt.registerLazySingleton<ClientsRepository>(
    () => ParseClientsRepository(getIt<HttpManager>()),
  );

  getIt.registerLazySingleton<ClientsController>(
    () => ClientsController(
      getIt<ClientsRepository>(),
      getIt<AuthController>(),
    ),
  );

  getIt.registerLazySingleton<DashboardRepository>(
    () => ParseDashboardRepository(getIt<HttpManager>()),
  );

  getIt.registerLazySingleton<DashboardController>(
    () => DashboardController(
      getIt<DashboardRepository>(),
      getIt<AuthController>(),
    ),
  );

  getIt.registerLazySingleton<OrdersRepository>(
    () => ParseOrdersRepository(getIt<HttpManager>()),
  );

  getIt.registerLazySingleton<OrdersController>(
    () => OrdersController(
      getIt<OrdersRepository>(),
      getIt<AuthController>(),
    ),
  );

  getIt.registerLazySingleton<ProductsRepository>(
    () => ParseProductsRepository(getIt<HttpManager>()),
  );

  getIt.registerLazySingleton<ProductsController>(
    () => ProductsController(
      getIt<ProductsRepository>(),
      getIt<AuthController>(),
    ),
  );

  getIt.registerLazySingleton<TasksRepository>(
    () => ParseTasksRepository(getIt<HttpManager>()),
  );

  getIt.registerLazySingleton<TasksController>(
    () => TasksController(
      getIt<TasksRepository>(),
      getIt<AuthController>(),
    ),
  );

  getIt.registerLazySingleton<LogisticsRepository>(
    () => ParseLogisticsRepository(getIt<HttpManager>()),
  );

  getIt.registerLazySingleton<LogisticsController>(
    () => LogisticsController(
      getIt<LogisticsRepository>(),
      getIt<AuthController>(),
    ),
  );

  getIt.registerLazySingleton<GoRouter>(
    () => createAppRouter(getIt<AuthController>()),
  );
}

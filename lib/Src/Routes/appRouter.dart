import 'package:sistem_cormex/Src/Pages/Auth/Controller/authController.dart';
import 'package:sistem_cormex/Src/Pages/Auth/authShell.dart';
import 'package:sistem_cormex/Src/Pages/Account/account.dart';
import 'package:sistem_cormex/Src/Pages/Account/accountSection.dart';
import 'package:sistem_cormex/Src/Pages/Clients/ClientForm/clientForm.dart';
import 'package:sistem_cormex/Src/Pages/Clients/clients.dart';
import 'package:sistem_cormex/Src/Pages/Dashboard/dashboard.dart';
import 'package:sistem_cormex/Src/Pages/Orders/OrderForm/orderForm.dart';
import 'package:sistem_cormex/Src/Pages/Orders/orders.dart';
import 'package:sistem_cormex/Src/Pages/Products/ProductForm/productForm.dart';
import 'package:sistem_cormex/Src/Pages/Products/products.dart';
import 'package:sistem_cormex/Src/Pages/Tasks/tasks.dart';
import 'package:sistem_cormex/Src/Pages/Logistics/logistics.dart';
import 'package:go_router/go_router.dart';

abstract final class AppRoutes {
  static const root = '/';
  static const logIn = '/login';
  static const signUp = '/cadastro';
  static const dashboard = '/dashboard';
  static const dashboardReports = '/dashboard/relatorios';
  static const orders = '/pedidos';
  static const orderNew = '/pedidos/novo';
  static const clients = '/clientes';
  static const clientNew = '/clientes/novo';
  static const products = '/produtos';
  static const productNew = '/produtos/novo';
  static const tasks = '/tarefas';
  static const logistics = '/logistica';
  static const accountProfile = '/conta/perfil';
  static const accountCompany = '/conta/empresa';
  static const accountPlans = '/conta/plano';
  static const accountUsers = '/conta/usuarios';
  static const accountPaymentTerms = '/conta/condicoes-pagamento';

  static String orderById(String orderId) => '/pedidos/$orderId';
  static String clientById(String clientId) => '/clientes/$clientId';
  static String productById(String productId) => '/produtos/$productId';
}

GoRouter createAppRouter(AuthController authController) {
  return GoRouter(
    initialLocation: AppRoutes.logIn,
    refreshListenable: authController,
    redirect: (context, state) {
      final inAuth = state.matchedLocation == AppRoutes.logIn ||
          state.matchedLocation == AppRoutes.signUp;

      if (!authController.isAuthenticated && !inAuth) {
        return AppRoutes.logIn;
      }
      if (authController.isAuthenticated &&
          authController.mustConfigureCompany.value &&
          state.matchedLocation != AppRoutes.accountCompany) {
        return AppRoutes.accountCompany;
      }
      if (authController.isAuthenticated && inAuth) {
        return authController.mustConfigureCompany.value
            ? AppRoutes.accountCompany
            : AppRoutes.dashboard;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.root,
        redirect: (_, __) => authController.isAuthenticated
            ? AppRoutes.dashboard
            : AppRoutes.logIn,
      ),
      GoRoute(
        path: AppRoutes.logIn,
        builder: (_, __) => const AuthShell(mode: AuthMode.logIn),
      ),
      GoRoute(
        path: AppRoutes.signUp,
        builder: (_, __) => const AuthShell(mode: AuthMode.signUp),
      ),
      GoRoute(
        path: AppRoutes.accountProfile,
        builder: (_, __) => const AccountPage(section: AccountSection.profile),
      ),
      GoRoute(
        path: AppRoutes.accountCompany,
        builder: (_, __) => const AccountPage(section: AccountSection.company),
      ),
      GoRoute(
        path: AppRoutes.accountPlans,
        builder: (_, state) => AccountPage(
          section: AccountSection.plans,
          checkoutId: state.uri.queryParameters['checkout_id'],
          checkoutReturnStatus: state.uri.queryParameters['checkout'],
        ),
      ),
      GoRoute(
        path: AppRoutes.accountUsers,
        builder: (_, __) => const AccountPage(section: AccountSection.users),
      ),
      GoRoute(
        path: AppRoutes.accountPaymentTerms,
        builder: (_, __) => const AccountPage(section: AccountSection.paymentTerms),
      ),
      GoRoute(
        path: AppRoutes.clientNew,
        builder: (_, __) => const ClientFormPage(),
      ),
      GoRoute(
        path: '/clientes/:clientId',
        builder: (_, state) => ClientFormPage(
          clientId: state.pathParameters['clientId'],
        ),
      ),
      GoRoute(
        path: AppRoutes.clients,
        builder: (_, __) => const ClientsPage(),
      ),
      GoRoute(
        path: AppRoutes.productNew,
        builder: (_, __) => const ProductFormPage(),
      ),
      GoRoute(
        path: '/produtos/:productId',
        builder: (_, state) => ProductFormPage(
          productId: state.pathParameters['productId'],
        ),
      ),
      GoRoute(
        path: AppRoutes.products,
        builder: (_, __) => const ProductsPage(),
      ),
      GoRoute(
        path: AppRoutes.tasks,
        builder: (_, __) => const TasksPage(),
      ),
      GoRoute(
        path: AppRoutes.logistics,
        builder: (_, __) => const LogisticsPage(),
      ),
      GoRoute(
        path: AppRoutes.dashboardReports,
        builder: (_, __) => const DashboardPage(
          section: DashboardSection.reports,
        ),
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        builder: (_, __) => const DashboardPage(),
      ),
      GoRoute(
        path: AppRoutes.orderNew,
        builder: (_, __) => const OrderFormPage(),
      ),
      GoRoute(
        path: '/pedidos/:orderId',
        builder: (_, state) => OrderFormPage(
          orderId: state.pathParameters['orderId'],
        ),
      ),
      GoRoute(
        path: AppRoutes.orders,
        builder: (_, __) => const OrdersPage(),
      ),
    ],
  );
}

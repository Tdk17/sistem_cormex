import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals/signals_flutter.dart';
import 'package:sistem_cormex/Src/Config/appColors.dart';
import 'package:sistem_cormex/Src/Dependencies/dependencies.dart';
import 'package:sistem_cormex/Src/Pages/Account/Plans/Controller/billingController.dart';
import 'package:sistem_cormex/Src/Pages/Auth/Controller/authController.dart';
import 'package:sistem_cormex/Src/Routes/appRouter.dart';

class DashboardSidebar extends StatelessWidget {
  const DashboardSidebar({
    super.key,
    required this.compact,
    this.insideDrawer = false,
  });

  final bool compact;
  final bool insideDrawer;

  static const _destinations = <_SidebarDestination>[
    _SidebarDestination(
      'Indicadores',
      Icons.space_dashboard_outlined,
      route: AppRoutes.dashboard,
      feature: 'dashboard',
    ),
    _SidebarDestination(
      'Pedidos',
      Icons.receipt_long_outlined,
      route: AppRoutes.orders,
      feature: 'orders',
    ),
    _SidebarDestination(
      'Clientes',
      Icons.groups_2_outlined,
      route: AppRoutes.clients,
      feature: 'clients',
    ),
    _SidebarDestination(
      'Produtos',
      Icons.inventory_2_outlined,
      route: AppRoutes.products,
      feature: 'products',
    ),
    _SidebarDestination('Portal B2B', Icons.storefront_outlined),
    _SidebarDestination(
      'Tarefas',
      Icons.task_alt_outlined,
      route: AppRoutes.tasks,
      feature: 'tasks',
    ),
    _SidebarDestination(
      'Logística',
      Icons.route_outlined,
      route: AppRoutes.logistics,
      feature: 'logistics.routes',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final billingController = getIt<BillingController>();
    if (billingController.catalog.value == null &&
        !billingController.loading.value) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        billingController.initialize();
      });
    }
    return Material(
      color: Colors.white,
      child: Container(
        width: compact ? 82 : 224,
        decoration: const BoxDecoration(
          border: Border(right: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          right: false,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  compact ? 20 : 22,
                  18,
                  compact ? 20 : 18,
                  22,
                ),
                child: _ComerxBrand(compact: compact),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  itemCount: _destinations.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 5),
                  itemBuilder: (context, index) {
                    final destination = _destinations[index];
                    return Watch((context) {
                      final selected = destination.route == AppRoutes.dashboard
                          ? location.startsWith(AppRoutes.dashboard)
                          : destination.route != null &&
                              location.startsWith(destination.route!);
                      final catalog = billingController.catalog.value;
                      final subscription = catalog?.subscription;
                      final locked = catalog != null &&
                          destination.feature != null &&
                          (subscription == null ||
                              !subscription.grantsAccess ||
                              !subscription.hasFeature(destination.feature!));
                      return _NavigationButton(
                        compact: compact,
                        destination: destination,
                        selected: selected,
                        locked: locked,
                        onTap: () {
                          final router = GoRouter.of(context);
                          if (insideDrawer) Navigator.of(context).pop();
                          if (locked) {
                            router.go(AppRoutes.accountPlans);
                            return;
                          }
                          final route = destination.route;
                          if (route != null) {
                            router.go(route);
                            return;
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${destination.label} será conectado na próxima etapa.',
                              ),
                            ),
                          );
                        },
                      );
                    });
                  },
                ),
              ),
              if (!compact)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: InkWell(
                    onTap: () => context.go(AppRoutes.accountPlans),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.navy,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.workspace_premium_outlined, color: AppColors.lime, size: 19),
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Plano e módulos',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  'Contrate novos recursos',
                                  style: TextStyle(color: Colors.white60, fontSize: 9.5),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded, color: Colors.white54, size: 18),
                        ],
                      ),
                    ),
                  ),
                ),
              _AccountButton(compact: compact),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class DashboardTopBar extends StatelessWidget implements PreferredSizeWidget {
  const DashboardTopBar({super.key, required this.mobile});

  final bool mobile;

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  Widget build(BuildContext context) {
    final authController = getIt<AuthController>();

    return AppBar(
      primary: mobile,
      toolbarHeight: 70,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: AppColors.ink,
      shape: const Border(
        bottom: BorderSide(color: AppColors.border),
      ),
      titleSpacing: mobile ? 0 : 24,
      title: mobile
          ? const _ComerxBrand(compact: false)
          : Watch((context) {
              final name = authController.user.value?.name.trim();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name == null || name.isEmpty ? 'Olá' : 'Olá, $name',
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Text(
                    'Acompanhe o ritmo da sua operação',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              );
            }),
      actions: [
        if (!mobile)
          Container(
            width: 230,
            height: 40,
            margin: const EdgeInsets.only(right: 10),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Busca rápida',
                hintStyle: const TextStyle(fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                filled: true,
                fillColor: AppColors.canvas,
                contentPadding: EdgeInsets.zero,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
          ),
        IconButton(
          tooltip: 'Notificações',
          onPressed: () {},
          icon: const Badge(
            smallSize: 7,
            child: Icon(Icons.notifications_none_rounded),
          ),
        ),
        PopupMenuButton<String>(
          tooltip: 'Minha conta',
          onSelected: (value) {
            if (value == 'profile') context.go(AppRoutes.accountProfile);
            if (value == 'plans') context.go(AppRoutes.accountPlans);
            if (value == 'logout') authController.logOut();
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'profile', child: Text('Minha conta')),
            PopupMenuItem(value: 'plans', child: Text('Plano e módulos')),
            PopupMenuItem(value: 'logout', child: Text('Sair')),
          ],
          child: Container(
            width: 38,
            height: 38,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            decoration: const BoxDecoration(
              color: AppColors.navy,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Watch((context) {
              final name = authController.user.value?.name.trim();
              final initial = name == null || name.isEmpty
                  ? 'C'
                  : name.substring(0, 1).toUpperCase();
              return Text(
                initial,
                style: const TextStyle(
                  color: AppColors.lime,
                  fontWeight: FontWeight.w800,
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _ComerxBrand extends StatelessWidget {
  const _ComerxBrand({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.navy,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.rotate(
                angle: -.48,
                child: Container(
                  width: 16,
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.lime,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              Transform.translate(
                offset: const Offset(7, 5),
                child: const CircleAvatar(
                  radius: 3.5,
                  backgroundColor: AppColors.cyan,
                ),
              ),
            ],
          ),
        ),
        if (!compact) ...[
          const SizedBox(width: 10),
          const Text(
            'Cormex Exchange',
            style: TextStyle(
              color: AppColors.navy,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ],
    );
  }
}

class _NavigationButton extends StatelessWidget {
  const _NavigationButton({
    required this.compact,
    required this.destination,
    required this.selected,
    required this.locked,
    required this.onTap,
  });

  final bool compact;
  final _SidebarDestination destination;
  final bool selected;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: compact
          ? locked
              ? '${destination.label} — contrate este módulo'
              : destination.label
          : '',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 48,
          padding: EdgeInsets.symmetric(horizontal: compact ? 0 : 14),
          decoration: BoxDecoration(
            color: selected ? AppColors.navy : Colors.transparent,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Row(
            mainAxisAlignment:
                compact ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Icon(
                destination.icon,
                size: 20,
                color: selected
                    ? AppColors.lime
                    : locked
                        ? AppColors.muted.withOpacity(.55)
                        : AppColors.muted,
              ),
              if (!compact) ...[
                const SizedBox(width: 12),
                Text(
                  destination.label,
                  style: TextStyle(
                    color: selected
                        ? Colors.white
                        : locked
                            ? AppColors.muted
                            : AppColors.ink,
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
                if (locked) ...[
                  const Spacer(),
                  const Icon(
                    Icons.lock_outline_rounded,
                    size: 14,
                    color: AppColors.muted,
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountButton extends StatelessWidget {
  const _AccountButton({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final selected = location.startsWith('/conta/');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: InkWell(
        onTap: () => context.go(AppRoutes.accountProfile),
        borderRadius: BorderRadius.circular(13),
        child: Container(
          height: 46,
          decoration: BoxDecoration(
            color: selected ? AppColors.navy : Colors.transparent,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Row(
            mainAxisAlignment:
                compact ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              const SizedBox(width: 13),
              Icon(Icons.manage_accounts_outlined, size: 20, color: selected ? AppColors.lime : AppColors.muted),
              if (!compact) ...[
                const SizedBox(width: 12),
                Text(
                  'Minha conta',
                  style: TextStyle(
                    color: selected ? Colors.white : AppColors.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarDestination {
  const _SidebarDestination(
    this.label,
    this.icon, {
    this.route,
    this.feature,
  });

  final String label;
  final IconData icon;
  final String? route;
  final String? feature;
}

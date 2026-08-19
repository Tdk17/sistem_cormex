import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals/signals_flutter.dart';
import 'package:sistem_cormex/Src/Config/appColors.dart';
import 'package:sistem_cormex/Src/Pages/Dashboard/Components/dashboardFormatters.dart';
import 'package:sistem_cormex/Src/Pages/Dashboard/Controller/dashboardController.dart';
import 'package:sistem_cormex/Src/Routes/appRouter.dart';

class DashboardPageHeading extends StatelessWidget {
  const DashboardPageHeading({
    super.key,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.actionIcon,
    required this.onAction,
  });

  final String title;
  final String description;
  final String actionLabel;
  final IconData actionIcon;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 620;
        final titleArea = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: AppColors.ink,
                fontSize: narrow ? 25 : 29,
                height: 1.1,
                fontWeight: FontWeight.w900,
                letterSpacing: -.7,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 13.5,
              ),
            ),
          ],
        );

        final action = FilledButton.icon(
          onPressed: onAction,
          icon: Icon(actionIcon, size: 18),
          label: Text(actionLabel),
          style: FilledButton.styleFrom(
            foregroundColor: AppColors.navy,
            backgroundColor: AppColors.lime,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w800),
          ),
        );

        if (narrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleArea,
              const SizedBox(height: 16),
              SizedBox(width: double.infinity, child: action),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: titleArea),
            const SizedBox(width: 20),
            action,
          ],
        );
      },
    );
  }
}

class DashboardBanner extends StatelessWidget {
  const DashboardBanner({super.key, required this.controller});

  final DashboardController controller;

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      if (!controller.bannerVisible.value) return const SizedBox.shrink();
      final overview = controller.overview.value;
      final change = overview?.summary.grossSalesChangePercent;
      final comparison = change == null
          ? 'Os dados comerciais serão atualizados assim que a API responder.'
          : change >= 0
              ? 'As vendas cresceram ${formatPercent(change)} em relação ao período anterior.'
              : 'As vendas variaram ${formatPercent(change)} em relação ao período anterior.';

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.navy, AppColors.navySoft],
          ),
          borderRadius: BorderRadius.circular(17),
          boxShadow: [
            BoxShadow(
              color: AppColors.navy.withOpacity(.12),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.lime.withOpacity(.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.insights_rounded, color: AppColors.lime),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Seu resumo comercial está pronto',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    comparison,
                    style: const TextStyle(
                      color: Color(0xFFB7CBD5),
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => controller.loadOverview(force: true),
              child: const Text(
                'Atualizar',
                style: TextStyle(
                  color: AppColors.lime,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Fechar',
              onPressed: controller.closeBanner,
              icon: const Icon(Icons.close_rounded, color: Colors.white70),
            ),
          ],
        ),
      );
    });
  }
}

class DashboardTabs extends StatelessWidget {
  const DashboardTabs({super.key, required this.reportsSelected});

  final bool reportsSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.fromLTRB(8, 7, 8, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _DashboardTab(
            label: 'Painel',
            icon: Icons.dashboard_outlined,
            selected: !reportsSelected,
            onTap: () => context.go(AppRoutes.dashboard),
          ),
          _DashboardTab(
            label: 'Relatórios',
            icon: Icons.analytics_outlined,
            selected: reportsSelected,
            onTap: () => context.go(AppRoutes.dashboardReports),
          ),
        ],
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  const _DashboardTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
      child: Container(
        height: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? AppColors.cyan : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? AppColors.navy : AppColors.muted,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.navy : AppColors.muted,
                fontSize: 13,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardCard extends StatelessWidget {
  const DashboardCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:sistem_cormex/Src/Config/appColors.dart';
import 'package:sistem_cormex/Src/Dependencies/dependencies.dart';
import 'package:sistem_cormex/Src/Pages/Dashboard/Components/dashboardCommon.dart';
import 'package:sistem_cormex/Src/Pages/Dashboard/Components/dashboardNavigation.dart';
import 'package:sistem_cormex/Src/Pages/Dashboard/Components/dashboardPanel.dart';
import 'package:sistem_cormex/Src/Pages/Dashboard/Components/dashboardReports.dart';
import 'package:sistem_cormex/Src/Pages/Dashboard/Controller/dashboardController.dart';

enum DashboardSection { panel, reports }

class DashboardPage extends StatefulWidget {
  const DashboardPage({
    super.key,
    this.section = DashboardSection.panel,
  });

  final DashboardSection section;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late final DashboardController controller;

  @override
  void initState() {
    super.initState();
    controller = getIt<DashboardController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.initialize(
        includeReports: widget.section == DashboardSection.reports,
      );
    });
  }

  @override
  void didUpdateWidget(covariant DashboardPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.section != widget.section) {
      controller.initialize(
        includeReports: widget.section == DashboardSection.reports,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportsSelected = widget.section == DashboardSection.reports;

    return LayoutBuilder(
      builder: (context, constraints) {
        final mobile = constraints.maxWidth < 760;
        final compactNavigation = constraints.maxWidth < 1120;

        return Scaffold(
          backgroundColor: AppColors.canvas,
          drawer: mobile
              ? Drawer(
                  width: 254,
                  child: DashboardSidebar(
                    compact: false,
                    insideDrawer: true,
                  ),
                )
              : null,
          appBar: mobile ? const DashboardTopBar(mobile: true) : null,
          body: Row(
            children: [
              if (!mobile)
                DashboardSidebar(
                  compact: compactNavigation,
                ),
              Expanded(
                child: Column(
                  children: [
                    if (!mobile) const DashboardTopBar(mobile: false),
                    Expanded(
                      child: _DashboardContent(
                        controller: controller,
                        reportsSelected: reportsSelected,
                        mobile: mobile,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.controller,
    required this.reportsSelected,
    required this.mobile,
  });

  final DashboardController controller;
  final bool reportsSelected;
  final bool mobile;

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          mobile ? 14 : 24,
          mobile ? 18 : 24,
          mobile ? 14 : 24,
          32,
        ),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DashboardPageHeading(
                  title:
                      reportsSelected ? 'Central de relatórios' : 'Visão comercial',
                  description: reportsSelected
                      ? 'Encontre dados estratégicos para cada área da operação.'
                      : 'Indicadores essenciais para decisões mais rápidas e precisas.',
                  actionLabel:
                      reportsSelected ? 'Criar relatório' : 'Adicionar indicador',
                  actionIcon: reportsSelected
                      ? Icons.add_chart_rounded
                      : Icons.add_rounded,
                  onAction: () {
                    reportsSelected
                        ? showCreateDashboardReportDialog(context, controller)
                        : showDashboardIndicatorDialog(context, controller);
                  },
                ),
                const SizedBox(height: 18),
                DashboardBanner(controller: controller),
                const SizedBox(height: 16),
                DashboardTabs(reportsSelected: reportsSelected),
                const SizedBox(height: 16),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: reportsSelected
                      ? DashboardReports(
                          key: const ValueKey('reports'),
                          controller: controller,
                        )
                      : DashboardPanel(
                          key: const ValueKey('panel'),
                          controller: controller,
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';
import 'package:sistem_cormex/Src/Config/appColors.dart';
import 'package:sistem_cormex/Src/Models/dashboardModels.dart';
import 'package:sistem_cormex/Src/Pages/Dashboard/Components/dashboardCommon.dart';
import 'package:sistem_cormex/Src/Pages/Dashboard/Components/dashboardFormatters.dart';
import 'package:sistem_cormex/Src/Pages/Dashboard/Controller/dashboardController.dart';

class DashboardPanel extends StatelessWidget {
  const DashboardPanel({super.key, required this.controller});

  final DashboardController controller;

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final loading = controller.isLoading.value;
      final error = controller.errorMessage.value;
      final data = controller.overview.value;

      if (loading && data == null) {
        return const _PanelLoading();
      }
      if (data == null) {
        return _PanelMessage(
          icon: Icons.cloud_off_outlined,
          title: 'Não foi possível carregar o Painel',
          message: error ?? 'A API não retornou dados para o período.',
          buttonLabel: 'Tentar novamente',
          onPressed: () => controller.loadOverview(force: true),
        );
      }

      final visible = controller.visibleIndicators.value;
      final showAll = visible.isEmpty;
      bool show(String key) => showAll || visible.contains(key);

      return Column(
        children: [
          if (error != null) ...[
            _InlineError(
              message: error,
              onRetry: () => controller.loadOverview(force: true),
            ),
            const SizedBox(height: 16),
          ],
          if (loading) const LinearProgressIndicator(minHeight: 2),
          _DashboardFilters(controller: controller, data: data),
          const SizedBox(height: 16),
          _MetricGrid(
            summary: data.summary,
            visible: {
              if (show('grossSales')) 'grossSales',
              if (show('orders')) 'orders',
              if (show('activeClients')) 'activeClients',
              if (show('averageTicket')) 'averageTicket',
            },
          ),
          if (show('salesEvolution') || show('goal')) ...[
            const SizedBox(height: 16),
            _SalesOverview(
              evolution: data.salesEvolution,
              goal: data.goal,
              period: data.selectedPeriod,
              showChart: show('salesEvolution'),
              showGoal: show('goal'),
            ),
          ],
          if (show('clientPortfolio') ||
              show('positivation') ||
              show('clientAbc')) ...[
            const SizedBox(height: 16),
            _IndicatorGrid(
              portfolio: data.clientPortfolio,
              positivation: data.positivation,
              clientAbc: data.clientAbc,
              showPortfolio: show('clientPortfolio'),
              showPositivation: show('positivation'),
              showClientAbc: show('clientAbc'),
            ),
          ],
          if (data.generatedAt != null) ...[
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Dados atualizados em ${formatReportValue(data.generatedAt!.toIso8601String(), 'datetime')}',
                style: const TextStyle(color: AppColors.muted, fontSize: 10.5),
              ),
            ),
          ],
        ],
      );
    });
  }
}

Future<void> showDashboardIndicatorDialog(
  BuildContext context,
  DashboardController controller,
) async {
  const options = <String, String>{
    'grossSales': 'Vendido no mês',
    'orders': 'Pedidos emitidos',
    'activeClients': 'Clientes ativos',
    'averageTicket': 'Ticket médio',
    'salesEvolution': 'Evolução de vendas',
    'goal': 'Meta comercial',
    'clientPortfolio': 'Carteira de clientes',
    'positivation': 'Cobertura de positivação',
    'clientAbc': 'Curva ABC de clientes',
  };
  final selected = controller.visibleIndicators.value.isEmpty
      ? options.keys.toSet()
      : controller.visibleIndicators.value.toSet();

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Indicadores do Painel'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Escolha os indicadores que deseja visualizar. A preferência será salva na API.',
                    style: TextStyle(color: AppColors.muted, fontSize: 12.5),
                  ),
                ),
                const SizedBox(height: 12),
                for (final entry in options.entries)
                  CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(entry.value),
                    value: selected.contains(entry.key),
                    onChanged: (checked) {
                      setState(() {
                        checked == true
                            ? selected.add(entry.key)
                            : selected.remove(entry.key);
                      });
                    },
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          Watch((context) {
            final saving = controller.preferencesSaving.value;
            return FilledButton(
              onPressed: saving || selected.isEmpty
                  ? null
                  : () async {
                      final success = await controller.savePreferences(
                        options.keys.where(selected.contains).toList(),
                      );
                      if (success && dialogContext.mounted) {
                        Navigator.pop(dialogContext);
                      }
                    },
              child: saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Salvar'),
            );
          }),
        ],
      ),
    ),
  );
}

class _DashboardFilters extends StatelessWidget {
  const _DashboardFilters({required this.controller, required this.data});

  final DashboardController controller;
  final DashboardOverview data;

  @override
  Widget build(BuildContext context) {
    final periods = [...data.filterOptions.periods];
    if (!periods.any((item) => item.value == controller.selectedPeriod.value)) {
      periods.add(
        DashboardPeriodOption(
          value: controller.selectedPeriod.value,
          label: periodLabel(controller.selectedPeriod.value),
        ),
      );
    }

    return DashboardCard(
      padding: const EdgeInsets.all(14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 720;
          final period = _FilterDropdown<String>(
            label: 'Período',
            value: controller.selectedPeriod.value,
            items: {
              for (final item in periods) item.value: item.label,
            },
            onChanged: controller.changePeriod,
          );
          final seller = _FilterDropdown<String?>(
            label: 'Equipe comercial',
            value: controller.selectedSellerId.value,
            items: {
              null: 'Todos os vendedores',
              for (final item in data.filterOptions.sellers.where((e) => e.active))
                item.id: item.name,
            },
            onChanged: controller.changeSeller,
          );
          final refresh = SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () => controller.loadOverview(force: true),
              icon: const Icon(Icons.refresh_rounded, size: 19),
              label: const Text('Atualizar'),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          );

          if (narrow) {
            return Column(
              children: [
                period,
                const SizedBox(height: 10),
                seller,
                const SizedBox(height: 10),
                SizedBox(width: double.infinity, child: refresh),
              ],
            );
          }
          return Row(
            children: [
              Expanded(flex: 2, child: period),
              const SizedBox(width: 10),
              Expanded(flex: 3, child: seller),
              const SizedBox(width: 10),
              refresh,
            ],
          );
        },
      ),
    );
  }
}

class _FilterDropdown<T> extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T value;
  final Map<T, String> items;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: .5,
            ),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              isDense: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
              items: items.entries
                  .map(
                    (entry) => DropdownMenuItem<T>(
                      value: entry.key,
                      child: Text(entry.value, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              onChanged: (item) {
                if (item != null || items.containsKey(null)) onChanged(item as T);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.summary, required this.visible});

  final DashboardSummary summary;
  final Set<String> visible;

  @override
  Widget build(BuildContext context) {
    final metrics = <_MetricData>[
      if (visible.contains('grossSales'))
        _MetricData(
          'Vendido no mês',
          formatCurrency(summary.grossSales),
          formatPercent(summary.grossSalesChangePercent, showSign: true),
          Icons.trending_up_rounded,
          AppColors.cyan,
        ),
      if (visible.contains('orders'))
        _MetricData(
          'Pedidos emitidos',
          '${summary.orderCount}',
          '+${summary.ordersToday} hoje',
          Icons.receipt_long_outlined,
          const Color(0xFF7459D9),
        ),
      if (visible.contains('activeClients'))
        _MetricData(
          'Clientes ativos',
          '${summary.activeClientCount}',
          '${formatPercent(summary.activeClientPercent)} da carteira',
          Icons.groups_2_outlined,
          const Color(0xFF38B87C),
        ),
      if (visible.contains('averageTicket'))
        _MetricData(
          'Ticket médio',
          formatCurrency(summary.averageTicket),
          formatPercent(summary.averageTicketChangePercent, showSign: true),
          Icons.payments_outlined,
          const Color(0xFFFFA928),
        ),
    ];
    if (metrics.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1120
            ? math.min(4, metrics.length)
            : constraints.maxWidth >= 560
                ? math.min(2, metrics.length)
                : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: metrics.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            mainAxisExtent: 112,
          ),
          itemBuilder: (_, index) => _MetricCard(data: metrics[index]),
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.data});
  final _MetricData data;

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      padding: const EdgeInsets.all(17),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: data.color.withOpacity(.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(data.icon, color: data.color, size: 22),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data.label,
                    style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  data.value,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  data.comparison,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: data.color,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SalesOverview extends StatelessWidget {
  const _SalesOverview({
    required this.evolution,
    required this.goal,
    required this.period,
    required this.showChart,
    required this.showGoal,
  });

  final DashboardSalesEvolution evolution;
  final DashboardGoal? goal;
  final String period;
  final bool showChart;
  final bool showGoal;

  @override
  Widget build(BuildContext context) {
    final chart = SizedBox(
      height: 390,
      child: _SalesChartCard(evolution: evolution, goal: goal),
    );
    final goalCard = SizedBox(
      height: 390,
      child: _SalesGoalCard(goal: goal, period: period),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (showChart && !showGoal) return chart;
        if (!showChart && showGoal) return goalCard;
        if (constraints.maxWidth < 920 && showChart && showGoal) {
          return Column(
            children: [
              chart,
              const SizedBox(height: 16),
              goalCard,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 7, child: chart),
            const SizedBox(width: 16),
            Expanded(flex: 3, child: goalCard),
          ],
        );
      },
    );
  }
}

class _SalesChartCard extends StatelessWidget {
  const _SalesChartCard({required this.evolution, required this.goal});
  final DashboardSalesEvolution evolution;
  final DashboardGoal? goal;

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeader(
            title: 'Evolução de vendas',
            subtitle: 'Realizado e projeção até o fim do mês',
            icon: Icons.show_chart_rounded,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: evolution.actual.isEmpty && evolution.forecast.isEmpty
                ? const Center(child: Text('Sem vendas para o período.'))
                : CustomPaint(
                    size: Size.infinite,
                    painter: _SalesChartPainter(evolution, goal),
                  ),
          ),
          const SizedBox(height: 10),
          const Wrap(
            spacing: 18,
            runSpacing: 8,
            children: [
              _LegendDot(color: AppColors.cyan, label: 'Vendas realizadas'),
              _LegendDot(color: Color(0xFFFFA928), label: 'Projeção'),
              _LegendDot(color: AppColors.border, label: 'Meta do mês'),
            ],
          ),
        ],
      ),
    );
  }
}

class _SalesGoalCard extends StatelessWidget {
  const _SalesGoalCard({required this.goal, required this.period});
  final DashboardGoal? goal;
  final String period;

  @override
  Widget build(BuildContext context) {
    final data = goal;
    return DashboardCard(
      child: data == null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CardHeader(
                  title: 'Meta comercial',
                  subtitle: periodLabel(period),
                  icon: Icons.flag_outlined,
                ),
                const Expanded(
                  child: Center(
                    child: Text(
                      'Nenhuma meta configurada para este período.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.muted),
                    ),
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CardHeader(
                  title: 'Meta comercial',
                  subtitle: periodLabel(period),
                  icon: Icons.flag_outlined,
                ),
                const SizedBox(height: 24),
                Text(
                  formatCurrency(data.achievedValue),
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'de ${formatCurrency(data.targetValue)} previstos',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12.5),
                ),
                const SizedBox(height: 22),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    minHeight: 11,
                    value: (data.progressPercent / 100)
                        .clamp(0.0, 1.0)
                        .toDouble(),
                    color: AppColors.lime,
                    backgroundColor: AppColors.field,
                  ),
                ),
                const SizedBox(height: 9),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${formatPercent(data.progressPercent)} alcançado',
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${formatCurrency(data.remainingValue)} restantes',
                      style: const TextStyle(fontSize: 10.5),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.canvas,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ritmo necessário · ${data.remainingBusinessDays} dias úteis',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 10.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${formatCurrency(data.requiredPerBusinessDay)} por dia',
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _IndicatorGrid extends StatelessWidget {
  const _IndicatorGrid({
    required this.portfolio,
    required this.positivation,
    required this.clientAbc,
    required this.showPortfolio,
    required this.showPositivation,
    required this.showClientAbc,
  });

  final DashboardBreakdown portfolio;
  final DashboardPositivation positivation;
  final DashboardBreakdown clientAbc;
  final bool showPortfolio;
  final bool showPositivation;
  final bool showClientAbc;

  @override
  Widget build(BuildContext context) {
    final indicators = <_DonutData>[
      if (showPortfolio)
        _DonutData(
          title: 'Carteira de clientes',
          value: '${portfolio.total}',
          caption: 'clientes',
          segments: _segments(portfolio.segments, const [
            Color(0xFF38B87C),
            Color(0xFFFFC94A),
            Color(0xFFE56F72),
          ]),
        ),
      if (showPositivation)
        _DonutData(
          title: 'Cobertura de positivação',
          value: formatPercent(positivation.progressPercent),
          caption: '${positivation.positivatedClients} clientes',
          segments: _segments(positivation.segments, const [
            AppColors.cyan,
            Color(0xFF7459D9),
            AppColors.border,
          ]),
        ),
      if (showClientAbc)
        _DonutData(
          title: 'Curva ABC de clientes',
          value: '${clientAbc.total}',
          caption: clientAbc.referenceMonths == null
              ? 'classificados'
              : 'últimos ${clientAbc.referenceMonths} meses',
          segments: _segments(clientAbc.segments, const [
            AppColors.navy,
            Color(0xFF7459D9),
            Color(0xFFD7C8F2),
          ]),
        ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1050
            ? math.min(3, indicators.length)
            : constraints.maxWidth >= 620
                ? math.min(2, indicators.length)
                : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: indicators.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: math.max(1, columns),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            mainAxisExtent: 300,
          ),
          itemBuilder: (_, index) => _DonutIndicatorCard(data: indicators[index]),
        );
      },
    );
  }

  static List<_DonutSegment> _segments(
    List<DashboardSegment> data,
    List<Color> colors,
  ) {
    return [
      for (var index = 0; index < data.length; index++)
        _DonutSegment(
          data[index].percent / 100,
          colors[index % colors.length],
          '${data[index].count} ${data[index].label}',
        ),
    ];
  }
}

class _DonutIndicatorCard extends StatelessWidget {
  const _DonutIndicatorCard({required this.data});
  final _DonutData data;

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data.title,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 15),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size.square(132),
                        painter: _DonutPainter(data.segments),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            data.value,
                            style: const TextStyle(
                              color: AppColors.ink,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            data.caption,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: data.segments
                        .map(
                          (segment) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: _LegendDot(
                              color: segment.color,
                              label: segment.label,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 18),
          const Center(
            child: Text(
              'Dados calculados pela API',
              style: TextStyle(color: AppColors.muted, fontSize: 10.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardHeader extends StatelessWidget {
  const _CardHeader({required this.title, required this.subtitle, required this.icon});
  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 37,
          height: 37,
          decoration: BoxDecoration(
            color: AppColors.cyan.withOpacity(.11),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: AppColors.cyan, size: 19),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w800)),
              Text(subtitle,
                  style: const TextStyle(color: AppColors.muted, fontSize: 10.5)),
            ],
          ),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.muted, fontSize: 10.5),
          ),
        ),
      ],
    );
  }
}

class _SalesChartPainter extends CustomPainter {
  const _SalesChartPainter(this.evolution, this.goal);
  final DashboardSalesEvolution evolution;
  final DashboardGoal? goal;

  @override
  void paint(Canvas canvas, Size size) {
    final plot = Rect.fromLTRB(54, 12, size.width - 12, size.height - 30);
    final values = [
      ...evolution.actual.map((point) => point.value),
      ...evolution.forecast.map((point) => point.value),
      if (goal != null) goal!.targetValue,
    ];
    final highestValue = values.isEmpty
        ? 0.0
        : values.reduce((a, b) => math.max(a, b).toDouble());
    final maxValue = math.max(1.0, highestValue * 1.12).toDouble();
    final allDates = [
      ...evolution.actual.map((point) => point.date),
      ...evolution.forecast.map((point) => point.date),
    ].whereType<DateTime>().toList();
    final lastDay = allDates.isEmpty
        ? 31
        : allDates
            .map((date) => date.day)
            .reduce((a, b) => math.max(a, b).toInt());

    final gridPaint = Paint()
      ..color = AppColors.border.withOpacity(.75)
      ..strokeWidth = 1;
    for (var index = 0; index <= 4; index++) {
      final y = plot.top + plot.height * index / 4;
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), gridPaint);
      _drawText(
        canvas,
        _compactMoney(maxValue * (4 - index) / 4),
        Offset(0, y - 6),
      );
    }

    if (goal != null && goal!.targetValue > 0) {
      final y = plot.bottom - plot.height * goal!.targetValue / maxValue;
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), gridPaint);
    }

    _drawSeries(
      canvas,
      plot,
      evolution.actual,
      lastDay,
      maxValue,
      AppColors.cyan,
      dashed: false,
    );
    _drawSeries(
      canvas,
      plot,
      evolution.forecast,
      lastDay,
      maxValue,
      const Color(0xFFFFA928),
      dashed: true,
    );

    final step = math.max(1, (lastDay / 6).ceil());
    for (var day = 1; day <= lastDay; day += step) {
      final x = plot.left + plot.width * (day - 1) / math.max(1, lastDay - 1);
      _drawText(canvas, '$day', Offset(x - 3, plot.bottom + 9));
    }
  }

  void _drawSeries(
    Canvas canvas,
    Rect plot,
    List<DashboardSalesPoint> points,
    int lastDay,
    double maxValue,
    Color color, {
    required bool dashed,
  }) {
    if (points.isEmpty) return;
    final path = Path();
    for (var index = 0; index < points.length; index++) {
      final day = points[index].date?.day ?? index + 1;
      final x = plot.left + plot.width * (day - 1) / math.max(1, lastDay - 1);
      final y = plot.bottom - plot.height * points[index].value / maxValue;
      index == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
      if (!dashed) canvas.drawCircle(Offset(x, y), 3, Paint()..color = color);
    }
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    if (!dashed) {
      canvas.drawPath(path, paint);
      return;
    }
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, math.min(distance + 6, metric.length)),
          paint,
        );
        distance += 10;
      }
    }
  }

  String _compactMoney(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)} mi';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)} mil';
    return value.toStringAsFixed(0);
  }

  void _drawText(Canvas canvas, String value, Offset offset) {
    final painter = TextPainter(
      text: TextSpan(
        text: value,
        style: const TextStyle(color: AppColors.muted, fontSize: 8),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _SalesChartPainter oldDelegate) =>
      oldDelegate.evolution != evolution || oldDelegate.goal != goal;
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter(this.segments);
  final List<_DonutSegment> segments;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 8;
    var start = -math.pi / 2;
    for (final segment in segments) {
      final sweep = math.pi *
          2 *
          segment.value.clamp(0.0, 1.0).toDouble();
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start + .022,
        math.max(0.0, sweep - .044).toDouble(),
        false,
        Paint()
          ..color = segment.color
          ..strokeWidth = 14
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.segments != segments;
}

class _PanelLoading extends StatelessWidget {
  const _PanelLoading();
  @override
  Widget build(BuildContext context) {
    return const DashboardCard(
      child: SizedBox(
        height: 280,
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _PanelMessage extends StatelessWidget {
  const _PanelMessage({
    required this.icon,
    required this.title,
    required this.message,
    required this.buttonLabel,
    required this.onPressed,
  });
  final IconData icon;
  final String title;
  final String message;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      child: SizedBox(
        height: 260,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 42, color: AppColors.muted),
              const SizedBox(height: 12),
              Text(title,
                  style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 17,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted)),
              const SizedBox(height: 16),
              FilledButton(onPressed: onPressed, child: Text(buttonLabel)),
            ],
          ),
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.danger.withOpacity(.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.danger),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
          TextButton(onPressed: onRetry, child: const Text('Tentar novamente')),
        ],
      ),
    );
  }
}

class _MetricData {
  const _MetricData(this.label, this.value, this.comparison, this.icon, this.color);
  final String label;
  final String value;
  final String comparison;
  final IconData icon;
  final Color color;
}

class _DonutData {
  const _DonutData({
    required this.title,
    required this.value,
    required this.caption,
    required this.segments,
  });
  final String title;
  final String value;
  final String caption;
  final List<_DonutSegment> segments;
}

class _DonutSegment {
  const _DonutSegment(this.value, this.color, this.label);
  final double value;
  final Color color;
  final String label;
}

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';
import 'package:sistem_cormex/Src/Config/appColors.dart';
import 'package:sistem_cormex/Src/Dependencies/dependencies.dart';
import 'package:sistem_cormex/Src/Models/billingModels.dart';
import 'package:sistem_cormex/Src/Pages/Account/Components/accountCommon.dart';
import 'package:sistem_cormex/Src/Pages/Account/Plans/Controller/billingController.dart';
import 'package:sistem_cormex/Src/Pages/Orders/Components/orderCommon.dart';
import 'package:url_launcher/url_launcher.dart';

class PlansSection extends StatefulWidget {
  const PlansSection({super.key, this.checkoutId, this.checkoutReturnStatus});

  final String? checkoutId;
  final String? checkoutReturnStatus;

  @override
  State<PlansSection> createState() => _PlansSectionState();
}

class _PlansSectionState extends State<PlansSection> {
  late final BillingController controller;
  bool acceptedTerms = false;

  @override
  void initState() {
    super.initState();
    controller = getIt<BillingController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.initialize(checkoutId: widget.checkoutId);
      if (widget.checkoutReturnStatus == 'cancelled') {
        controller.checkoutMessage.value =
            'Pagamento cancelado. Nenhuma alteração foi feita no seu plano.';
      }
    });
  }

  @override
  void didUpdateWidget(covariant PlansSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.checkoutId == widget.checkoutId &&
        oldWidget.checkoutReturnStatus == widget.checkoutReturnStatus) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      controller.initialize(checkoutId: widget.checkoutId);
      if (widget.checkoutReturnStatus == 'cancelled') {
        controller.checkoutMessage.value =
            'Pagamento cancelado. Nenhuma alteração foi feita no seu plano.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final loading = controller.loading.value;
      final catalog = controller.catalog.value;
      final error = controller.error.value;
      final message = controller.checkoutMessage.value;
      controller.selectedPlanId.value;
      controller.selectedAddOnIds.value;
      controller.selectedProvider.value;
      controller.billingCycle.value;

      if (loading && catalog == null) {
        return const OrderSurface(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 72),
            child: Center(child: CircularProgressIndicator()),
          ),
        );
      }

      if (catalog == null) {
        return Column(
          children: [
            if (error != null) ...[
              OrderInlineError(message: error, onRetry: controller.loadCatalog),
              const SizedBox(height: 14),
            ],
            OrderSurface(
              child: AccountEmptyState(
                icon: Icons.credit_card_off_outlined,
                title: 'Não foi possível carregar os planos',
                message:
                    'A função v1-billing-catalog precisa estar publicada na API.',
              ),
            ),
          ],
        );
      }

      if (!catalog.permissions.canViewBilling) {
        return const OrderSurface(
          child: AccountEmptyState(
            icon: Icons.lock_outline_rounded,
            title: 'Área financeira restrita',
            message:
                'Solicite acesso ao responsável financeiro da sua empresa.',
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message != null) ...[
            _FeedbackBanner(
              message: message,
              loading: controller.verifyingCheckout.value,
              onClose: controller.clearCheckoutMessage,
              onRefresh: widget.checkoutId == null ||
                      controller.verifyingCheckout.value
                  ? null
                  : () {
                      controller.verifyCheckout(widget.checkoutId!);
                    },
            ),
            const SizedBox(height: 14),
          ],
          if (error != null) ...[
            OrderInlineError(message: error),
            const SizedBox(height: 14),
          ],
          if (catalog.subscription != null) ...[
            _CurrentSubscriptionCard(
              subscription: catalog.subscription!,
              permissions: catalog.permissions,
              busy: controller.actionLoading.value,
              onManage: _openCustomerPortal,
              onCancel: _confirmCancellation,
              onResume: _resumeSubscription,
            ),
            const SizedBox(height: 22),
          ],
          _SectionHeading(
            icon: Icons.workspace_premium_outlined,
            title: catalog.subscription == null
                ? 'Escolha o pacote ideal'
                : 'Planos disponíveis',
            description:
                'Os valores, benefícios e limites abaixo são carregados diretamente do banco de dados.',
            trailing: _BillingCycleSelector(
              value: controller.billingCycle.value,
              onChanged: controller.selectBillingCycle,
            ),
          ),
          const SizedBox(height: 14),
          _PlansGrid(
            plans: catalog.plans.where((plan) => plan.active).toList(),
            selectedPlanId: controller.selectedPlanId.value,
            currentPlanCode: catalog.subscription?.planCode,
            billingCycle: controller.billingCycle.value,
            onSelected: controller.selectPlan,
          ),
          if (catalog.addOns.any((item) => item.active)) ...[
            const SizedBox(height: 26),
            const _SectionHeading(
              icon: Icons.extension_outlined,
              title: 'Adicione módulos ao seu pacote',
              description:
                  'Ative somente o que sua operação precisa. Os módulos serão vinculados à mesma assinatura.',
            ),
            const SizedBox(height: 14),
            _AddOnsGrid(
              addOns: catalog.addOns.where((item) => item.active).toList(),
              plan: controller.selectedPlan,
              selectedIds: controller.selectedAddOnIds.value,
              billingCycle: controller.billingCycle.value,
              onToggle: controller.toggleAddOn,
            ),
          ],
          const SizedBox(height: 26),
          _SectionHeading(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Forma de contratação',
            description:
                'O pagamento é realizado no ambiente seguro da plataforma selecionada.',
          ),
          const SizedBox(height: 14),
          _ProvidersGrid(
            providers:
                catalog.providers.where((provider) => provider.enabled).toList(),
            selectedCode: controller.selectedProvider.value,
            onSelected: controller.selectProvider,
          ),
          const SizedBox(height: 20),
          _CheckoutSummary(
            plan: controller.selectedPlan,
            addOns: controller.selectedAddOns,
            billingCycle: controller.billingCycle.value,
            total: controller.selectionTotal,
            canSubscribe: catalog.permissions.canSubscribe,
            acceptedTerms: acceptedTerms,
            busy: controller.actionLoading.value,
            onTermsChanged: (value) {
              setState(() => acceptedTerms = value);
            },
            onCheckout: _startCheckout,
          ),
          if (catalog.permissions.canViewInvoices &&
              catalog.invoices.isNotEmpty) ...[
            const SizedBox(height: 26),
            _InvoicesSection(
              invoices: catalog.invoices,
              onOpen: _openInvoice,
            ),
          ],
        ],
      );
    });
  }

  Future<void> _startCheckout() async {
    final checkout = await controller.createCheckout();
    if (!mounted || checkout == null) return;
    final uri = Uri.tryParse(checkout.checkoutUrl);
    if (uri == null || uri.scheme != 'https') {
      _showMessage('A API retornou um endereço de pagamento inválido.');
      return;
    }
    final opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
      webOnlyWindowName: kIsWeb ? '_self' : null,
    );
    if (!opened && mounted) {
      _showMessage('Não foi possível abrir a página de pagamento.');
    }
  }

  Future<void> _openCustomerPortal() async {
    final portal = await controller.createPortal();
    if (!mounted || portal == null) return;
    final uri = Uri.tryParse(portal.portalUrl);
    if (uri == null || uri.scheme != 'https') {
      _showMessage('A API retornou um endereço de gerenciamento inválido.');
      return;
    }
    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
      webOnlyWindowName: kIsWeb ? '_self' : null,
    );
  }

  Future<void> _openInvoice(BillingInvoice invoice) async {
    final uri = Uri.tryParse(invoice.invoiceUrl ?? '');
    if (uri == null || uri.scheme != 'https') {
      _showMessage('Esta cobrança ainda não possui um link disponível.');
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _confirmCancellation() async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancelar renovação'),
        content: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'O acesso continuará disponível até o final do período já pago. Informe o motivo para nos ajudar a melhorar.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Motivo do cancelamento',
                  hintText: 'Conte brevemente o que motivou sua decisão',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Voltar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirmar cancelamento'),
          ),
        ],
      ),
    );
    final reason = reasonController.text;
    reasonController.dispose();
    if (confirmed == true) await controller.cancelSubscription(reason);
  }

  Future<void> _resumeSubscription() async {
    final success = await controller.resumeSubscription();
    if (success && mounted) _showMessage('Renovação reativada com sucesso.');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.icon,
    required this.title,
    required this.description,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String description;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final text = Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.cyan.withOpacity(.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.cyan),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: const TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        );
        if (trailing == null) return text;
        if (constraints.maxWidth < 700) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [text, const SizedBox(height: 12), trailing!],
          );
        }
        return Row(
          children: [Expanded(child: text), const SizedBox(width: 20), trailing!],
        );
      },
    );
  }
}

class _FeedbackBanner extends StatelessWidget {
  const _FeedbackBanner({
    required this.message,
    required this.loading,
    required this.onClose,
    this.onRefresh,
  });

  final String message;
  final bool loading;
  final VoidCallback onClose;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F8F1),
        border: Border.all(color: const Color(0xFF99DDC3)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          if (loading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2.2),
            )
          else
            const Icon(Icons.verified_outlined, color: Color(0xFF14734E)),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          if (onRefresh != null)
            TextButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded, size: 17),
              label: const Text('Atualizar status'),
            ),
          IconButton(onPressed: onClose, icon: const Icon(Icons.close_rounded)),
        ],
      ),
    );
  }
}

class _CurrentSubscriptionCard extends StatelessWidget {
  const _CurrentSubscriptionCard({
    required this.subscription,
    required this.permissions,
    required this.busy,
    required this.onManage,
    required this.onCancel,
    required this.onResume,
  });

  final BillingSubscription subscription;
  final BillingPermissions permissions;
  final bool busy;
  final VoidCallback onManage;
  final VoidCallback onCancel;
  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    final attention = subscription.needsPaymentAttention;
    final endDate = billingDate(
      subscription.accessUntil ?? subscription.currentPeriodEnd,
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.navy, AppColors.navySoft],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final details = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.verified_rounded, color: AppColors.lime),
                  const SizedBox(width: 8),
                  _StatusPill(
                    status: subscription.status,
                    label: subscription.statusLabel,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                subscription.planName.isEmpty
                    ? 'Sua assinatura'
                    : subscription.planName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                [
                  billingMoney(subscription.amount, subscription.currency),
                  subscription.billingCycle == 'annual' ? 'por ano' : 'por mês',
                  if (endDate != '—')
                    subscription.cancelAtPeriodEnd
                        ? 'acesso até $endDate'
                        : 'próxima cobrança em $endDate',
                ].join(' • '),
                style: TextStyle(
                  color: attention ? const Color(0xFFFFD27A) : Colors.white70,
                  fontSize: 12.5,
                ),
              ),
              if (subscription.cancelAtPeriodEnd) ...[
                const SizedBox(height: 10),
                const Text(
                  'A renovação automática está cancelada.',
                  style: TextStyle(
                    color: Color(0xFFFFD27A),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          );

          final actions = Wrap(
            spacing: 9,
            runSpacing: 9,
            children: [
              if (permissions.canManageBilling)
                OutlinedButton.icon(
                  onPressed: busy ? null : onManage,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white38),
                  ),
                  icon: const Icon(Icons.open_in_new_rounded, size: 17),
                  label: Text(attention ? 'Regularizar pagamento' : 'Gerenciar cobrança'),
                ),
              if (subscription.cancelAtPeriodEnd && permissions.canManageBilling)
                FilledButton.icon(
                  onPressed: busy ? null : onResume,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.lime,
                    foregroundColor: AppColors.navy,
                  ),
                  icon: const Icon(Icons.autorenew_rounded, size: 17),
                  label: const Text('Reativar renovação'),
                )
              else if (permissions.canCancel)
                TextButton(
                  onPressed: busy ? null : onCancel,
                  style: TextButton.styleFrom(foregroundColor: Colors.white70),
                  child: const Text('Cancelar renovação'),
                ),
            ],
          );

          if (constraints.maxWidth < 760) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [details, const SizedBox(height: 18), actions],
            );
          }
          return Row(
            children: [
              Expanded(child: details),
              const SizedBox(width: 18),
              actions,
            ],
          );
        },
      ),
    );
  }
}

class _BillingCycleSelector extends StatelessWidget {
  const _BillingCycleSelector({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(value: 'monthly', label: Text('Mensal')),
        ButtonSegment(
          value: 'annual',
          label: Text('Anual'),
          icon: Icon(Icons.savings_outlined, size: 17),
        ),
      ],
      selected: {value},
      showSelectedIcon: false,
      onSelectionChanged: (values) => onChanged(values.first),
    );
  }
}

class _PlansGrid extends StatelessWidget {
  const _PlansGrid({
    required this.plans,
    required this.selectedPlanId,
    required this.currentPlanCode,
    required this.billingCycle,
    required this.onSelected,
  });

  final List<BillingPlan> plans;
  final String? selectedPlanId;
  final String? currentPlanCode;
  final String billingCycle;
  final ValueChanged<BillingPlan> onSelected;

  @override
  Widget build(BuildContext context) {
    if (plans.isEmpty) {
      return const OrderSurface(
        child: AccountEmptyState(
          icon: Icons.inventory_2_outlined,
          title: 'Nenhum plano disponível',
          message: 'Cadastre planos ativos na classe BillingPlan.',
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1050
            ? 3
            : constraints.maxWidth >= 650
                ? 2
                : 1;
        final width = (constraints.maxWidth - ((columns - 1) * 14)) / columns;
        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: plans
              .map(
                (plan) => SizedBox(
                  width: width,
                  child: _PlanCard(
                    plan: plan,
                    selected: selectedPlanId == plan.id,
                    current: currentPlanCode == plan.code,
                    billingCycle: billingCycle,
                    onTap: () => onSelected(plan),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.selected,
    required this.current,
    required this.billingCycle,
    required this.onTap,
  });

  final BillingPlan plan;
  final bool selected;
  final bool current;
  final String billingCycle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final displayedPrice = billingCycle == 'annual'
        ? plan.annualMonthlyEquivalent
        : plan.monthlyPrice;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF2F9E7) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppColors.lime : AppColors.border,
            width: selected ? 2 : 1,
          ),
          boxShadow: plan.highlighted
              ? const [
                  BoxShadow(
                    color: Color(0x13071D2B),
                    blurRadius: 22,
                    offset: Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    plan.name,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                if (current)
                  const _SmallPill(label: 'Plano atual', color: AppColors.cyan)
                else if (plan.badge.isNotEmpty)
                  _SmallPill(label: plan.badge, color: AppColors.navy),
              ],
            ),
            const SizedBox(height: 7),
            Text(
              plan.description,
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 18),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.end,
              children: [
                Text(
                  billingMoney(displayedPrice, plan.currency),
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(bottom: 4, left: 4),
                  child: Text('/mês', style: TextStyle(color: AppColors.muted)),
                ),
              ],
            ),
            if (billingCycle == 'annual')
              Text(
                '${billingMoney(plan.annualPrice, plan.currency)} cobrados por ano',
                style: const TextStyle(color: AppColors.muted, fontSize: 10.5),
              ),
            const SizedBox(height: 18),
            ...plan.features.where((feature) => feature.included).take(7).map(
                  (feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF2BAA68),
                          size: 17,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            feature.label,
                            style: const TextStyle(fontSize: 12.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: selected
                  ? FilledButton.icon(
                      onPressed: onTap,
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text('Selecionado'),
                    )
                  : OutlinedButton(
                      onPressed: onTap,
                      child: Text(current ? 'Manter este plano' : 'Escolher plano'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddOnsGrid extends StatelessWidget {
  const _AddOnsGrid({
    required this.addOns,
    required this.plan,
    required this.selectedIds,
    required this.billingCycle,
    required this.onToggle,
  });

  final List<BillingAddOn> addOns;
  final BillingPlan? plan;
  final Set<String> selectedIds;
  final String billingCycle;
  final ValueChanged<BillingAddOn> onToggle;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 3
            : constraints.maxWidth >= 580
                ? 2
                : 1;
        final width = (constraints.maxWidth - ((columns - 1) * 12)) / columns;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: addOns.map((addOn) {
            final enabled = plan != null && addOn.supportsPlan(plan!.code);
            final selected = selectedIds.contains(addOn.id);
            return SizedBox(
              width: width,
              child: InkWell(
                onTap: enabled ? () => onToggle(addOn) : null,
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: selected ? const Color(0xFFEAF8F4) : Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: selected ? AppColors.cyan : AppColors.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.navy,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          billingAddOnIcon(addOn.icon),
                          color: AppColors.lime,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              addOn.name,
                              style: const TextStyle(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              enabled
                                  ? addOn.description
                                  : 'Indisponível para o plano selecionado',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 10.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '+ ${billingMoney(addOn.priceFor(billingCycle), addOn.currency)} ${billingCycle == 'annual' ? '/ano' : '/mês'}',
                              style: const TextStyle(
                                color: AppColors.navy,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: selected,
                        onChanged: enabled ? (_) => onToggle(addOn) : null,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _ProvidersGrid extends StatelessWidget {
  const _ProvidersGrid({
    required this.providers,
    required this.selectedCode,
    required this.onSelected,
  });

  final List<BillingProvider> providers;
  final String? selectedCode;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    if (providers.isEmpty) {
      return const OrderInlineError(
        message: 'Nenhuma plataforma de pagamento foi habilitada pela API.',
      );
    }
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: providers.map((provider) {
        final selected = provider.code == selectedCode;
        return ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 250, maxWidth: 390),
          child: InkWell(
            onTap: () => onSelected(provider.code),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFFF2F9E7) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected ? AppColors.lime : AppColors.border,
                  width: selected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Radio<String>(
                    value: provider.code,
                    groupValue: selectedCode,
                    onChanged: (value) {
                      if (value != null) onSelected(value);
                    },
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                provider.name,
                                style: const TextStyle(fontWeight: FontWeight.w900),
                              ),
                            ),
                            if (provider.recommended) ...[
                              const SizedBox(width: 7),
                              const _SmallPill(
                                label: 'Recomendado',
                                color: AppColors.cyan,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          provider.paymentMethods.join(' • '),
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _CheckoutSummary extends StatelessWidget {
  const _CheckoutSummary({
    required this.plan,
    required this.addOns,
    required this.billingCycle,
    required this.total,
    required this.canSubscribe,
    required this.acceptedTerms,
    required this.busy,
    required this.onTermsChanged,
    required this.onCheckout,
  });

  final BillingPlan? plan;
  final List<BillingAddOn> addOns;
  final String billingCycle;
  final double total;
  final bool canSubscribe;
  final bool acceptedTerms;
  final bool busy;
  final ValueChanged<bool> onTermsChanged;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    final currency = plan?.currency ?? 'BRL';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final summary = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Resumo da contratação',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              _SummaryLine(
                label: plan?.name ?? 'Nenhum plano selecionado',
                value: plan == null
                    ? '—'
                    : billingMoney(plan!.priceFor(billingCycle), currency),
              ),
              ...addOns.map(
                (addOn) => _SummaryLine(
                  label: addOn.name,
                  value: billingMoney(addOn.priceFor(billingCycle), currency),
                ),
              ),
              const Divider(height: 24),
              _SummaryLine(
                label: billingCycle == 'annual'
                    ? 'Total anual'
                    : 'Total mensal',
                value: billingMoney(total, currency),
                emphasized: true,
              ),
            ],
          );

          final action = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InkWell(
                onTap: () => onTermsChanged(!acceptedTerms),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: acceptedTerms,
                        onChanged: (value) => onTermsChanged(value ?? false),
                      ),
                      const Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(top: 10),
                          child: Text(
                            'Li e concordo com os termos da assinatura, cobrança recorrente e política de cancelamento.',
                            style: TextStyle(fontSize: 11.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: canSubscribe &&
                        acceptedTerms &&
                        plan != null &&
                        !busy
                    ? onCheckout
                    : null,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                icon: busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.lock_outline_rounded, size: 18),
                label: Text(
                  canSubscribe
                      ? 'Ir para pagamento seguro'
                      : 'Somente o responsável financeiro pode contratar',
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                'O sistema não recebe nem armazena os dados completos do cartão.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted, fontSize: 10),
              ),
            ],
          );

          if (constraints.maxWidth < 760) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [summary, const SizedBox(height: 20), action],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: summary),
              const SizedBox(width: 34),
              SizedBox(width: 390, child: action),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      color: emphasized ? AppColors.navy : AppColors.ink,
      fontSize: emphasized ? 16 : 12.5,
      fontWeight: emphasized ? FontWeight.w900 : FontWeight.w600,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
    );
  }
}

class _InvoicesSection extends StatelessWidget {
  const _InvoicesSection({required this.invoices, required this.onOpen});

  final List<BillingInvoice> invoices;
  final ValueChanged<BillingInvoice> onOpen;

  @override
  Widget build(BuildContext context) {
    return OrderSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const OrderSectionTitle(
            icon: Icons.receipt_long_outlined,
            title: 'Histórico de cobranças',
            description:
                'As cobranças são registradas pela API após confirmação da plataforma.',
          ),
          const SizedBox(height: 16),
          ...invoices.take(12).map(
                (invoice) => Container(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: AppColors.border),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              invoice.description,
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                            Text(
                              'Vencimento: ${billingDate(invoice.dueAt)}',
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 10.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Text(
                          billingMoney(invoice.amount, invoice.currency),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      _StatusPill(
                        status: invoice.status,
                        label: invoice.statusLabel,
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Abrir cobrança',
                        onPressed: invoice.invoiceUrl == null
                            ? null
                            : () => onOpen(invoice),
                        icon: const Icon(Icons.open_in_new_rounded, size: 18),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status, required this.label});

  final String status;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = switch (status) {
      'active' || 'paid' || 'trialing' =>
        (const Color(0xFFD9F6EA), const Color(0xFF14734E)),
      'past_due' || 'past_due_grace' || 'overdue' =>
        (const Color(0xFFFFE8D2), const Color(0xFF9A4E00)),
      'canceled' || 'unpaid' || 'void' =>
        (const Color(0xFFF9DDDD), AppColors.danger),
      _ => (const Color(0xFFFFF1BF), const Color(0xFF8A6700)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: colors.$2,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SmallPill extends StatelessWidget {
  const _SmallPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 9.5, fontWeight: FontWeight.w900),
      ),
    );
  }
}

String billingMoney(double value, String currency) {
  final fixed = value.toStringAsFixed(2);
  final parts = fixed.split('.');
  final digits = parts.first;
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) buffer.write('.');
    buffer.write(digits[index]);
  }
  final symbol = currency == 'BRL' ? 'R\$' : currency;
  return '$symbol ${buffer.toString()},${parts.last}';
}

String billingDate(DateTime? value) {
  if (value == null) return '—';
  final local = value.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/'
      '${local.month.toString().padLeft(2, '0')}/${local.year}';
}

IconData billingAddOnIcon(String value) {
  switch (value) {
    case 'route':
      return Icons.route_outlined;
    case 'tracking':
      return Icons.local_shipping_outlined;
    case 'users':
      return Icons.group_add_outlined;
    case 'reports':
      return Icons.query_stats_outlined;
    case 'whatsapp':
      return Icons.chat_outlined;
    case 'storage':
      return Icons.inventory_2_outlined;
    default:
      return Icons.extension_outlined;
  }
}

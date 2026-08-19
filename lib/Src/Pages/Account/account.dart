import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';
import 'package:sistem_cormex/Src/Config/appColors.dart';
import 'package:sistem_cormex/Src/Dependencies/dependencies.dart';
import 'package:sistem_cormex/Src/Models/accountModels.dart';
import 'package:sistem_cormex/Src/Pages/Account/Company/companySection.dart';
import 'package:sistem_cormex/Src/Pages/Account/Components/accountCommon.dart';
import 'package:sistem_cormex/Src/Pages/Account/Controller/accountController.dart';
import 'package:sistem_cormex/Src/Pages/Account/PaymentTerms/paymentTermsSection.dart';
import 'package:sistem_cormex/Src/Pages/Account/Plans/plansSection.dart';
import 'package:sistem_cormex/Src/Pages/Account/Profile/profileSection.dart';
import 'package:sistem_cormex/Src/Pages/Account/Users/usersSection.dart';
import 'package:sistem_cormex/Src/Pages/Account/accountSection.dart';
import 'package:sistem_cormex/Src/Pages/Orders/Components/orderCommon.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({
    super.key,
    required this.section,
    this.checkoutId,
    this.checkoutReturnStatus,
  });

  final AccountSection section;
  final String? checkoutId;
  final String? checkoutReturnStatus;

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  late final AccountController controller;

  @override
  void initState() {
    super.initState();
    controller = getIt<AccountController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.initialize(
        includeUsers: widget.section == AccountSection.users,
        includePaymentTerms: widget.section == AccountSection.paymentTerms,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return OrdersScaffold(
      child: Scrollbar(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 22, 18, 42),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1540),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const OrdersPageHeader(
                    title: 'Minha conta',
                    description: 'Gerencie seus dados, empresa, equipe e regras comerciais.',
                  ),
                  const SizedBox(height: 18),
                  AccountTabs(section: widget.section),
                  const SizedBox(height: 18),
                  Watch((context) {
                    final loading = controller.loading.value;
                    final workspace = controller.workspace.value;
                    final error = controller.error.value;
                    if (loading && workspace == null) {
                      return const OrderSurface(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 70),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      );
                    }
                    if (workspace == null) {
                      return OrderSurface(
                        child: Column(
                          children: [
                            const AccountEmptyState(
                              icon: Icons.cloud_off_outlined,
                              title: 'Não foi possível carregar sua conta',
                              message: 'Confira a conexão com a API e tente novamente.',
                            ),
                            if (error != null) ...[
                              Text(error, style: const TextStyle(color: AppColors.danger)),
                              const SizedBox(height: 12),
                            ],
                            FilledButton.icon(
                              onPressed: controller.loadWorkspace,
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Tentar novamente'),
                            ),
                          ],
                        ),
                      );
                    }
                    return Column(
                      children: [
                        if (workspace.setupRequired && widget.section != AccountSection.company) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAF8F4),
                              borderRadius: BorderRadius.circular(13),
                              border: Border.all(color: AppColors.cyan.withOpacity(.35)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.domain_add_outlined, color: AppColors.navy),
                                SizedBox(width: 10),
                                Expanded(child: Text('Cadastre sua empresa para liberar pedidos, clientes e produtos.')),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],
                        _section(workspace),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _section(AccountWorkspace workspace) {
    switch (widget.section) {
      case AccountSection.profile:
        return ProfileSection(controller: controller, workspace: workspace);
      case AccountSection.company:
        return CompanySection(controller: controller, workspace: workspace);
      case AccountSection.plans:
        return PlansSection(
          checkoutId: widget.checkoutId,
          checkoutReturnStatus: widget.checkoutReturnStatus,
        );
      case AccountSection.users:
        return UsersSection(controller: controller, workspace: workspace);
      case AccountSection.paymentTerms:
        return PaymentTermsSection(controller: controller, workspace: workspace);
    }
  }
}

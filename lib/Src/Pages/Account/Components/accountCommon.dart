import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sistem_cormex/Src/Config/appColors.dart';
import 'package:sistem_cormex/Src/Pages/Account/accountSection.dart';
import 'package:sistem_cormex/Src/Routes/appRouter.dart';

class AccountTabs extends StatelessWidget {
  const AccountTabs({super.key, required this.section});

  final AccountSection section;

  @override
  Widget build(BuildContext context) {
    const items = <(AccountSection, String, IconData, String)>[
      (AccountSection.profile, 'Meu perfil', Icons.person_outline_rounded, AppRoutes.accountProfile),
      (AccountSection.company, 'Minha empresa', Icons.apartment_rounded, AppRoutes.accountCompany),
      (AccountSection.plans, 'Plano e módulos', Icons.workspace_premium_outlined, AppRoutes.accountPlans),
      (AccountSection.users, 'Usuários', Icons.group_outlined, AppRoutes.accountUsers),
      (AccountSection.paymentTerms, 'Condições de pagamento', Icons.payments_outlined, AppRoutes.accountPaymentTerms),
    ];
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = items[index];
          final selected = item.$1 == section;
          return InkWell(
            onTap: () => context.go(item.$4),
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: selected ? AppColors.navy : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? AppColors.navy : AppColors.border,
                ),
              ),
              child: Row(
                children: [
                  Icon(item.$3, size: 18, color: selected ? AppColors.lime : AppColors.muted),
                  const SizedBox(width: 8),
                  Text(
                    item.$2,
                    style: TextStyle(
                      color: selected ? Colors.white : AppColors.ink,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class AccountEmptyState extends StatelessWidget {
  const AccountEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 44, color: AppColors.muted),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 5),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted)),
          ],
        ),
      ),
    );
  }
}

class AccountPermissionNotice extends StatelessWidget {
  const AccountPermissionNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5D6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF0D37A)),
      ),
      child: const Row(
        children: [
          Icon(Icons.lock_outline_rounded, color: Color(0xFF8B6500)),
          SizedBox(width: 10),
          Expanded(child: Text('Seu perfil pode visualizar esta área, mas apenas um administrador pode alterá-la.')),
        ],
      ),
    );
  }
}

String accountInitials(String value) {
  final parts = value.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
  if (parts.isEmpty) return 'C';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'.toUpperCase();
}

import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';
import 'package:sistem_cormex/Src/Config/appColors.dart';
import 'package:sistem_cormex/Src/Models/accountModels.dart';
import 'package:sistem_cormex/Src/Pages/Account/Components/accountCommon.dart';
import 'package:sistem_cormex/Src/Pages/Account/Controller/accountController.dart';
import 'package:sistem_cormex/Src/Pages/Orders/Components/orderCommon.dart';

class ProfileSection extends StatelessWidget {
  const ProfileSection({
    super.key,
    required this.controller,
    required this.workspace,
  });

  final AccountController controller;
  final AccountWorkspace workspace;

  @override
  Widget build(BuildContext context) {
    final user = workspace.user;
    return Column(
      children: [
        OrderSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const OrderSectionTitle(
                icon: Icons.badge_outlined,
                title: 'Meu perfil',
                description: 'Dados usados para identificar você em todo o sistema.',
              ),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 680;
                  final avatar = CircleAvatar(
                    radius: 42,
                    backgroundColor: AppColors.navy,
                    foregroundColor: AppColors.lime,
                    child: Text(
                      accountInitials(user.fullname),
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                    ),
                  );
                  final data = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.fullname, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 8),
                      _InfoLine(Icons.email_outlined, user.email),
                      if (user.phone.isNotEmpty) _InfoLine(Icons.phone_outlined, user.phone),
                      if (user.document.isNotEmpty) _InfoLine(Icons.assignment_ind_outlined, user.document),
                      const SizedBox(height: 10),
                      Chip(
                        avatar: const Icon(Icons.verified_user_outlined, size: 16),
                        label: Text(user.roleLabel),
                        side: const BorderSide(color: AppColors.border),
                        backgroundColor: AppColors.canvas,
                      ),
                    ],
                  );
                  final edit = FilledButton.icon(
                    onPressed: workspace.permissions.canEditProfile
                        ? () => _editProfile(context, user)
                        : null,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Alterar meus dados'),
                    style: FilledButton.styleFrom(backgroundColor: AppColors.navy),
                  );
                  if (compact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [avatar, const SizedBox(height: 18), data, const SizedBox(height: 18), edit],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [avatar, const SizedBox(width: 22), Expanded(child: data), edit],
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        OrderSurface(
          child: Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(color: AppColors.lime.withOpacity(.2), borderRadius: BorderRadius.circular(13)),
                child: const Icon(Icons.apartment_rounded, color: AppColors.navy),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Empresa vinculada', style: TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    Text(
                      workspace.company?.tradeName ?? 'Empresa ainda não cadastrada',
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              Icon(
                workspace.company == null ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
                color: workspace.company == null ? const Color(0xFFE0A400) : const Color(0xFF2F9B68),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _editProfile(BuildContext context, AccountUser user) async {
    final name = TextEditingController(text: user.fullname);
    final phone = TextEditingController(text: user.phone);
    final document = TextEditingController(text: user.document);
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Alterar meus dados'),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: name, decoration: const InputDecoration(labelText: 'Nome completo')),
              const SizedBox(height: 12),
              TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Telefone')),
              const SizedBox(height: 12),
              TextField(controller: document, decoration: const InputDecoration(labelText: 'Documento')),
              const SizedBox(height: 8),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('O e-mail de acesso não pode ser alterado aqui.', style: TextStyle(color: AppColors.muted, fontSize: 12)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancelar')),
          Watch((context) => FilledButton(
                onPressed: controller.saving.value
                    ? null
                    : () async {
                        final ok = await controller.updateProfile(
                          fullname: name.text,
                          phone: phone.text,
                          document: document.text,
                        );
                        if (ok && dialogContext.mounted) {
                          Navigator.pop(dialogContext, true);
                        } else if (dialogContext.mounted) {
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            SnackBar(content: Text(controller.error.value ?? 'Não foi possível atualizar o perfil.')),
                          );
                        }
                      },
                child: controller.saving.value
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Salvar'),
              )),
        ],
      ),
    );
    name.dispose();
    phone.dispose();
    document.dispose();
    if (saved == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perfil atualizado com sucesso.')));
    }
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(children: [Icon(icon, size: 17, color: AppColors.muted), const SizedBox(width: 7), Flexible(child: Text(text, style: const TextStyle(color: AppColors.muted)))]),
    );
  }
}

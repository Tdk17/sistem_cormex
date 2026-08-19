import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';
import 'package:sistem_cormex/Src/Config/appColors.dart';
import 'package:sistem_cormex/Src/Models/accountModels.dart';
import 'package:sistem_cormex/Src/Pages/Account/Components/accountCommon.dart';
import 'package:sistem_cormex/Src/Pages/Account/Controller/accountController.dart';
import 'package:sistem_cormex/Src/Pages/Orders/Components/orderCommon.dart';

class UsersSection extends StatelessWidget {
  const UsersSection({
    super.key,
    required this.controller,
    required this.workspace,
  });

  final AccountController controller;
  final AccountWorkspace workspace;

  @override
  Widget build(BuildContext context) {
    if (workspace.company == null) {
      return const OrderSurface(
        child: AccountEmptyState(
          icon: Icons.apartment_rounded,
          title: 'Cadastre a empresa primeiro',
          message: 'Os usuários precisam pertencer a uma empresa para acessar dados e pedidos.',
        ),
      );
    }
    return Watch((context) {
      final loading = controller.usersLoading.value;
      final users = controller.users.value;
      final error = controller.error.value;
      final atLimit = workspace.activeUserCount >= workspace.userLimit;
      return Column(
        children: [
          if (!workspace.permissions.canManageUsers) ...[
            const AccountPermissionNotice(),
            const SizedBox(height: 14),
          ],
          if (atLimit) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFFFFF4D7), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFF0D37A))),
              child: Row(children: [
                const Icon(Icons.info_outline_rounded, color: Color(0xFF8A6500)),
                const SizedBox(width: 10),
                Expanded(child: Text('Limite atingido: ${workspace.activeUserCount} de ${workspace.userLimit} usuários ativos.')),
              ]),
            ),
            const SizedBox(height: 14),
          ],
          OrderSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OrderSectionTitle(
                  icon: Icons.groups_2_outlined,
                  title: 'Equipe',
                  description: '${workspace.activeUserCount} de ${workspace.userLimit} usuários ativos nesta empresa.',
                  trailing: workspace.permissions.canManageUsers
                      ? FilledButton.icon(
                          onPressed: atLimit ? null : () => _userDialog(context),
                          icon: const Icon(Icons.person_add_alt_rounded, size: 18),
                          label: const Text('Convidar usuário'),
                          style: FilledButton.styleFrom(backgroundColor: AppColors.navy),
                        )
                      : null,
                ),
                const SizedBox(height: 18),
                if (loading && users.isEmpty)
                  const Padding(padding: EdgeInsets.all(45), child: Center(child: CircularProgressIndicator()))
                else if (users.isEmpty)
                  AccountEmptyState(
                    icon: Icons.group_off_outlined,
                    title: 'Nenhum usuário retornado',
                    message: error ?? 'Atualize a lista para buscar os usuários da empresa.',
                  )
                else ...[
                  const _GroupLabel('Responsável e administradores'),
                  ...users.where((item) => item.owner || item.role == 'admin').map((item) => _UserCard(
                        user: item,
                        canManage: workspace.permissions.canManageUsers,
                        onEdit: () => _userDialog(context, user: item),
                        onDeactivate: () => _deactivate(context, item),
                      )),
                  const SizedBox(height: 18),
                  const _GroupLabel('Demais usuários'),
                  ...users.where((item) => !item.owner && item.role != 'admin').map((item) => _UserCard(
                        user: item,
                        canManage: workspace.permissions.canManageUsers,
                        onEdit: () => _userDialog(context, user: item),
                        onDeactivate: () => _deactivate(context, item),
                      )),
                ],
                if (error != null && users.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  OrderInlineError(message: error, onRetry: controller.loadUsers),
                ],
              ],
            ),
          ),
        ],
      );
    });
  }

  Future<void> _userDialog(BuildContext context, {AccountUser? user}) async {
    final name = TextEditingController(text: user?.fullname ?? '');
    final email = TextEditingController(text: user?.email ?? '');
    final phone = TextEditingController(text: user?.phone ?? '');
    final roleOptions = workspace.availableRoles.isEmpty
        ? const [AccountOption(id: 'admin', label: 'Administrador'), AccountOption(id: 'seller', label: 'Vendedor')]
        : workspace.availableRoles;
    var role = roleOptions.any((item) => item.id == user?.role) ? user!.role : roleOptions.first.id;
    var active = user?.active ?? true;
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(user == null ? 'Convidar usuário' : 'Editar usuário'),
          content: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: name, decoration: const InputDecoration(labelText: 'Nome completo')),
                const SizedBox(height: 11),
                TextField(controller: email, enabled: user == null, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'E-mail de acesso')),
                const SizedBox(height: 11),
                TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Telefone')),
                const SizedBox(height: 11),
                DropdownButtonFormField<String>(
                  value: role,
                  decoration: const InputDecoration(labelText: 'Perfil de acesso'),
                  items: roleOptions.map((item) => DropdownMenuItem(value: item.id, child: Text(item.label))).toList(),
                  onChanged: user?.owner == true ? null : (value) => setDialogState(() => role = value!),
                ),
                if (user != null && !user.owner)
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Usuário ativo'),
                    value: active,
                    onChanged: (value) => setDialogState(() => active = value),
                  ),
                if (user == null)
                  const Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Text('A API deve criar o usuário e o vendedor com ponteiros para esta mesma empresa.', style: TextStyle(color: AppColors.muted, fontSize: 12)),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancelar')),
            Watch((context) => FilledButton(
                  onPressed: controller.userActionLoading.value
                      ? null
                      : () async {
                          final ok = user == null
                              ? await controller.inviteUser(fullname: name.text, email: email.text, phone: phone.text, role: role)
                              : await controller.updateManagedUser(user: user, fullname: name.text, phone: phone.text, role: role, active: active);
                          if (ok && dialogContext.mounted) {
                            Navigator.pop(dialogContext, true);
                          } else if (dialogContext.mounted) {
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              SnackBar(content: Text(controller.error.value ?? 'Não foi possível salvar o usuário.')),
                            );
                          }
                        },
                  child: controller.userActionLoading.value
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(user == null ? 'Convidar' : 'Salvar'),
                )),
          ],
        ),
      ),
    );
    name.dispose();
    email.dispose();
    phone.dispose();
    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(user == null ? 'Usuário criado e vinculado à empresa.' : 'Usuário atualizado.')));
    }
  }

  Future<void> _deactivate(BuildContext context, AccountUser user) async {
    if (user.owner) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Desativar usuário?'),
        content: Text('${user.fullname} perderá o acesso, mas seu histórico será mantido.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), style: FilledButton.styleFrom(backgroundColor: AppColors.danger), child: const Text('Desativar')),
        ],
      ),
    );
    if (confirmed != true) return;
    final ok = await controller.deactivateUser(user);
    if (ok && context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Usuário desativado.')));
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(label.toUpperCase(), style: const TextStyle(color: AppColors.muted, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: .7)),
      );
}

class _UserCard extends StatelessWidget {
  const _UserCard({required this.user, required this.canManage, required this.onEdit, required this.onDeactivate});
  final AccountUser user;
  final bool canManage;
  final VoidCallback onEdit;
  final VoidCallback onDeactivate;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: user.active ? AppColors.canvas : AppColors.field, borderRadius: BorderRadius.circular(13), border: Border.all(color: AppColors.border)),
      child: LayoutBuilder(builder: (context, constraints) {
        final info = Row(children: [
          CircleAvatar(radius: 23, backgroundColor: user.active ? AppColors.navy : AppColors.muted, foregroundColor: AppColors.lime, child: Text(accountInitials(user.fullname), style: const TextStyle(fontWeight: FontWeight.w900))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Wrap(spacing: 7, crossAxisAlignment: WrapCrossAlignment.center, children: [
              Text(user.fullname, style: const TextStyle(fontWeight: FontWeight.w900)),
              if (user.owner) const Chip(label: Text('Responsável'), visualDensity: VisualDensity.compact),
              if (!user.active) const Chip(label: Text('Inativo'), visualDensity: VisualDensity.compact),
            ]),
            Text('${user.email}${user.phone.isEmpty ? '' : ' • ${user.phone}'}', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
            Text(user.roleLabel, style: const TextStyle(color: AppColors.cyan, fontWeight: FontWeight.w700, fontSize: 12)),
          ])),
        ]);
        final actions = Wrap(spacing: 5, children: [
          OutlinedButton.icon(onPressed: canManage ? onEdit : null, icon: const Icon(Icons.edit_outlined, size: 16), label: const Text('Alterar')),
          if (!user.owner) IconButton(onPressed: canManage && user.active ? onDeactivate : null, tooltip: 'Desativar', color: AppColors.danger, icon: const Icon(Icons.person_off_outlined)),
        ]);
        if (constraints.maxWidth < 650) return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [info, const SizedBox(height: 12), actions]);
        return Row(children: [Expanded(child: info), actions]);
      }),
    );
  }
}

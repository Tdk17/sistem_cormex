import 'package:sistem_cormex/Src/Config/appColors.dart';
import 'package:sistem_cormex/Src/Pages/Auth/Components/authWidgets.dart';
import 'package:sistem_cormex/Src/Pages/Auth/Controller/authController.dart';
import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

class LogInPage extends StatefulWidget {
  const LogInPage({
    super.key,
    required this.authController,
    required this.onCreateAccount,
  });

  final AuthController authController;
  final VoidCallback onCreateAccount;

  @override
  State<LogInPage> createState() => _LogInPageState();
}

class _LogInPageState extends State<LogInPage> {
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool hiddenPassword = true;

  @override
  void initState() {
    super.initState();
    widget.authController.clearError();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    await widget.authController.logIn(
      email: emailController.text,
      password: passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AuthEyebrow(text: 'BEM-VINDO DE VOLTA'),
          const SizedBox(height: 12),
          const Text(
            'Acesse sua operação comercial',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 34,
              height: 1.08,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.1,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Pedidos, clientes e resultados em um só lugar.',
            style: TextStyle(color: AppColors.muted, fontSize: 16),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(
              labelText: 'E-mail profissional',
              prefixIcon: Icon(Icons.alternate_email_rounded),
            ),
            validator: validateEmail,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: passwordController,
            obscureText: hiddenPassword,
            autofillHints: const [AutofillHints.password],
            onFieldSubmitted: (_) {
              _submit();
            },
            decoration: InputDecoration(
              labelText: 'Senha',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                tooltip: hiddenPassword ? 'Mostrar senha' : 'Ocultar senha',
                onPressed: () {
                  setState(() => hiddenPassword = !hiddenPassword);
                },
                icon: Icon(
                  hiddenPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
            validator: validatePassword,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {},
              child: const Text('Esqueci minha senha'),
            ),
          ),
          const SizedBox(height: 8),
          Watch((context) {
            final error = widget.authController.errorMessage.value;
            final loading = widget.authController.isLoading.value;
            return Column(
              children: [
                if (error != null) ...[
                  AuthErrorMessage(message: error),
                  const SizedBox(height: 12),
                ],
                AuthPrimaryButton(
                  label: 'Entrar no Cormex Exchange',
                  icon: Icons.arrow_forward_rounded,
                  loading: loading,
                  onTap: () {
                    _submit();
                  },
                ),
              ],
            );
          }),
          const SizedBox(height: 28),
          Center(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text(
                  'Primeira vez por aqui?',
                  style: TextStyle(color: AppColors.muted),
                ),
                TextButton(
                  onPressed: widget.onCreateAccount,
                  child: const Text('Criar conta grátis'),
                ),
              ],
            ),
          ),
          const AuthLegalText(),
        ],
      ),
    );
  }
}

import 'package:sistem_cormex/Src/Config/appColors.dart';
import 'package:sistem_cormex/Src/Pages/Auth/Components/authWidgets.dart';
import 'package:sistem_cormex/Src/Pages/Auth/Controller/authController.dart';
import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({
    super.key,
    required this.authController,
    required this.onLogIn,
  });

  final AuthController authController;
  final VoidCallback onLogIn;

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final documentController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  bool hiddenPassword = true;
  bool acceptedTerms = false;

  @override
  void initState() {
    super.initState();
    widget.authController.clearError();
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    documentController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!formKey.currentState!.validate()) return;
    if (!acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aceite os termos para continuar.')),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    await widget.authController.signUp(
      fullname: nameController.text,
      email: emailController.text,
      password: passwordController.text,
      document: documentController.text,
      phone: phoneController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AuthEyebrow(text: 'COMECE SEM COMPLICAÇÃO'),
          const SizedBox(height: 12),
          const Text(
            'Organize suas vendas desde o primeiro pedido',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 32,
              height: 1.08,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Crie seu ambiente comercial em poucos minutos.',
            style: TextStyle(color: AppColors.muted, fontSize: 16),
          ),
          const SizedBox(height: 28),
          TextFormField(
            controller: nameController,
            textCapitalization: TextCapitalization.words,
            autofillHints: const [AutofillHints.name],
            decoration: const InputDecoration(
              labelText: 'Seu nome',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
            validator: (value) {
              if ((value ?? '').trim().length < 3) {
                return 'Informe seu nome completo';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
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
          const SizedBox(height: 14),
          TextFormField(
            controller: documentController,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'CPF, CNPJ ou documento',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
            validator: validateDocument,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            autofillHints: const [AutofillHints.telephoneNumber],
            decoration: const InputDecoration(
              labelText: 'Telefone com DDD',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
            validator: validatePhone,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: passwordController,
            obscureText: hiddenPassword,
            autofillHints: const [AutofillHints.newPassword],
            onFieldSubmitted: (_) {
              _submit();
            },
            decoration: InputDecoration(
              labelText: 'Crie uma senha',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
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
            validator: validateStrongPassword,
          ),
          const SizedBox(height: 10),
          Material(
            color: Colors.transparent,
            child: CheckboxListTile(
              value: acceptedTerms,
              onChanged: (value) {
                setState(() => acceptedTerms = value ?? false);
              },
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: AppColors.navy,
              title: const Text(
                'Concordo com os Termos de uso e a Política de privacidade.',
                style: TextStyle(fontSize: 13.5, color: AppColors.muted),
              ),
            ),
          ),
          const SizedBox(height: 6),
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
                  label: 'Criar meu espaço',
                  icon: Icons.rocket_launch_outlined,
                  loading: loading,
                  onTap: () {
                    _submit();
                  },
                ),
              ],
            );
          }),
          const SizedBox(height: 18),
          Center(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text(
                  'Já possui uma conta?',
                  style: TextStyle(color: AppColors.muted),
                ),
                TextButton(
                  onPressed: widget.onLogIn,
                  child: const Text('Fazer login'),
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

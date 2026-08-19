import 'package:sistem_cormex/Src/Config/appColors.dart';
import 'package:flutter/material.dart';

class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.light = false});

  final bool light;

  @override
  Widget build(BuildContext context) {
    final color = light ? Colors.white : AppColors.navy;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.lime,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.rotate(
                angle: -0.45,
                child: Container(width: 17, height: 7, color: AppColors.navy),
              ),
              Transform.translate(
                offset: const Offset(7, 5),
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: AppColors.cyan,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 11),
        Text(
          'comerx',
          style: TextStyle(
            color: color,
            fontSize: 27,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.1,
          ),
        ),
      ],
    );
  }
}

class AuthEyebrow extends StatelessWidget {
  const AuthEyebrow({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.cyan,
        fontWeight: FontWeight.w800,
        fontSize: 12,
        letterSpacing: 1.4,
      ),
    );
  }
}

class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.loading = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton.icon(
        onPressed: loading ? null : onTap,
        icon: loading
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: AppColors.navy,
                ),
              )
            : Icon(icon),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        ),
        style: FilledButton.styleFrom(
          foregroundColor: AppColors.navy,
          backgroundColor: AppColors.lime,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

class AuthErrorMessage extends StatelessWidget {
  const AuthErrorMessage({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.danger.withOpacity(.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.danger.withOpacity(.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.danger,
            size: 19,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.danger,
                fontSize: 13.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AuthLegalText extends StatelessWidget {
  const AuthLegalText({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Seus dados são protegidos e nunca serão vendidos.',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.muted, fontSize: 12),
      ),
    );
  }
}

class MobileBrandHeader extends StatelessWidget {
  const MobileBrandHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
      decoration: const BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BrandLogo(light: true),
          SizedBox(height: 22),
          Text(
            'Sua operação de vendas em movimento.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

String? validateEmail(String? value) {
  final email = value?.trim() ?? '';
  final pattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  if (email.isEmpty || !pattern.hasMatch(email)) {
    return 'Informe um e-mail válido';
  }
  return null;
}

String? validatePassword(String? value) {
  final password = value ?? '';
  if (password.isEmpty) return 'Informe sua senha';
  if (password.length > 128) return 'A senha deve ter no máximo 128 caracteres';
  return null;
}

String? validateStrongPassword(String? value) {
  final password = value ?? '';
  if (password.length < 8 || password.length > 128) {
    return 'Use entre 8 e 128 caracteres';
  }
  if (!RegExp(r'[A-Za-zÀ-ÖØ-öø-ÿ]').hasMatch(password) ||
      !RegExp(r'\d').hasMatch(password)) {
    return 'Inclua pelo menos uma letra e um número';
  }
  return null;
}

String? validatePhone(String? value) {
  final phone = (value ?? '').replaceAll(RegExp(r'\D'), '');
  if (!RegExp(r'^\d{10,15}$').hasMatch(phone)) {
    return 'Informe um telefone com DDD';
  }
  return null;
}

String? validateDocument(String? value) {
  final document = (value ?? '')
      .trim()
      .replaceAll(RegExp(r'[.\-/\s]'), '')
      .toUpperCase();
  if (!RegExp(r'^[A-Z0-9]{5,32}$').hasMatch(document)) {
    return 'Informe um documento válido';
  }
  return null;
}

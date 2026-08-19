import 'package:sistem_cormex/Src/Config/appColors.dart';
import 'package:sistem_cormex/Src/Dependencies/dependencies.dart';
import 'package:sistem_cormex/Src/Pages/Auth/Components/authWidgets.dart';
import 'package:sistem_cormex/Src/Pages/Auth/Components/commerceShowcase.dart';
import 'package:sistem_cormex/Src/Pages/Auth/Controller/authController.dart';
import 'package:sistem_cormex/Src/Pages/Auth/LogIn/logIn.dart';
import 'package:sistem_cormex/Src/Pages/Auth/SignUp/signUp.dart';
import 'package:sistem_cormex/Src/Routes/appRouter.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

enum AuthMode { logIn, signUp }

class AuthShell extends StatelessWidget {
  const AuthShell({super.key, required this.mode});

  final AuthMode mode;

  @override
  Widget build(BuildContext context) {
    final authController = getIt<AuthController>();
    final form = AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      child: mode == AuthMode.logIn
          ? LogInPage(
              key: const ValueKey('login'),
              authController: authController,
              onCreateAccount: () => context.go(AppRoutes.signUp),
            )
          : SignUpPage(
              key: const ValueKey('signUp'),
              authController: authController,
              onLogIn: () => context.go(AppRoutes.logIn),
            ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 940;
        if (isDesktop) {
          return Scaffold(
            body: Row(
              children: [
                Expanded(flex: 11, child: _AuthFormPanel(child: form)),
                const Expanded(flex: 9, child: CommerceShowcase()),
              ],
            ),
          );
        }

        return Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const MobileBrandHeader(),
                  _AuthFormPanel(child: form, compact: true),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AuthFormPanel extends StatelessWidget {
  const _AuthFormPanel({required this.child, this.compact = false});

  final Widget child;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final content = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 500),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!compact) ...[
            const BrandLogo(),
            const SizedBox(height: 68),
          ],
          child,
        ],
      ),
    );

    return Container(
      color: AppColors.canvas,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 24 : 48,
        vertical: compact ? 34 : 40,
      ),
      child: Center(
        child: compact ? content : SingleChildScrollView(child: content),
      ),
    );
  }
}

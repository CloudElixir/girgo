import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../services/auth_service.dart';
import '../theme/admin_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleEmailSignIn() async {
    if (_isLoading || !(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    try {
      await context.read<AuthProvider>().signInWithEmailAndPassword(
            email: _emailController.text,
            password: _passwordController.text,
          );
    } catch (e) {
      if (mounted) {
        final msg = e is Exception
            ? (e.toString().startsWith('Exception: ')
                ? e.toString().substring(11)
                : e.toString())
            : formatAuthErrorForUser(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: const Color(0xFF8B1D1D),
            duration: const Duration(seconds: 8),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      await context.read<AuthProvider>().signInWithGoogle();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(formatAuthErrorForUser(e)),
            backgroundColor: const Color(0xFF8B1D1D),
            duration: const Duration(seconds: 8),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 960;
          final card = _LoginCard(
            formKey: _formKey,
            emailController: _emailController,
            passwordController: _passwordController,
            isLoading: _isLoading,
            onEmailSignIn: _handleEmailSignIn,
            onGoogleSignIn: _handleGoogleSignIn,
          );

          if (wide) {
            return Row(
              children: [
                Expanded(
                  flex: 42,
                  child: _BrandPanel(height: constraints.maxHeight),
                ),
                Expanded(
                  flex: 58,
                  child: ColoredBox(
                    color: GirgoBrand.offWhite,
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 32),
                        child: card,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: [0.0, 0.45, 1.0],
                colors: [
                  GirgoBrand.black,
                  GirgoBrand.green,
                  GirgoBrand.offWhite,
                ],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
                  child: card,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            GirgoBrand.black,
            GirgoBrand.blackMuted,
            GirgoBrand.green,
          ],
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -40,
            top: -40,
            child: IgnorePointer(
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: GirgoBrand.greenMuted.withValues(alpha: 0.12),
                ),
              ),
            ),
          ),
          Positioned(
            left: -60,
            bottom: 80,
            child: IgnorePointer(
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: GirgoBrand.white.withValues(alpha: 0.08),
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 56),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: GirgoBrand.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: GirgoBrand.white.withValues(alpha: 0.15)),
                  ),
                  child: const Icon(
                    Icons.spa_rounded,
                    color: GirgoBrand.white,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Girgo',
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                    color: GirgoBrand.white,
                    letterSpacing: -1.2,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Admin',
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w300,
                    color: GirgoBrand.white.withValues(alpha: 0.92),
                    letterSpacing: 4,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'Manage products, orders, content, and customers in one calm, focused workspace.',
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.55,
                    color: GirgoBrand.white.withValues(alpha: 0.72),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 36),
                const Row(
                  children: [
                    _BrandDot(label: 'Secure'),
                    SizedBox(width: 20),
                    _BrandDot(label: 'Realtime'),
                    SizedBox(width: 20),
                    _BrandDot(label: 'Firebase'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandDot extends StatelessWidget {
  const _BrandDot({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: GirgoBrand.greenMuted,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: GirgoBrand.white.withValues(alpha: 0.85),
            fontWeight: FontWeight.w600,
            fontSize: 13,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

class _LoginCard extends StatelessWidget {
  const _LoginCard({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.isLoading,
    required this.onEmailSignIn,
    required this.onGoogleSignIn,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isLoading;
  final VoidCallback onEmailSignIn;
  final VoidCallback onGoogleSignIn;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Material(
        color: GirgoBrand.white,
        elevation: 0,
        shadowColor: GirgoBrand.black.withValues(alpha: 0.12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: GirgoBrand.borderLight, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: GirgoBrand.greenSoft,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.lock_person_rounded,
                        color: GirgoBrand.green,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sign in',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: scheme.onSurface,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Girgo control center',
                            style: TextStyle(
                              fontSize: 14,
                              color: scheme.onSurface.withValues(alpha: 0.55),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  autofillHints: const [AutofillHints.username],
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Username or email',
                    hintText: 'Your admin email address',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Enter your username or email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  autofillHints: const [AutofillHints.password],
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => onEmailSignIn(),
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    hintText: 'Your Firebase account password',
                    prefixIcon: Icon(Icons.key_rounded),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Enter your password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 22),
                FilledButton(
                  onPressed: isLoading ? null : onEmailSignIn,
                  child: isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: GirgoBrand.white,
                          ),
                        )
                      : const Text('Sign in'),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(child: Divider(color: scheme.outline.withValues(alpha: 0.5))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Text(
                        'or continue with',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface.withValues(alpha: 0.45),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: scheme.outline.withValues(alpha: 0.5))),
                  ],
                ),
                const SizedBox(height: 18),
                OutlinedButton.icon(
                  onPressed: isLoading ? null : onGoogleSignIn,
                  icon: Icon(Icons.login_rounded, color: scheme.onSurface.withValues(alpha: 0.85)),
                  label: const Text('Google'),
                ),
                const SizedBox(height: 20),
                Text(
                  'Use the email and password from Firebase Authentication, or Google for the same admin account.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.45,
                    color: scheme.onSurface.withValues(alpha: 0.48),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/locale_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';

/// Email/parol orqali kirish ekrani (glassmorphism).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscure = true;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final loc = context.read<LocaleProvider>();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = loc.t('auth.loginError'));
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await context.read<AuthProvider>().signIn(email, password);

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _error = result;
    });
    // Muvaffaqiyatli bo'lsa authStateChanges StreamBuilder ni almashtiradi.
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocaleProvider>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: SizedBox(
            width: 400,
            child: GlassCard(
              blur: 20,
              opacity: 0.25,
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo / icon
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.accentOrange.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.storefront_rounded,
                      color: AppTheme.accentOrange,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    loc.t('auth.title'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Email
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    enabled: !_isLoading,
                    decoration: InputDecoration(
                      labelText: loc.t('auth.email'),
                      prefixIcon: const Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Password
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscure,
                    enabled: !_isLoading,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _isLoading ? null : _login(),
                    decoration: InputDecoration(
                      labelText: loc.t('auth.password'),
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppTheme.textSecondary,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                  ),

                  // Error
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppTheme.accentRed,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: const TextStyle(
                              color: AppTheme.accentRed,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Login button
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              loc.t('auth.login'),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

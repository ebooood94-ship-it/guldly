import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/router/router.dart';
import '../../widgets/common/gold_button.dart';
import '../../widgets/common/gold_text_field.dart';
import '../../../core/providers/providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  void _showForgotPassword() {
    final emailCtrl =
        TextEditingController(text: _emailCtrl.text.trim());
    bool sending = false;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInner) => AlertDialog(
          title: const Text('Reset password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                  'Enter your email and we\'ll send a reset link.',
                  style: TextStyle(fontSize: 13)),
              const SizedBox(height: 16),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'your@email.com',
                  filled: true,
                  fillColor: AppConstants.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: sending
                  ? null
                  : () async {
                      setInner(() => sending = true);
                      try {
                        await ref
                            .read(authNotifierProvider)
                            .resetPassword(emailCtrl.text.trim());
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Reset link sent — check your email'),
                              backgroundColor: AppConstants.green,
                            ),
                          );
                        }
                      } catch (e) {
                        setInner(() => sending = false);
                      }
                    },
              child: Text(sending ? 'Sending…' : 'Send link',
                  style: const TextStyle(color: AppConstants.gold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _signIn() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authNotifierProvider).signIn(
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text,
          );
      // GoRouter redirect handles navigation
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),
              // Logo
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppConstants.gold,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.star_rounded,
                          color: Colors.white, size: 36),
                    ),
                    const SizedBox(height: 12),
                    const Text('guldly',
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: AppConstants.gold,
                            letterSpacing: 1)),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              const Text('Welcome back',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppConstants.black)),
              const SizedBox(height: 4),
              const Text('Sign in to your account',
                  style: TextStyle(fontSize: 14, color: AppConstants.subtitle)),
              const SizedBox(height: 32),
              GoldTextField(
                label: 'Email',
                hint: 'your@email.com',
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              GoldTextField(
                label: 'Password',
                hint: '••••••••',
                controller: _passwordCtrl,
                obscure: true,
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: _showForgotPassword,
                  child: const Text(
                    'Forgot password?',
                    style: TextStyle(
                      color: AppConstants.gold,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!,
                    style: const TextStyle(
                        color: AppConstants.error, fontSize: 13)),
              ],
              const SizedBox(height: 28),
              GoldButton(
                  label: 'Sign in', onPressed: _signIn, loading: _loading),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account? ",
                      style: TextStyle(color: AppConstants.subtitle)),
                  GestureDetector(
                    onTap: () => context.go(Routes.register),
                    child: const Text('Sign up',
                        style: TextStyle(
                            color: AppConstants.gold,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

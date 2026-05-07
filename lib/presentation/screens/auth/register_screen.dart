import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/router/router.dart';
import '../../../core/providers/providers.dart';
import '../../widgets/common/gold_button.dart';
import '../../widgets/common/gold_text_field.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _signUp() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authNotifierProvider).signUp(
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text,
            fullName: _nameCtrl.text.trim(),
          );
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
              const SizedBox(height: 40),
              GestureDetector(
                onTap: () => context.go(Routes.login),
                child: const Icon(Icons.arrow_back,
                    color: AppConstants.black, size: 22),
              ),
              const SizedBox(height: 32),
              const Text('Create account',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppConstants.black)),
              const SizedBox(height: 4),
              const Text('Start investing in gold today',
                  style: TextStyle(fontSize: 14, color: AppConstants.subtitle)),
              const SizedBox(height: 32),
              GoldTextField(
                  label: 'Full Name',
                  hint: 'Your full name',
                  controller: _nameCtrl),
              const SizedBox(height: 16),
              GoldTextField(
                  label: 'Email',
                  hint: 'your@email.com',
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 16),
              GoldTextField(
                  label: 'Password',
                  hint: '••••••••',
                  controller: _passwordCtrl,
                  obscure: true),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!,
                    style: const TextStyle(
                        color: AppConstants.error, fontSize: 13)),
              ],
              const SizedBox(height: 28),
              GoldButton(
                  label: 'Create account',
                  onPressed: _signUp,
                  loading: _loading),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Already have an account? ',
                      style: TextStyle(color: AppConstants.subtitle)),
                  GestureDetector(
                    onTap: () => context.go(Routes.login),
                    child: const Text('Sign in',
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

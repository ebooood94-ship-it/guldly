import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/providers.dart';
import '../../../core/router/router.dart';
import '../../../core/utils/error_utils.dart';
import '../../widgets/common/gold_button.dart';
import '../../widgets/common/gold_text_field.dart';
import '../../widgets/gold/gold_logo.dart';

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

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

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
      setState(() => _error = friendlyError(e));
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
              const Center(child: GoldLogo(size: LogoSize.medium)),
              const SizedBox(height: 32),
              Text(
                'Skapa konto',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 26,
                  fontStyle: FontStyle.italic,
                  color: AppConstants.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Börja spara i guld idag.',
                style: GoogleFonts.inter(
                    fontSize: 14, color: AppConstants.subtitle),
              ),
              const SizedBox(height: 32),
              GoldTextField(
                label: 'FULLSTÄNDIGT NAMN',
                hint: 'Ditt namn',
                controller: _nameCtrl,
              ),
              const SizedBox(height: 16),
              GoldTextField(
                label: 'E-POST',
                hint: 'din@email.se',
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              GoldTextField(
                label: 'LÖSENORD',
                hint: '••••••••',
                controller: _passwordCtrl,
                obscure: true,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!,
                    style: GoogleFonts.inter(
                        color: AppConstants.error, fontSize: 13)),
              ],
              const SizedBox(height: 28),
              GoldButton(
                label: 'SKAPA KONTO',
                onPressed: _signUp,
                loading: _loading,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Har du redan ett konto? ',
                      style: GoogleFonts.inter(
                          color: AppConstants.subtitle, fontSize: 13)),
                  GestureDetector(
                    onTap: () => context.go(Routes.login),
                    child: Text('Logga in',
                        style: GoogleFonts.inter(
                            color: AppConstants.gold,
                            fontWeight: FontWeight.w600,
                            fontSize: 13)),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

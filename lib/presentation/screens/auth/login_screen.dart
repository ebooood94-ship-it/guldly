import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/providers.dart';
import '../../../core/router/router.dart';
import '../../widgets/common/app_snackbar.dart';
import '../../widgets/common/gold_button.dart';
import '../../widgets/common/gold_text_field.dart';
import '../../widgets/gold/gold_logo.dart';

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

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _showForgotPassword() {
    final emailCtrl = TextEditingController(text: _emailCtrl.text.trim());
    bool sending = false;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInner) => AlertDialog(
          backgroundColor: AppConstants.card,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.cardRadius)),
          title: Text('Återställ lösenord',
              style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppConstants.black)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ange din e-post så skickar vi en återställningslänk.',
                  style: GoogleFonts.inter(
                      fontSize: 13, color: AppConstants.subtitle)),
              const SizedBox(height: 16),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                style: GoogleFonts.inter(
                    fontSize: 14, color: AppConstants.black),
                decoration: InputDecoration(
                  hintText: 'din@email.se',
                  hintStyle: GoogleFonts.inter(
                      color: AppConstants.subtitle, fontSize: 14),
                  filled: true,
                  fillColor: AppConstants.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: AppConstants.divider),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: AppConstants.divider),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                        color: AppConstants.gold, width: 1.5),
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
              child: Text('Avbryt',
                  style: GoogleFonts.inter(
                      color: AppConstants.subtitle,
                      fontWeight: FontWeight.w500)),
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
                          AppSnackbar.success(context,
                              'Återställningslänk skickad — kolla din e-post.');
                        }
                      } catch (e) {
                        setInner(() => sending = false);
                      }
                    },
              child: Text(sending ? 'Skickar…' : 'Skicka länk',
                  style: GoogleFonts.inter(
                      color: AppConstants.gold,
                      fontWeight: FontWeight.w600)),
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
    } catch (e) {
      setState(() => _error = 'Fel e-post eller lösenord.');
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
              const SizedBox(height: 64),
              const Center(child: GoldLogo(size: LogoSize.large)),
              const SizedBox(height: 56),
              Text(
                'Välkommen tillbaka',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 26,
                  fontStyle: FontStyle.italic,
                  color: AppConstants.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Logga in på ditt konto.',
                style: GoogleFonts.inter(
                    fontSize: 14, color: AppConstants.subtitle),
              ),
              const SizedBox(height: 32),
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
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: _showForgotPassword,
                  child: Text(
                    'Glömt lösenordet?',
                    style: GoogleFonts.inter(
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
                    style: GoogleFonts.inter(
                        color: AppConstants.error, fontSize: 13)),
              ],
              const SizedBox(height: 28),
              GoldButton(
                label: 'LOGGA IN',
                onPressed: _signIn,
                loading: _loading,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Har du inget konto? ',
                      style: GoogleFonts.inter(
                          color: AppConstants.subtitle, fontSize: 13)),
                  GestureDetector(
                    onTap: () => context.go(Routes.register),
                    child: Text('Registrera dig',
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

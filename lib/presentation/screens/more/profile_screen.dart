import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/providers.dart';
import '../../widgets/common/app_snackbar.dart';
import '../../widgets/common/back_header.dart';
import '../../widgets/common/gold_button.dart';
import '../../widgets/common/gold_text_field.dart';
import '../../widgets/common/section_label.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profile = ref.read(profileProvider).value;
      _nameCtrl.text = profile?.fullName ?? '';
      _phoneCtrl.text = profile?.phone ?? '';
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);
    final profile = profileAsync.value;
    final name = profile?.fullName ?? '';
    final email = ref.read(currentUserProvider)?.email ?? '';
    final initials = name.trim().isEmpty
        ? '?'
        : name.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase();

    return Scaffold(
      backgroundColor: AppConstants.background,
      body: SafeArea(
        child: Column(
          children: [
            const BackHeader(title: 'Profil', useSerifTitle: true),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.screenPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: AppConstants.goldLight,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: AppConstants.gold, width: 2),
                            ),
                            child: Center(
                              child: Text(
                                initials,
                                style: GoogleFonts.inter(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: AppConstants.gold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (name.isNotEmpty)
                            Text(
                              name,
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 20,
                                fontStyle: FontStyle.italic,
                                color: AppConstants.black,
                              ),
                            ),
                          if (email.isNotEmpty)
                            Text(
                              email,
                              style: GoogleFonts.inter(
                                  fontSize: 13, color: AppConstants.subtitle),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppConstants.sectionGap),
                    const SectionLabel('PERSONUPPGIFTER'),
                    Container(
                      decoration: BoxDecoration(
                        color: AppConstants.card,
                        borderRadius:
                            BorderRadius.circular(AppConstants.cardRadius),
                        border:
                            Border.all(color: AppConstants.divider, width: 1),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          GoldTextField(
                            label: 'Fullständigt namn',
                            hint: 'Ditt namn',
                            controller: _nameCtrl,
                          ),
                          const SizedBox(height: 16),
                          GoldTextField(
                            label: 'Telefon',
                            hint: '+46 70 000 00 00',
                            controller: _phoneCtrl,
                            keyboardType: TextInputType.phone,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    GoldButton(
                      label: 'SPARA',
                      loading: _saving,
                      onPressed: _saving ? null : _save,
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final user = ref.read(currentUserProvider);
    if (user != null) {
      try {
        await ref.read(supabaseProvider).from('profiles').update({
          'full_name': _nameCtrl.text.trim(),
          'phone': _phoneCtrl.text.trim(),
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', user.id);
        ref.invalidate(profileProvider);
        if (mounted) AppSnackbar.success(context, 'Profil uppdaterad.');
      } catch (e) {
        if (mounted) AppSnackbar.error(context, e);
      }
    }
    if (mounted) setState(() => _saving = false);
  }
}

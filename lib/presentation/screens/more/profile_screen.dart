import 'package:flutter/material.dart';
import 'package:guldly/core/constants/app_constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/common/back_header.dart';
import '../../../core/providers/providers.dart';
import '../../widgets/common/gold_card.dart';
import '../../widgets/common/gold_button.dart';
import '../../widgets/common/gold_text_field.dart';

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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            const BackHeader(title: 'Profile'),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GoldCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GoldTextField(
                              label: 'Full Name',
                              hint: 'Your name',
                              controller: _nameCtrl,
                            ),
                            const SizedBox(height: 16),
                            GoldTextField(
                              label: 'Phone',
                              hint: '+1 234 567 890',
                              controller: _phoneCtrl,
                              keyboardType: TextInputType.phone,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    GoldButton(
                        label: _saving ? 'Saving...' : 'Save changes',
                        onPressed: _saving
                            ? null
                            : () async {
                                setState(() => _saving = true);
                                final user = ref.read(currentUserProvider);
                                if (user != null) {
                                  await ref
                                      .read(supabaseProvider)
                                      .from('profiles')
                                      .update({
                                    'full_name': _nameCtrl.text,
                                    'phone': _phoneCtrl.text,
                                    'updated_at':
                                        DateTime.now().toIso8601String(),
                                  }).eq('id', user.id);
                                  ref.invalidate(profileProvider);
                                }
                                if (mounted) setState(() => _saving = false);
                              }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

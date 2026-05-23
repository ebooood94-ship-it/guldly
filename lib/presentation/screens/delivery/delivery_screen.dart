import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/providers.dart';
import '../../../core/router/router.dart';
import '../../widgets/common/app_snackbar.dart';
import '../../widgets/common/back_header.dart';
import '../../widgets/common/gold_button.dart';
import '../../widgets/common/info_banner.dart';
import '../../widgets/common/section_label.dart';

class DeliveryScreen extends ConsumerStatefulWidget {
  const DeliveryScreen({super.key});

  @override
  ConsumerState<DeliveryScreen> createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends ConsumerState<DeliveryScreen> {
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _zipCtrl = TextEditingController();
  double _grams = 0;
  bool _loading = false;
  String? _selectedPill;

  static const _pctLabels = ['25%', '50%', '75%', 'Allt'];
  static const _pctValues = [0.25, 0.50, 0.75, 1.0];

  @override
  void dispose() {
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _zipCtrl.dispose();
    super.dispose();
  }

  void _setGrams(double g, double available) {
    final clamped = (g < 0 ? 0.0 : g > available ? available : g);
    setState(() => _grams = clamped);
  }

  Future<void> _onContinue() async {
    final street = _addressCtrl.text.trim();
    final city = _cityCtrl.text.trim();
    final zip = _zipCtrl.text.trim();
    if (street.isEmpty || city.isEmpty || zip.isEmpty) {
      AppSnackbar.warning(context, 'Fyll i alla adressfält.');
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(goldTransactionServiceProvider).requestDelivery(
            goldGrams: _grams,
            deliveryAddress: '$street, $city $zip',
          );
      if (mounted) {
        context.go(Routes.receipt, extra: {
          'type': 'Delivery Requested',
          'amountSek': 0.0,
          'goldGrams': _grams,
          'deliveryAddress': '$street, $city $zip',
        });
      }
    } catch (e) {
      if (mounted) AppSnackbar.error(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletAsync = ref.watch(walletProvider);
    final available = walletAsync.value?.goldGrams ?? 0.0;
    final canContinue = _grams > 0 && _grams <= available && !_loading;

    return Scaffold(
      backgroundColor: AppConstants.background,
      body: SafeArea(
        child: Column(
          children: [
            const BackHeader(title: 'Leverans'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.screenPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildAvailableCard(available),
                    const SizedBox(height: AppConstants.sectionGap),
                    const SectionLabel('VÄLJ MÄNGD'),
                    _buildAmountCard(available),
                    const SizedBox(height: AppConstants.sectionGap),
                    const SectionLabel('LEVERANSADRESS'),
                    _buildAddressCard(),
                    const SizedBox(height: AppConstants.sectionGap),
                    const InfoBanner(
                      'Leverans sker inom 3–5 bankdagar. Guld skickas med spårbar försändelse.',
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppConstants.screenPadding, 0, AppConstants.screenPadding, 20),
              child: GoldButton(
                label: 'FORTSÄTT',
                loading: _loading,
                onPressed: canContinue ? _onContinue : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableCard(double available) {
    final fmt = available.toStringAsFixed(3).replaceAll('.', ',');
    return Container(
      decoration: BoxDecoration(
        color: AppConstants.card,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(color: AppConstants.divider, width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppConstants.deliveryIconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.local_shipping_outlined,
                color: AppConstants.navy, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tillgängligt guld',
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppConstants.black)),
              Text('$fmt g',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppConstants.subtitle)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmountCard(double available) {
    return Container(
      decoration: BoxDecoration(
        color: AppConstants.card,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(color: AppConstants.divider, width: 1),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            _grams > 0
                ? '${_grams.toStringAsFixed(3).replaceAll('.', ',')} g'
                : '0,000 g',
            style: GoogleFonts.playfairDisplay(
              fontSize: 48,
              fontStyle: FontStyle.italic,
              color: AppConstants.black,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 20),
          if (available > 0)
            Row(
              children: List.generate(4, (i) {
                final pct = _pctValues[i];
                final amt = double.parse(
                    (available * pct).toStringAsFixed(3));
                final label = _pctLabels[i];
                final selected = _selectedPill == label;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i < 3 ? 8 : 0),
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() => _selectedPill = label);
                        _setGrams(amt, available);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppConstants.deliveryIconBg
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected
                                ? AppConstants.navy
                                : AppConstants.divider,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            label,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: selected
                                  ? AppConstants.navy
                                  : AppConstants.black,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            )
          else
            Text(
              'Du har inget guld tillgängligt för leverans.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 13, color: AppConstants.subtitle),
            ),
        ],
      ),
    );
  }

  Widget _buildAddressCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppConstants.card,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(color: AppConstants.divider, width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _AddressLabel('GATUADRESS'),
          const SizedBox(height: 8),
          _AddressField(
            controller: _addressCtrl,
            hint: 'Storgatan 1',
            capitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _AddressLabel('STAD'),
                    const SizedBox(height: 8),
                    _AddressField(
                      controller: _cityCtrl,
                      hint: 'Stockholm',
                      capitalization: TextCapitalization.words,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _AddressLabel('POSTNUMMER'),
                    const SizedBox(height: 8),
                    _AddressField(
                      controller: _zipCtrl,
                      hint: '12345',
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddressLabel extends StatelessWidget {
  final String text;
  const _AddressLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppConstants.subtitle,
        letterSpacing: 1.0,
      ),
    );
  }
}

class _AddressField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextCapitalization capitalization;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const _AddressField({
    required this.controller,
    required this.hint,
    this.capitalization = TextCapitalization.none,
    this.keyboardType,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textCapitalization: capitalization,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: GoogleFonts.inter(fontSize: 14, color: AppConstants.black),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            GoogleFonts.inter(color: AppConstants.subtitle, fontSize: 14),
        filled: true,
        fillColor: AppConstants.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppConstants.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppConstants.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppConstants.gold, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}

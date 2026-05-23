import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/providers.dart';
import '../../../core/router/router.dart';
import '../../widgets/common/app_snackbar.dart';
import '../../widgets/common/back_header.dart';
import '../../widgets/common/gold_button.dart';
import '../../widgets/common/section_label.dart';

class SellScreen extends ConsumerStatefulWidget {
  const SellScreen({super.key});

  @override
  ConsumerState<SellScreen> createState() => _SellScreenState();
}

class _SellScreenState extends ConsumerState<SellScreen> {
  double _grams = 0;
  bool _loading = false;
  String? _selectedPill;
  final _gramsCtrl = TextEditingController();

  static const _pctLabels = ['25%', '50%', '75%', 'Allt'];
  static const _pctValues = [0.25, 0.50, 0.75, 1.0];

  @override
  void dispose() {
    _gramsCtrl.dispose();
    super.dispose();
  }

  void _setGrams(double g, double available) {
    final clamped = (g < 0 ? 0.0 : g > available ? available : g);
    final formatted = clamped > 0 ? clamped.toStringAsFixed(3) : '';
    if (_grams == clamped && _gramsCtrl.text == formatted) return;
    setState(() {
      _grams = clamped;
      if (_gramsCtrl.text != formatted) {
        _gramsCtrl.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      }
    });
  }

  Future<void> _onContinue(double pricePerGramSek) async {
    setState(() => _loading = true);
    try {
      await ref.read(goldTransactionServiceProvider).sellGold(
            goldGrams: _grams,
            goldPricePerGramSek: pricePerGramSek,
          );
      if (mounted) {
        context.go(Routes.receipt, extra: {
          'type': 'Sell Gold',
          'amountSek': _grams * pricePerGramSek,
          'goldGrams': _grams,
          'goldPricePerGramSek': pricePerGramSek,
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
    final goldAsync = ref.watch(goldPriceProvider);
    final available = walletAsync.value?.goldGrams ?? 0.0;
    final pricePerGram = goldAsync.value?.pricePerGramSek ?? 0.0;
    final sekValue = _grams * pricePerGram;

    return Scaffold(
      backgroundColor: AppConstants.background,
      body: SafeArea(
        child: Column(
          children: [
            const BackHeader(title: 'Sälj guld'),
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
                    _buildAmountCard(available, sekValue),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppConstants.screenPadding, 0, AppConstants.screenPadding, 20),
              child: goldAsync.when(
                data: (g) => GoldButton(
                  label: 'FORTSÄTT',
                  variant: GoldButtonVariant.destructive,
                  loading: _loading,
                  onPressed: (_grams > 0 && _grams <= available && !_loading)
                      ? () => _onContinue(g.pricePerGramSek)
                      : null,
                ),
                loading: () => const GoldButton(
                    label: 'FORTSÄTT',
                    variant: GoldButtonVariant.destructive,
                    onPressed: null),
                error: (_, __) => const GoldButton(
                    label: 'FORTSÄTT',
                    variant: GoldButtonVariant.destructive,
                    onPressed: null),
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
              color: AppConstants.sellIconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.layers_rounded,
                color: AppConstants.error, size: 20),
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

  Widget _buildAmountCard(double available, double sekValue) {
    return Container(
      decoration: BoxDecoration(
        color: AppConstants.card,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(color: AppConstants.divider, width: 1),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _showAmountSheet(available),
            child: Text(
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
          ),
          const SizedBox(height: 6),
          Text(
            '≈ ${NumberFormat('#,##0', 'sv_SE').format(sekValue).replaceAll(',', ' ')} kr',
            style: GoogleFonts.inter(
                fontSize: 13, color: AppConstants.subtitle),
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
                        setState(() {
                          _selectedPill = label;
                        });
                        _setGrams(amt, available);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppConstants.sellIconBg
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected
                                ? AppConstants.error
                                : AppConstants.divider,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            label,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: selected
                                  ? AppConstants.error
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
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Du har inget guld att sälja.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    fontSize: 13, color: AppConstants.subtitle),
              ),
            ),
        ],
      ),
    );
  }

  void _showAmountSheet(double available) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GramsInputSheet(
        initial: _grams,
        available: available,
        onConfirm: (v) {
          _setGrams(v, available);
          setState(() => _selectedPill = null);
        },
      ),
    );
  }
}

class _GramsInputSheet extends StatefulWidget {
  final double initial;
  final double available;
  final ValueChanged<double> onConfirm;

  const _GramsInputSheet({
    required this.initial,
    required this.available,
    required this.onConfirm,
  });

  @override
  State<_GramsInputSheet> createState() => _GramsInputSheetState();
}

class _GramsInputSheetState extends State<_GramsInputSheet> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
      text: widget.initial > 0 ? widget.initial.toStringAsFixed(3) : '',
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 20,
        right: 20,
        top: 20,
      ),
      decoration: const BoxDecoration(
        color: AppConstants.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Max: ${widget.available.toStringAsFixed(3).replaceAll('.', ',')} g',
            style: GoogleFonts.inter(
                fontSize: 12, color: AppConstants.subtitle),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _ctrl,
            autofocus: true,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                  RegExp(r'^\d*\.?\d{0,3}'))
            ],
            textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(
              fontSize: 36,
              fontStyle: FontStyle.italic,
              color: AppConstants.black,
            ),
            decoration: InputDecoration(
              hintText: '0,000',
              suffixText: 'g',
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              hintStyle: GoogleFonts.playfairDisplay(
                fontSize: 36,
                fontStyle: FontStyle.italic,
                color: AppConstants.divider,
              ),
            ),
          ),
          const SizedBox(height: 16),
          GoldButton(
            label: 'BEKRÄFTA',
            variant: GoldButtonVariant.destructive,
            onPressed: () {
              final v = double.tryParse(_ctrl.text) ?? 0;
              widget.onConfirm(v.clamp(0, widget.available));
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

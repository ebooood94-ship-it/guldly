import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/models.dart';
import '../../../core/providers/providers.dart';
import '../../../core/router/router.dart';
import '../../widgets/common/app_snackbar.dart';
import '../../widgets/common/back_header.dart';
import '../../widgets/common/gold_button.dart';
import '../../widgets/common/section_label.dart';
import '../../widgets/common/suggestion_pills.dart';

class _Recipient {
  final String name;
  final String email;
  const _Recipient(this.name, this.email);

  @override
  bool operator ==(Object other) =>
      other is _Recipient && other.email == email;

  @override
  int get hashCode => email.hashCode;
}

class GiftScreen extends ConsumerStatefulWidget {
  const GiftScreen({super.key});

  @override
  ConsumerState<GiftScreen> createState() => _GiftScreenState();
}

class _GiftScreenState extends ConsumerState<GiftScreen> {
  bool _isSEK = true;
  double _grams = 0;
  double _amountSek = 0;
  bool _loading = false;
  String? _selectedPill;
  bool _showSuggestions = false;

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();

  static const _sekLabels = ['100 kr', '250 kr', '500 kr', '1 000 kr'];
  static const _sekValues = [100.0, 250.0, 500.0, 1000.0];
  static const _gramLabels = ['1 g', '5 g', '10 g', '25 g'];
  static const _gramValues = [1.0, 5.0, 10.0, 25.0];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  List<_Recipient> _pastRecipients(List<Transaction> txs) {
    final seen = <String>{};
    final result = <_Recipient>[];
    for (final tx in txs) {
      if (tx.type == TransactionType.giftSent &&
          tx.recipientName != null &&
          tx.recipientEmail != null) {
        final email = tx.recipientEmail!;
        if (!seen.contains(email)) {
          seen.add(email);
          result.add(_Recipient(tx.recipientName!, email));
        }
      }
    }
    return result;
  }

  List<_Recipient> _filteredRecipients(List<_Recipient> all) {
    final q = _nameCtrl.text.toLowerCase();
    if (q.isEmpty) return all.take(3).toList();
    return all
        .where((r) =>
            r.name.toLowerCase().contains(q) ||
            r.email.toLowerCase().contains(q))
        .take(5)
        .toList();
  }

  void _selectRecipient(_Recipient r) {
    setState(() {
      _nameCtrl.text = r.name;
      _emailCtrl.text = r.email;
      _showSuggestions = false;
    });
  }

  void _setAmountFromPill(double value) {
    if (_isSEK) {
      final text = value.toStringAsFixed(0);
      setState(() {
        _amountSek = value;
        _amountCtrl.value = TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        );
      });
    } else {
      final text = value.toStringAsFixed(value % 1 == 0 ? 0 : 3);
      setState(() {
        _grams = value;
        _amountCtrl.value = TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        );
      });
    }
  }

  bool _isValidEmail(String email) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);

  Future<void> _onContinue(double goldPricePerGramSek) async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    if (name.isEmpty || email.isEmpty) {
      AppSnackbar.warning(context, 'Fyll i mottagarens uppgifter.');
      return;
    }
    if (!_isValidEmail(email)) {
      AppSnackbar.warning(context, 'Ange en giltig e-postadress.');
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(goldTransactionServiceProvider).sendGift(
            amountSek: _amountSek,
            goldGrams: _grams,
            recipientName: name,
            recipientEmail: email,
            goldPricePerGramSek: goldPricePerGramSek,
            isSEKMode: _isSEK,
          );
      if (mounted) {
        final effectiveAmountSek =
            _isSEK ? _amountSek : _grams * goldPricePerGramSek;
        final effectiveGrams =
            _isSEK ? _amountSek / goldPricePerGramSek : _grams;
        context.go(Routes.receipt, extra: {
          'type': 'Gift Sent',
          'amountSek': effectiveAmountSek,
          'goldGrams': effectiveGrams,
          'goldPricePerGramSek': goldPricePerGramSek,
          'recipientName': name,
          'recipientEmail': email,
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
    final txAsync = ref.watch(transactionsProvider);
    final pastRecipients = _pastRecipients(txAsync.value ?? []);
    final suggestions = _filteredRecipients(pastRecipients);
    final pricePerGram = goldAsync.value?.pricePerGramSek ?? 0.0;

    final hasAmount = _isSEK ? _amountSek > 0 : _grams > 0;

    return GestureDetector(
      onTap: () => setState(() => _showSuggestions = false),
      child: Scaffold(
        backgroundColor: AppConstants.background,
        body: SafeArea(
          child: Column(
            children: [
              const BackHeader(title: 'Ge guld', useSerifTitle: false),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.screenPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      _buildToggle(),
                      const SizedBox(height: AppConstants.sectionGap),
                      const SectionLabel('BELOPP'),
                      _buildAmountCard(pricePerGram, walletAsync.value?.goldGrams ?? 0),
                      const SizedBox(height: AppConstants.sectionGap),
                      const SectionLabel('MOTTAGARE'),
                      _buildRecipientCard(suggestions),
                      const SizedBox(height: AppConstants.sectionGap),
                      const SectionLabel('SAMMANFATTNING'),
                      _buildSummaryCard(pricePerGram),
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
                    variant: GoldButtonVariant.gift,
                    loading: _loading,
                    onPressed: (hasAmount && !_loading)
                        ? () => _onContinue(g.pricePerGramSek)
                        : null,
                  ),
                  loading: () => const GoldButton(
                      label: 'FORTSÄTT',
                      variant: GoldButtonVariant.gift,
                      onPressed: null),
                  error: (_, __) => const GoldButton(
                      label: 'FORTSÄTT',
                      variant: GoldButtonVariant.gift,
                      onPressed: null),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggle() {
    return Container(
      decoration: BoxDecoration(
        color: AppConstants.card,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(color: AppConstants.divider, width: 1),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _buildToggleTab('SEK', _isSEK),
          _buildToggleTab('Gram (g)', !_isSEK),
        ],
      ),
    );
  }

  Widget _buildToggleTab(String label, bool selected) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            _isSEK = label == 'SEK';
            _amountCtrl.clear();
            _amountSek = 0;
            _grams = 0;
            _selectedPill = null;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppConstants.violet : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? Colors.white : AppConstants.subtitle,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAmountCard(double pricePerGram, double availableGrams) {
    final labels = _isSEK ? _sekLabels : _gramLabels;
    final values = _isSEK ? _sekValues : _gramValues;

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
            onTap: () => _showAmountSheet(pricePerGram),
            child: Text(
              _isSEK
                  ? (_amountSek > 0
                      ? '${NumberFormat('#,##0', 'sv_SE').format(_amountSek.toInt()).replaceAll(',', ' ')} kr'
                      : '0 kr')
                  : (_grams > 0
                      ? '${_grams.toStringAsFixed(3).replaceAll('.', ',')} g'
                      : '0,000 g'),
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
            _isSEK
                ? (pricePerGram > 0
                    ? '≈ ${(_amountSek / pricePerGram).toStringAsFixed(4).replaceAll('.', ',')} g guld'
                    : '≈ 0 g guld')
                : '≈ ${NumberFormat('#,##0', 'sv_SE').format(_grams * pricePerGram).replaceAll(',', ' ')} kr',
            style: GoogleFonts.inter(
                fontSize: 13, color: AppConstants.subtitle),
          ),
          const SizedBox(height: 20),
          SuggestionPills(
            labels: labels,
            selected: _selectedPill,
            onTap: (label) {
              HapticFeedback.lightImpact();
              final idx = labels.indexOf(label);
              if (idx >= 0) {
                _setAmountFromPill(values[idx]);
                setState(() => _selectedPill = label);
              }
            },
            pillContext: PillContext.gift,
          ),
        ],
      ),
    );
  }

  Widget _buildRecipientCard(List<_Recipient> suggestions) {
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
          Text('NAMN',
              style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppConstants.subtitle,
                  letterSpacing: 1.0)),
          const SizedBox(height: 8),
          TextField(
            controller: _nameCtrl,
            textCapitalization: TextCapitalization.words,
            style: GoogleFonts.inter(fontSize: 14, color: AppConstants.black),
            decoration: InputDecoration(
              hintText: 'Söka eller ange namn',
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
                borderSide:
                    const BorderSide(color: AppConstants.gold, width: 1.5),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            onChanged: (_) => setState(() => _showSuggestions = true),
            onTap: () => setState(() => _showSuggestions = true),
          ),
          if (_showSuggestions && suggestions.isNotEmpty) ...[
            const SizedBox(height: 4),
            Container(
              decoration: BoxDecoration(
                color: AppConstants.card,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppConstants.divider),
              ),
              child: Column(
                children: suggestions.asMap().entries.map((e) {
                  final r = e.value;
                  final isLast = e.key == suggestions.length - 1;
                  return GestureDetector(
                    onTap: () => _selectRecipient(r),
                    child: Container(
                      decoration: isLast
                          ? null
                          : const BoxDecoration(
                              border: Border(
                                  bottom: BorderSide(
                                      color: AppConstants.divider))),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              color: AppConstants.giftIconBg,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                r.name.substring(0, 1).toUpperCase(),
                                style: GoogleFonts.inter(
                                  color: AppConstants.violet,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(r.name,
                                  style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: AppConstants.black)),
                              Text(r.email,
                                  style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: AppConstants.subtitle)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text('E-POST',
              style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppConstants.subtitle,
                  letterSpacing: 1.0)),
          const SizedBox(height: 8),
          TextField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            style: GoogleFonts.inter(fontSize: 14, color: AppConstants.black),
            decoration: InputDecoration(
              hintText: 'mottagare@email.se',
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
                borderSide:
                    const BorderSide(color: AppConstants.gold, width: 1.5),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(double pricePerGram) {
    final effectiveSek =
        _isSEK ? _amountSek : _grams * pricePerGram;
    final effectiveGrams =
        _isSEK ? (_amountSek / (pricePerGram > 0 ? pricePerGram : 1)) : _grams;

    return Container(
      decoration: BoxDecoration(
        color: AppConstants.card,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(color: AppConstants.divider, width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _SummaryRow(
            label: 'Belopp',
            value:
                '${NumberFormat('#,##0', 'sv_SE').format(effectiveSek).replaceAll(',', ' ')} kr',
          ),
          const Divider(height: 20, color: AppConstants.divider),
          _SummaryRow(
            label: 'Guld',
            value: '${effectiveGrams.toStringAsFixed(4).replaceAll('.', ',')} g',
          ),
        ],
      ),
    );
  }

  void _showAmountSheet(double pricePerGram) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AmountInputSheet(
        isSEK: _isSEK,
        initial: _isSEK ? _amountSek : _grams,
        onConfirm: (v) {
          setState(() {
            if (_isSEK) {
              _amountSek = v;
            } else {
              _grams = v;
            }
            _selectedPill = null;
          });
        },
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 13, color: AppConstants.subtitle)),
        Text(value,
            style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppConstants.black)),
      ],
    );
  }
}

class _AmountInputSheet extends StatefulWidget {
  final bool isSEK;
  final double initial;
  final ValueChanged<double> onConfirm;

  const _AmountInputSheet({
    required this.isSEK,
    required this.initial,
    required this.onConfirm,
  });

  @override
  State<_AmountInputSheet> createState() => _AmountInputSheetState();
}

class _AmountInputSheetState extends State<_AmountInputSheet> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
      text: widget.initial > 0
          ? (widget.isSEK
              ? widget.initial.toStringAsFixed(0)
              : widget.initial.toStringAsFixed(3))
          : '',
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
          TextField(
            controller: _ctrl,
            autofocus: true,
            keyboardType: widget.isSEK
                ? TextInputType.number
                : const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: widget.isSEK
                ? [FilteringTextInputFormatter.digitsOnly]
                : [
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
              hintText: widget.isSEK ? '0' : '0,000',
              suffixText: widget.isSEK ? 'kr' : 'g',
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
            variant: GoldButtonVariant.gift,
            onPressed: () {
              final v = double.tryParse(_ctrl.text) ?? 0;
              widget.onConfirm(v);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

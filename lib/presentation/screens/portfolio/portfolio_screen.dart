import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/models.dart';
import '../../../core/providers/providers.dart';
import '../../widgets/common/app_snackbar.dart';
import '../../widgets/common/error_view.dart';

class PortfolioScreen extends ConsumerWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletAsync = ref.watch(walletProvider);
    final subsAsync = ref.watch(subscriptionsProvider);
    final goldAsync = ref.watch(goldPriceProvider);
    final txAsync = ref.watch(transactionsProvider);

    final wallet = walletAsync.value;
    final gold = goldAsync.value;
    final txs = txAsync.value ?? [];
    final totalInvested = txs
        .where((t) =>
            t.type == TransactionType.buy ||
            t.type == TransactionType.recurringBuy)
        .fold<double>(0, (s, t) => s + t.amountSek);
    final goldValue = (wallet?.goldGrams ?? 0) * (gold?.pricePerGramSek ?? 0);
    final grams = wallet?.goldGrams ?? 0;
    final pctChange = totalInvested > 0
        ? (goldValue - totalInvested) / totalInvested * 100
        : 0.0;
    final isUp = pctChange >= 0;

    String fmtSek(double v) =>
        '${NumberFormat('#,##0', 'sv_SE').format(v).replaceAll(',', ' ')} kr';

    return Scaffold(
      backgroundColor: AppConstants.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'Portfölj',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.black,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // ── Hero ────────────────────────────────────────────────────
              Center(
                child: Column(
                  children: [
                    Text(
                      'MIN PORTFÖLJ',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppConstants.subtitle,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      fmtSek(goldValue),
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 36,
                        fontStyle: FontStyle.italic,
                        color: AppConstants.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${grams.toStringAsFixed(3).replaceAll('.', ',')} g guld',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppConstants.gold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isUp
                              ? Icons.trending_up_rounded
                              : Icons.trending_down_rounded,
                          color: isUp ? AppConstants.green : AppConstants.error,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          totalInvested > 0
                              ? '${isUp ? '+' : ''}${pctChange.toStringAsFixed(2).replaceAll('.', ',')}% mot inköpspris'
                              : '—',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: totalInvested > 0
                                ? (isUp ? AppConstants.green : AppConstants.error)
                                : AppConstants.subtitle,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.sectionGap),
              // ── Performance card ─────────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: AppConstants.card,
                  borderRadius: BorderRadius.circular(AppConstants.cardRadius),
                  border: Border.all(color: AppConstants.divider, width: 1),
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('INSATT',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppConstants.subtitle,
                                letterSpacing: 1.0,
                              )),
                          const SizedBox(height: 4),
                          Text(fmtSek(totalInvested),
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppConstants.black,
                              )),
                        ],
                      ),
                    ),
                    Consumer(builder: (_, ref, __) {
                      final h = ref.watch(goldPriceHistoryProvider);
                      return SizedBox(
                        width: 80,
                        height: 40,
                        child: h.length >= 2
                            ? CustomPaint(painter: _MiniChartPainter(h))
                            : const SizedBox.shrink(),
                      );
                    }),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('NUVARANDE VÄRDE',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppConstants.subtitle,
                                letterSpacing: 1.0,
                              )),
                          const SizedBox(height: 4),
                          Text(fmtSek(goldValue),
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppConstants.black,
                              )),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.sectionGap),
              // ── Active plan ───────────────────────────────────────────────
              Text(
                'AKTIV PLAN',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppConstants.subtitle,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 12),
              subsAsync.when(
                data: (subs) => subs.isEmpty
                    ? Container(
                        decoration: BoxDecoration(
                          color: AppConstants.card,
                          borderRadius:
                              BorderRadius.circular(AppConstants.cardRadius),
                          border:
                              Border.all(color: AppConstants.divider, width: 1),
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Center(
                          child: Text(
                            'Inga aktiva planer',
                            style: GoogleFonts.inter(
                                color: AppConstants.subtitle, fontSize: 14),
                          ),
                        ),
                      )
                    : Column(
                        children: subs
                            .map((s) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _SubscriptionCard(
                                    sub: s,
                                    onCancel: () async {
                                      await ref
                                          .read(goldTransactionServiceProvider)
                                          .cancelSubscription(s.id);
                                    },
                                    onEdit: (amount, freq, days, nextDate) async {
                                      await ref
                                          .read(goldTransactionServiceProvider)
                                          .updateSubscription(
                                            subscriptionId: s.id,
                                            amountSek: amount,
                                            frequency: freq,
                                            selectedDays: days,
                                            nextPaymentDate: nextDate,
                                          );
                                    },
                                  ),
                                ))
                            .toList()),
                loading: () => const Center(
                    child: CircularProgressIndicator(color: AppConstants.gold)),
                error: (e, _) => ErrorView(error: e),
              ),
              // ── Assets grid ───────────────────────────────────────────────
              const SizedBox(height: AppConstants.sectionGap),
              Text(
                'TILLGÅNGAR',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppConstants.subtitle,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.6,
                children: [
                  _AssetTile(
                    icon: Icons.layers_rounded,
                    iconColor: AppConstants.gold,
                    iconBg: AppConstants.goldLight,
                    label: 'GULD',
                    value: '${grams.toStringAsFixed(3).replaceAll('.', ',')} g',
                  ),
                  _AssetTile(
                    icon: Icons.account_balance_wallet_outlined,
                    iconColor: AppConstants.navy,
                    iconBg: AppConstants.deliveryIconBg,
                    label: 'PLÅNBOK',
                    value: fmtSek(wallet?.balanceSek ?? 0),
                  ),
                  _AssetTile(
                    icon: Icons.trending_up_rounded,
                    iconColor: AppConstants.green,
                    iconBg: const Color(0xFFCDE8DA),
                    label: 'AVKASTNING',
                    value: fmtSek(goldValue - totalInvested),
                  ),
                  _AssetTile(
                    icon: Icons.calendar_today_outlined,
                    iconColor: AppConstants.violet,
                    iconBg: AppConstants.giftIconBg,
                    label: 'INSATT',
                    value: fmtSek(totalInvested),
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

typedef _OnEdit = Future<void> Function(
    double amount, String freq, List<String> days, DateTime nextDate);

class _SubscriptionCard extends StatelessWidget {
  final Subscription sub;
  final Future<void> Function() onCancel;
  final _OnEdit onEdit;
  const _SubscriptionCard(
      {required this.sub, required this.onCancel, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0', 'sv_SE')
        .format(sub.amountSek)
        .replaceAll(',', ' ');
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
              color: AppConstants.goldLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.repeat_rounded,
                color: AppConstants.gold, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${sub.frequency.name[0].toUpperCase()}${sub.frequency.name.substring(1)} guldplan',
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppConstants.black),
                ),
                const SizedBox(height: 2),
                Text(
                  '$fmt kr / ${sub.frequency.name}',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    color: AppConstants.gold,
                  ),
                ),
                if (sub.nextPaymentDate != null)
                  Text(
                    'Nästa betalning: ${sub.nextPaymentDate!.day}/${sub.nextPaymentDate!.month}/${sub.nextPaymentDate!.year}',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppConstants.subtitle),
                  ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _showEditSheet(context),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppConstants.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.edit_outlined,
                  color: AppConstants.subtitle, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditSheet(sub: sub, onSave: onEdit, onCancel: onCancel),
    );
  }
}

class _EditSheet extends StatefulWidget {
  final Subscription sub;
  final _OnEdit onSave;
  final Future<void> Function() onCancel;
  const _EditSheet({required this.sub, required this.onSave, required this.onCancel});

  @override
  State<_EditSheet> createState() => _EditSheetState();
}

class _EditSheetState extends State<_EditSheet> {
  late final TextEditingController _amountCtrl;
  late String _frequency;
  late List<String> _selectedDays;
  late DateTime _nextDate;
  bool _saving = false;
  bool _cancelling = false;

  @override
  void initState() {
    super.initState();
    _amountCtrl =
        TextEditingController(text: widget.sub.amountSek.toStringAsFixed(0));
    _frequency = widget.sub.frequency.name;
    _selectedDays = List<String>.from(widget.sub.daysOfWeek ?? ['monday']);
    _nextDate = widget.sub.nextPaymentDate ??
        DateTime.now().add(const Duration(days: 1));
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) {
      AppSnackbar.warning(context, 'Ange ett giltigt belopp.');
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.onSave(amount, _frequency, _selectedDays, _nextDate);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) AppSnackbar.error(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _cancelSub() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Avbryta prenumeration?',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text(
          'Detta stoppar framtida automatiska guldköp.',
          style: GoogleFonts.inter(fontSize: 13),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Behåll')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Avbryt',
                  style: TextStyle(color: AppConstants.error))),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _cancelling = true);
    try {
      await widget.onCancel();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) AppSnackbar.error(context, e);
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      margin: EdgeInsets.only(bottom: bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppConstants.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Redigera plan',
              style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppConstants.black)),
          const SizedBox(height: 20),
          Text('Belopp (SEK)',
              style: GoogleFonts.inter(
                  fontSize: 11, color: AppConstants.subtitle, letterSpacing: 1.0)),
          const SizedBox(height: 8),
          TextField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              prefixText: 'kr ',
              filled: true,
              fillColor: AppConstants.background,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppConstants.divider)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppConstants.divider)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppConstants.gold)),
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.gold,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppConstants.buttonRadius)),
              ),
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text('Spara ändringar',
                      style: GoogleFonts.inter(
                          fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: _cancelling ? null : _cancelSub,
              child: Text('Avbryt prenumeration',
                  style: GoogleFonts.inter(
                      fontSize: 14, color: AppConstants.error)),
            ),
          ),
        ],
      ),
    );
  }
}

class _AssetTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String value;
  const _AssetTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppConstants.card,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(color: AppConstants.divider, width: 1),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: AppConstants.subtitle,
                letterSpacing: 1.0,
              )),
          const SizedBox(height: 2),
          Text(value,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppConstants.black,
              )),
        ],
      ),
    );
  }
}

class _MiniChartPainter extends CustomPainter {
  final List<double> prices;
  const _MiniChartPainter(this.prices);

  @override
  void paint(Canvas canvas, Size size) {
    if (prices.length < 2) return;
    final min = prices.reduce((a, b) => a < b ? a : b);
    final max = prices.reduce((a, b) => a > b ? a : b);
    final range = max - min == 0 ? 1.0 : max - min;
    final isUp = prices.last >= prices.first;
    final paint = Paint()
      ..color = isUp ? AppConstants.green : AppConstants.error
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    final path = Path();
    for (var i = 0; i < prices.length; i++) {
      final x = i / (prices.length - 1) * size.width;
      final y = (1 - (prices[i] - min) / range) * size.height;
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_MiniChartPainter old) => old.prices != prices;
}

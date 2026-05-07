import 'package:flutter/material.dart';
import 'package:guldly/core/constants/app_constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';
import '../../widgets/common/back_header.dart';
import '../../widgets/common/gold_card.dart';
import '../../widgets/common/gold_button.dart';
import '../../widgets/common/gold_text_field.dart';

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
  static const _suggestions = [10.0, 25.0, 50.0, 100.0];

  @override
  Widget build(BuildContext context) {
    final walletAsync = ref.watch(walletProvider);

    return Scaffold(
      backgroundColor: AppConstants.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            const BackHeader(title: 'Delivery'),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Amount to deliver',
                        style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    GoldCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(children: [
                          Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text('Gold',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14)),
                                      walletAsync.when(
                                        data: (w) => Text(
                                            'Avl Au = ${w?.goldGrams.toStringAsFixed(1) ?? 0}g',
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: AppConstants.subtitle)),
                                        loading: () => const Text('Loading...'),
                                        error: (_, __) =>
                                            const Text('Avl Au = 0g'),
                                      ),
                                    ]),
                                Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                        color: const Color(0xFF3498DB)
                                            .withValues(alpha: 0.12),
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                    child: const Icon(
                                        Icons.local_shipping_outlined,
                                        color: Color(0xFF3498DB),
                                        size: 20)),
                              ]),
                          const SizedBox(height: 16),
                          Center(
                              child: Text(
                            '${_grams == 0 ? '0' : _grams.toStringAsFixed(1)}g',
                            style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w300,
                                color: AppConstants.subtitle),
                          )),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _suggestions.map((amt) {
                              final sel = _grams == amt;
                              return GestureDetector(
                                onTap: () => setState(() => _grams = amt),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: sel
                                        ? AppConstants.gold
                                            .withValues(alpha: 0.12)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color: sel
                                            ? AppConstants.gold
                                            : const Color(0xFFDDDDDD)),
                                  ),
                                  child: Text('${amt.toStringAsFixed(0)}g',
                                      style: TextStyle(
                                          color: sel
                                              ? AppConstants.gold
                                              : AppConstants.black,
                                          fontWeight: sel
                                              ? FontWeight.w600
                                              : FontWeight.w400)),
                                ),
                              );
                            }).toList(),
                          ),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text('Delivery Address',
                        style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    GoldCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(children: [
                          const SizedBox(height: 6),
                          GoldTextField(
                              label: 'Street Address',
                              hint: 'Enter street address',
                              controller: _addressCtrl),
                          const SizedBox(height: 14),
                          Row(children: [
                            Expanded(
                                child: Column(children: [
                              const SizedBox(height: 6),
                              GoldTextField(
                                  label: 'City',
                                  hint: 'City',
                                  controller: _cityCtrl),
                            ])),
                            const SizedBox(width: 12),
                            Expanded(
                                child: Column(children: [
                              const SizedBox(height: 6),
                              GoldTextField(
                                  label: 'Postal Code',
                                  hint: '12345',
                                  controller: _zipCtrl,
                                  keyboardType: TextInputType.number),
                            ])),
                          ]),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: GoldButton(
                  label: 'Continue', onPressed: _grams > 0 ? () {} : null),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget test for the one-time buy amount-entry flow: tapping a suggestion
// pill sets the amount, and the continue button is disabled at 0 kr and
// enabled once an amount is chosen.
//
// The Supabase-backed providers are replaced with ProviderScope overrides so
// nothing touches the real backend.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guldly/core/models/models.dart';
import 'package:guldly/core/providers/providers.dart';
import 'package:guldly/presentation/screens/buy_gold/buy_onetime_screen.dart';
import 'package:guldly/presentation/widgets/common/gold_button.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

List<Override> _overrides() => [
      // A live gold price is required for the continue button to enable
      // (canContinue checks pricePerGram > 0).
      goldPriceProvider.overrideWith((ref) async => GoldPrice.mock),
      walletProvider.overrideWith((ref) async => null),
      supabaseProvider.overrideWithValue(SupabaseClient(
        'http://localhost:54321',
        'test',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      )),
    ];

Widget _wrap(Widget child) => ProviderScope(
      overrides: _overrides(),
      child: MaterialApp(home: child),
    );

GoldButton _continueButton(WidgetTester tester) =>
    tester.widget<GoldButton>(find.widgetWithText(GoldButton, 'FORTSÄTT'));

void main() {
  testWidgets('continue is disabled at 0 kr and enabled after picking a pill',
      (tester) async {
    await tester.pumpWidget(_wrap(const BuyOnetimeScreen()));
    await tester.pumpAndSettle();

    // Initial state: amount hero shows 0 kr, button disabled.
    expect(find.text('0 kr'), findsOneWidget);
    expect(_continueButton(tester).onPressed, isNull);

    // The pill is the only '100 kr' on screen before selection.
    expect(find.text('100 kr'), findsOneWidget);
    await tester.tap(find.text('100 kr'));
    await tester.pumpAndSettle();

    // Amount is now 100 kr (shown by both the pill and the hero), 0 kr gone,
    // and the button is enabled.
    expect(find.text('0 kr'), findsNothing);
    expect(find.text('100 kr'), findsNWidgets(2));
    expect(_continueButton(tester).onPressed, isNotNull);
  });

  testWidgets('a different pill sets its own amount', (tester) async {
    await tester.pumpWidget(_wrap(const BuyOnetimeScreen()));
    await tester.pumpAndSettle();

    // Use a non-grouped amount: the hero formats via NumberFormat(sv_SE),
    // whose thousands separator is a non-breaking space, so a grouped label
    // like '5 000 kr' (ASCII space) wouldn't string-match the hero.
    await tester.tap(find.text('500 kr'));
    await tester.pumpAndSettle();

    expect(find.text('500 kr'), findsNWidgets(2));
    expect(_continueButton(tester).onPressed, isNotNull);
  });
}

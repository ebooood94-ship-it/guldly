// Widget test for the add-funds amount-entry flow: tapping a suggestion pill
// sets the amount, and the continue button is disabled at 0 kr and enabled
// once an amount is chosen.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guldly/core/models/models.dart';
import 'package:guldly/core/providers/providers.dart';
import 'package:guldly/presentation/screens/wallet/add_funds_screen.dart';
import 'package:guldly/presentation/widgets/common/gold_button.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _mockWallet = Wallet(
  id: 'wallet-1',
  userId: 'user-1',
  balanceSek: 500,
  goldGrams: 0,
);

List<Override> _overrides() => [
      walletProvider.overrideWith((ref) async => _mockWallet),
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
    await tester.pumpWidget(_wrap(const AddFundsScreen()));
    await tester.pumpAndSettle();

    // Amount hero starts at 0 kr; button disabled. (The wallet balance renders
    // as 'Nuvarande saldo: 500 kr', a distinct string.)
    expect(find.text('0 kr'), findsOneWidget);
    expect(_continueButton(tester).onPressed, isNull);

    expect(find.text('250 kr'), findsOneWidget); // just the pill
    await tester.tap(find.text('250 kr'));
    await tester.pumpAndSettle();

    // Amount set to 250 kr (pill + hero), 0 kr gone, button enabled.
    expect(find.text('0 kr'), findsNothing);
    expect(find.text('250 kr'), findsNWidgets(2));
    expect(_continueButton(tester).onPressed, isNotNull);
  });
}

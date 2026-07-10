// Regression tests for the removed "bank transfer" payment method.
//
// Background: rpc_buy_gold and rpc_add_funds credit gold_grams / balance_sek
// unconditionally for any non-wallet payment method. Card payments are
// verified by Stripe before the RPC is called, but bank transfer had no
// verification at all — selecting it credited the account instantly for free.
// The option is removed from the UI and blocked in GoldTransactionService
// until a real pending/confirm flow exists.
//
// Server side: since migration 003 rpc_buy_gold rejects every
// payment_method except 'wallet' and rpc_add_funds is revoked from client
// roles — card payments are credited only by the stripe-webhook edge
// function (see docs/stripe-webhook-test-plan.md).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guldly/core/models/models.dart';
import 'package:guldly/core/providers/providers.dart';
import 'package:guldly/presentation/screens/buy_gold/buy_gold_screen.dart';
import 'package:guldly/presentation/screens/wallet/add_funds_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _mockWallet = Wallet(
  id: 'wallet-1',
  userId: 'user-1',
  balanceSek: 500,
  goldGrams: 1.25,
);

List<Override> _overrides() => [
      walletProvider.overrideWith((ref) async => _mockWallet),
      goldPriceProvider.overrideWith((ref) async => GoldPrice.mock),
      // Dummy client: never reached in these tests, but keeps providers that
      // depend on supabaseProvider from touching Supabase.instance.
      supabaseProvider.overrideWithValue(SupabaseClient(
        'http://localhost:54321',
        'test',
        // Without this the client starts a periodic token-refresh timer,
        // which the widget-test binding flags as a pending timer.
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      )),
    ];

Widget _wrap(Widget child) => ProviderScope(
      overrides: _overrides(),
      child: MaterialApp(home: child),
    );

void main() {
  group('bank transfer removed from UI', () {
    testWidgets('AddFundsScreen offers no bank transfer option',
        (tester) async {
      await tester.pumpWidget(_wrap(const AddFundsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Banköverföring'), findsNothing);
      expect(find.text('Kredit-/betalkort'), findsOneWidget);
    });

    testWidgets('BuyGoldScreen offers no bank transfer option',
        (tester) async {
      await tester.pumpWidget(_wrap(const BuyGoldScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Direktöverföring'), findsNothing);
      expect(find.text('Banköverföring'), findsNothing);
      expect(find.text('Plånbok'), findsOneWidget);
      expect(find.text('Bankkort'), findsOneWidget);
    });
  });

  group('GoldTransactionService rejects bank transfer', () {
    late ProviderContainer container;
    late GoldTransactionService service;

    setUp(() {
      container = ProviderContainer(overrides: _overrides());
      service = container.read(goldTransactionServiceProvider);
    });

    tearDown(() => container.dispose());

    test('buyGoldOnetime with bank throws and never credits gold_grams',
        () async {
      await expectLater(
        service.buyGoldOnetime(
          amountSek: 1000,
          goldGrams: 1.0,
          goldPricePerGramSek: 1000,
          paymentMethod: 'bank',
        ),
        throwsUnsupportedError,
      );
      // The guard throws before rpc_buy_gold is ever invoked, so the mocked
      // wallet state is untouched.
      final wallet = await container.read(walletProvider.future);
      expect(wallet!.goldGrams, _mockWallet.goldGrams);
      expect(wallet.balanceSek, _mockWallet.balanceSek);
    });

    test('buyGoldOnetime with card throws — cards are credited by the webhook',
        () async {
      // Card payments must never be recorded client-side: the stripe-webhook
      // edge function credits gold after Stripe confirms the payment.
      await expectLater(
        service.buyGoldOnetime(
          amountSek: 1000,
          goldGrams: 1.0,
          goldPricePerGramSek: 1000,
          paymentMethod: 'card',
        ),
        throwsUnsupportedError,
      );
      final wallet = await container.read(walletProvider.future);
      expect(wallet!.goldGrams, _mockWallet.goldGrams);
    });

    test('createRecurringSubscription with bank throws', () async {
      await expectLater(
        service.createRecurringSubscription(
          amountSek: 500,
          frequency: 'Monthly',
          selectedDays: const ['1'],
          paymentMethod: 'bank',
        ),
        throwsUnsupportedError,
      );
    });
  });
}

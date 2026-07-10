// Unit test for GoldTransactionService.paymentToDb — the UI-string → DB-enum
// mapping used when writing transactions/subscriptions.

import 'package:flutter_test/flutter_test.dart';
import 'package:guldly/core/providers/providers.dart';

void main() {
  group('GoldTransactionService.paymentToDb', () {
    test("'card' maps to 'credit_card'", () {
      expect(GoldTransactionService.paymentToDb('card'), 'credit_card');
    });

    test("'bank' maps to 'bank_transfer'", () {
      expect(GoldTransactionService.paymentToDb('bank'), 'bank_transfer');
    });

    test("'wallet' maps to 'wallet'", () {
      expect(GoldTransactionService.paymentToDb('wallet'), 'wallet');
    });

    test('any other/unknown value falls back to wallet', () {
      expect(GoldTransactionService.paymentToDb('swish'), 'wallet');
      expect(GoldTransactionService.paymentToDb(''), 'wallet');
    });
  });
}

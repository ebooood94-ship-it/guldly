// Unit tests for the pure logic in the model layer:
//   - lib/core/models/models.dart   (the live GoldPrice + fromMap parsers)
//   - lib/core/models/gold_price.dart (legacy GoldPrice with buy/sell spread)
//
// Both files declare a class named GoldPrice, so gold_price.dart is imported
// under the `legacy` prefix.

import 'package:flutter_test/flutter_test.dart';
import 'package:guldly/core/models/models.dart';
import 'package:guldly/core/models/gold_price.dart' as legacy;

void main() {
  group('GoldPrice (models.dart) — troy-ounce → gram conversion', () {
    final ts = DateTime(2026, 1, 1);

    test('pricePerGramSek = pricePerOzUsd × usdToSek / 31.1035 (exact case)', () {
      // Chosen so the math lands on a round number by hand:
      //   3110.35 × 10 = 31 103.5 SEK/oz
      //   31 103.5 / 31.1035 = exactly 1000 SEK/g
      final price =
          GoldPrice(pricePerOzUsd: 3110.35, usdToSek: 10.0, timestamp: ts);
      expect(price.pricePerOzSek, closeTo(31103.5, 1e-6));
      expect(price.pricePerGramSek, closeTo(1000.0, 1e-9));
    });

    test('matches a hand-calculated arbitrary case', () {
      final price =
          GoldPrice(pricePerOzUsd: 2000.0, usdToSek: 11.0, timestamp: ts);
      // 2000 × 11 = 22 000 SEK/oz; 22 000 / 31.1035 = 707.316 SEK/g
      expect(price.pricePerOzSek, closeTo(22000.0, 1e-9));
      expect(price.pricePerGramSek, closeTo(22000.0 / 31.1035, 1e-9));
      expect(price.pricePerGramSek, closeTo(707.316, 1e-3));
    });

    test('the two getters stay internally consistent', () {
      final p = GoldPrice.mock;
      // pricePerGramSek is exactly pricePerOzSek / 31.1035
      expect(p.pricePerGramSek * 31.1035, closeTo(p.pricePerOzSek, 1e-6));
      expect(p.pricePerOzSek, closeTo(3320.15 * 9.165, 1e-6));
    });

    test('zero inputs give zero, never NaN', () {
      final p = GoldPrice(pricePerOzUsd: 0, usdToSek: 0, timestamp: ts);
      expect(p.pricePerGramSek, 0.0);
    });
  });

  group('Wallet.fromMap', () {
    test('parses numeric strings/ints to double', () {
      final w = Wallet.fromMap({
        'id': 'w1',
        'user_id': 'u1',
        'balance_sek': 1500, // int from JSON
        'gold_grams': 2.5,
      });
      expect(w.id, 'w1');
      expect(w.userId, 'u1');
      expect(w.balanceSek, 1500.0);
      expect(w.goldGrams, 2.5);
    });
  });

  group('UserProfile', () {
    test('fromMap then toMap round-trips', () {
      const map = {
        'id': 'u1',
        'full_name': 'Test User',
        'avatar_url': null,
        'phone': '070',
      };
      final p = UserProfile.fromMap(map);
      expect(p.fullName, 'Test User');
      expect(p.avatarUrl, isNull);
      expect(p.toMap(), map);
    });
  });

  group('Transaction.fromMap', () {
    test('maps snake_case enum values to camelCase enums', () {
      final t = Transaction.fromMap({
        'id': 't1',
        'user_id': 'u1',
        'type': 'gift_sent',
        'status': 'completed',
        'amount_sek': 250,
        'gold_grams': 0.25,
        'gold_price_per_gram_sek': 1000,
        'payment_method': 'credit_card',
        'recipient_name': 'Ann',
        'recipient_email': 'ann@example.com',
        'delivery_address': null,
        'created_at': '2026-07-10T12:00:00Z',
      });
      expect(t.type, TransactionType.giftSent);
      expect(t.status, TransactionStatus.completed);
      expect(t.paymentMethod, PaymentMethod.creditCard);
      expect(t.amountSek, 250.0);
      expect(t.goldGrams, 0.25);
      expect(t.recipientEmail, 'ann@example.com');
      expect(t.deliveryAddress, isNull);
      expect(t.createdAt, DateTime.utc(2026, 7, 10, 12));
    });

    test('leaves optional fields null when absent', () {
      final t = Transaction.fromMap({
        'id': 't2',
        'user_id': 'u1',
        'type': 'add_funds',
        'status': 'pending',
        'amount_sek': 100,
        'created_at': '2026-07-10T12:00:00Z',
      });
      expect(t.type, TransactionType.addFunds);
      expect(t.goldGrams, isNull);
      expect(t.paymentMethod, isNull);
    });
  });

  group('Subscription.fromMap', () {
    test('parses frequency, payment method and days', () {
      final s = Subscription.fromMap({
        'id': 's1',
        'user_id': 'u1',
        'amount_sek': 500,
        'frequency': 'monthly',
        'days_of_week': ['monday', 'friday'],
        'day_of_month': 1,
        'payment_method': 'bank_transfer',
        'is_active': true,
        'next_payment_date': '2026-08-01',
      });
      expect(s.frequency, RecurringFrequency.monthly);
      expect(s.paymentMethod, PaymentMethod.bankTransfer);
      expect(s.daysOfWeek, ['monday', 'friday']);
      expect(s.isActive, isTrue);
      expect(s.nextPaymentDate, DateTime(2026, 8, 1));
    });
  });

  group('NotificationPreferences', () {
    test('fromMap applies documented defaults for missing keys', () {
      final n = NotificationPreferences.fromMap({'user_id': 'u1'});
      expect(n.pushPriceAlerts, isTrue);
      expect(n.pushPromotions, isFalse);
      expect(n.emailSecurityAlerts, isTrue);
      expect(n.smsEnabled, isFalse);
    });

    test('copyWith changes only the named field', () {
      const n = NotificationPreferences(userId: 'u1');
      final updated = n.copyWith(pushPromotions: true);
      expect(updated.pushPromotions, isTrue);
      expect(updated.pushPriceAlerts, n.pushPriceAlerts);
      expect(updated.userId, 'u1');
    });

    test('toMap omits user_id and preserves flags', () {
      const n = NotificationPreferences(userId: 'u1', smsEnabled: true);
      final map = n.toMap();
      expect(map.containsKey('user_id'), isFalse);
      expect(map['sms_enabled'], isTrue);
      expect(map['push_price_alerts'], isTrue);
    });
  });

  group('GoldPrice (legacy gold_price.dart) — 2% buy/sell spread', () {
    test('fromJson applies ±2% around the market price', () {
      final p = legacy.GoldPrice.fromJson({
        'market_price': 1000.0,
        'timestamp': '2026-07-10T12:00:00Z',
        'currency': 'SEK',
      });
      expect(p.marketPricePerGram, 1000.0);
      expect(p.buyPricePerGram, closeTo(1020.0, 1e-9));
      expect(p.sellPricePerGram, closeTo(980.0, 1e-9));
      expect(p.pricePerGramSek, 1000.0);
      expect(p.pricePerOzSek, closeTo(31103.5, 1e-6));
    });
  });
}

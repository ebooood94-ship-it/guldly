import 'dart:convert';
import 'package:http/http.dart' as http;

const _publishableKey =
    'pk_test_51TUpnp5YGUKTIsY7CugQwPteWhQm1sFJJLnmS0IzWAYt7BrNqdOxQ0FaMWT6rkmOgtbDHpyvXs9I1lUlIXI0ceQh00FT57ufJh';

/// Creates a Stripe PaymentMethod from raw card data, then confirms the
/// PaymentIntent identified by [clientSecret].
///
/// Works on all platforms (web + mobile) via Stripe's REST API.
/// Raw card data is accepted in test mode; in production use Stripe Elements.
Future<bool> confirmCardWithStripeJs({
  required String clientSecret,
  required String cardNumber,
  required String expiry,
  required String cvc,
  required String name,
}) async {
  final expParts = expiry.split('/');
  if (expParts.length != 2) throw Exception('Invalid expiry format');
  final expMonth = expParts[0].trim();
  final expYear = '20${expParts[1].trim()}';

  final headers = {
    'Authorization': 'Bearer $_publishableKey',
    'Content-Type': 'application/x-www-form-urlencoded',
  };

  // Step 1 — tokenise card into a PaymentMethod
  final pmRes = await http.post(
    Uri.parse('https://api.stripe.com/v1/payment_methods'),
    headers: headers,
    body: {
      'type': 'card',
      'card[number]': cardNumber.replaceAll(' ', ''),
      'card[exp_month]': expMonth,
      'card[exp_year]': expYear,
      'card[cvc]': cvc,
      'billing_details[name]': name,
    },
  );

  final pmData = jsonDecode(pmRes.body) as Map<String, dynamic>;
  if (pmData['error'] != null) {
    throw Exception((pmData['error'] as Map)['message'] ?? 'Card declined');
  }
  final pmId = pmData['id'] as String;

  // Step 2 — confirm the PaymentIntent
  // The client secret format is: pi_xxx_secret_yyy
  final piId = clientSecret.split('_secret_').first;

  final confirmRes = await http.post(
    Uri.parse('https://api.stripe.com/v1/payment_intents/$piId/confirm'),
    headers: headers,
    body: {
      'payment_method': pmId,
      'client_secret': clientSecret,
    },
  );

  final confirmData = jsonDecode(confirmRes.body) as Map<String, dynamic>;
  if (confirmData['error'] != null) {
    throw Exception(
        (confirmData['error'] as Map)['message'] ?? 'Payment failed');
  }
  return confirmData['status'] == 'succeeded';
}

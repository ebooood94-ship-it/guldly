import 'package:supabase_flutter/supabase_flutter.dart';

/// Charges a card server-side via the Supabase edge function.
///
/// The edge function uses the Stripe **secret** key to tokenise raw card data,
/// which bypasses the publishable-key surface restriction that blocks
/// direct REST calls from the browser.
Future<bool> confirmCardWithStripeJs({
  required SupabaseClient supabase,
  required double amountSek,
  required String cardNumber,
  required String expiry,
  required String cvc,
  required String name,
}) async {
  final expParts = expiry.split('/');
  if (expParts.length != 2) throw Exception('Invalid expiry format');
  final expMonth = expParts[0].trim();
  final expYear = '20${expParts[1].trim()}';

  final response = await supabase.functions.invoke(
    'create-payment-intent',
    body: {
      'amount': amountSek,
      'currency': 'sek',
      'cardNumber': cardNumber.replaceAll(' ', ''),
      'expMonth': int.parse(expMonth),
      'expYear': int.parse(expYear),
      'cvc': cvc,
      'name': name,
    },
  );

  final data = response.data as Map<String, dynamic>?;
  if (data == null) throw Exception('Payment service unavailable');
  if (data['error'] != null) throw Exception(data['error'] as String);
  return data['succeeded'] == true;
}

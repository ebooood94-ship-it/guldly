import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _publishableKey =
    'pk_test_51TUpnp5YGUKTIsY7CugQwPteWhQm1sFJJLnmS0IzWAYt7BrNqdOxQ0FaMWT6rkmOgtbDHpyvXs9I1lUlIXI0ceQh00FT57ufJh';

class StripeService {
  static void initialize(String publishableKey) {
    Stripe.publishableKey = publishableKey;
  }

  static Future<bool> pay({
    required double amountSek,
    required SupabaseClient supabase,
  }) async {
    // Ensure key is set — needed on web where eager init may have been skipped
    Stripe.publishableKey = _publishableKey;

    // 1. Create PaymentIntent server-side
    final response = await supabase.functions.invoke(
      'create-payment-intent',
      body: {'amount': amountSek, 'currency': 'sek'},
    );

    if (response.data == null || response.data['clientSecret'] == null) {
      throw Exception('Failed to create payment intent');
    }

    final clientSecret = response.data['clientSecret'] as String;

    // 2. Initialise the payment sheet
    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: clientSecret,
        merchantDisplayName: 'Guldly',
      ),
    );

    // 3. Present sheet
    try {
      await Stripe.instance.presentPaymentSheet();
      return true;
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) return false;
      throw Exception(e.error.localizedMessage ?? 'Payment failed');
    }
  }
}

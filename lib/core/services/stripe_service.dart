import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StripeService {
  /// Call once in main() before runApp.
  static void initialize(String publishableKey) {
    Stripe.publishableKey = publishableKey;
  }

  /// Creates a Stripe PaymentIntent via the Edge Function, presents the
  /// native payment sheet, and returns true if payment succeeded.
  /// Returns false if the user cancelled. Throws on failure.
  static Future<bool> pay({
    required double amountSek,
    required SupabaseClient supabase,
  }) async {
    // 1. Create PaymentIntent server-side (Stripe secret key never touches client)
    final response = await supabase.functions.invoke(
      'create-payment-intent',
      body: {'amount': amountSek, 'currency': 'sek'},
    );

    if (response.data == null || response.data['clientSecret'] == null) {
      throw Exception('Failed to create payment intent');
    }

    final clientSecret = response.data['clientSecret'] as String;

    // 2. Initialise the native payment sheet
    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: clientSecret,
        merchantDisplayName: 'Guldly',
      ),
    );

    // 3. Present sheet — throws StripeException on cancel or failure
    try {
      await Stripe.instance.presentPaymentSheet();
      return true;
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) return false;
      throw Exception(e.error.localizedMessage ?? 'Payment failed');
    }
  }
}

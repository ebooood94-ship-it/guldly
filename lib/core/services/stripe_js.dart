// This file is intentionally minimal.
// Card tokenization is now handled by flutter_stripe's CardField widget
// (Stripe Elements iframe) directly in card_checkout_sheet.dart.
// The edge function confirms the PaymentIntent server-side using the
// payment method id returned by Stripe.instance.createPaymentMethod().

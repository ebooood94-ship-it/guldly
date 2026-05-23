import 'package:supabase_flutter/supabase_flutter.dart';

/// Converts any raw exception into a short, plain-English string suitable
/// for showing to the user.
String friendlyError(Object e) {
  // PostgrestException — has a clean .message field
  if (e is PostgrestException) {
    return _mapMessage(e.message);
  }

  final raw = e.toString();

  // Strip "Exception: " prefix thrown by Dart
  if (raw.startsWith('Exception: ')) {
    return _mapMessage(raw.substring(11));
  }

  // Parse the ugly toString() format of PostgrestException:
  // "PostgrestException(message: Insufficient gold, code: P0001, ...)"
  final pgMatch =
      RegExp(r'PostgrestException\(message: ([^,]+)').firstMatch(raw);
  if (pgMatch != null) {
    return _mapMessage(pgMatch.group(1)!.trim());
  }

  return _mapMessage(raw);
}

/// Maps a known technical phrase to a friendly sentence. Falls back to
/// the original text if it is already short and readable.
String _mapMessage(String raw) {
  final lower = raw.toLowerCase().trim();

  if (lower.contains('insufficient gold') ||
      lower.contains('not enough gold')) {
    return 'You don\'t have enough gold for this transaction.';
  }
  if (lower.contains('insufficient wallet') ||
      lower.contains('insufficient balance') ||
      lower.contains('insufficient funds')) {
    return 'Your wallet balance is too low — please add funds first.';
  }
  if (lower.contains('not authenticated') || lower == 'not authenticated') {
    return 'You\'re not signed in. Please log in and try again.';
  }
  if (lower.contains('gold price') &&
      (lower.contains('unavailable') || lower.contains('error'))) {
    return 'Live gold prices are temporarily unavailable — try again shortly.';
  }
  if (lower.contains('network') ||
      lower.contains('socket') ||
      lower.contains('connection refused') ||
      lower.contains('failed host lookup')) {
    return 'No internet connection — check your network and try again.';
  }
  if (lower.contains('timeout') || lower.contains('timed out')) {
    return 'The request timed out — please try again.';
  }
  if (lower.contains('duplicate key') || lower.contains('unique constraint')) {
    return 'Den här posten finns redan.';
  }
  if (lower.contains('user already registered') ||
      lower.contains('already been registered') ||
      lower.contains('already registered')) {
    return 'Den här e-postadressen är redan registrerad. Försök logga in istället.';
  }
  if (lower.contains('invalid email') ||
      lower.contains('email format') ||
      lower.contains('unable to validate email')) {
    return 'Ange en giltig e-postadress.';
  }
  if (lower.contains('weak password') ||
      lower.contains('password should be') ||
      lower.contains('password must be')) {
    return 'Lösenordet måste vara minst 6 tecken långt.';
  }
  if (lower.contains('invalid login') ||
      lower.contains('invalid credentials')) {
    return 'Fel e-post eller lösenord — försök igen.';
  }
  if (lower.contains('email not confirmed')) {
    return 'Bekräfta din e-postadress innan du loggar in.';
  }
  if (lower.contains('signup is disabled') ||
      lower.contains('signups not allowed')) {
    return 'Registrering är för tillfället stängd.';
  }

  // Already a short, human-readable sentence → return as-is
  if (raw.length <= 80 &&
      !raw.contains('(') &&
      !raw.contains('{') &&
      !raw.contains('Exception')) {
    // Capitalise first letter
    return raw[0].toUpperCase() + raw.substring(1);
  }

  return 'Något gick fel — försök igen.';
}

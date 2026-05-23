import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

final supabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// ─── Auth ─────────────────────────────────────────────────────────────────────
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(supabaseProvider).auth.onAuthStateChange;
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(supabaseProvider).auth.currentUser;
});

// ─── Profile ──────────────────────────────────────────────────────────────────
final profileProvider = FutureProvider<UserProfile?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  final supabase = ref.watch(supabaseProvider);
  final data =
      await supabase.from('profiles').select().eq('id', user.id).maybeSingle();
  if (data == null) return null;
  return UserProfile.fromMap(data);
});

// ─── Theme ────────────────────────────────────────────────────────────────────
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);

// ─── Onboarding ───────────────────────────────────────────────────────────────
final onboardingCompleteProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('onboarding_complete') ?? false;
});

// ─── Gold Price History (last 20 readings for mini chart) ─────────────────────
final goldPriceHistoryProvider = StateProvider<List<double>>((ref) => []);

// ─── Gold Price ───────────────────────────────────────────────────────────────
final goldPriceProvider = FutureProvider<GoldPrice>((ref) async {
  ref.keepAlive();

  // Refresh every 60 seconds
  final timer = Timer.periodic(const Duration(seconds: 60), (_) {
    ref.invalidateSelf();
  });
  ref.onDispose(timer.cancel);

  // Call the server-side edge function to avoid CORS issues on web
  final supabase = ref.read(supabaseProvider);
  final response = await supabase.functions.invoke('get-gold-price');

  if (response.data == null) {
    throw Exception('Gold price service unavailable');
  }

  final data = response.data as Map<String, dynamic>;

  if (data['error'] != null) {
    throw Exception('Gold price error: ${data['error']}');
  }

  final pricePerOzUsd = (data['pricePerOzUsd'] as num).toDouble();
  final usdToSek = (data['usdToSek'] as num).toDouble();

  final price = GoldPrice(
    pricePerOzUsd: pricePerOzUsd,
    usdToSek: usdToSek,
    timestamp: DateTime.now(),
  );

  // Append to history (keep last 20 readings for mini chart)
  final history = ref.read(goldPriceHistoryProvider);
  ref.read(goldPriceHistoryProvider.notifier).state = [
    ...history.skip(history.length > 19 ? history.length - 19 : 0),
    price.pricePerGramSek,
  ];

  return price;
});

// ─── Wallet ───────────────────────────────────────────────────────────────────
final walletProvider = FutureProvider<Wallet?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  final supabase = ref.watch(supabaseProvider);
  final data = await supabase
      .from('wallets')
      .select()
      .eq('user_id', user.id)
      .maybeSingle();
  if (data == null) return null;
  return Wallet.fromMap(data);
});

// ─── First-login Setup (idempotent row creation) ───────────────────────────────
final firstLoginSetupProvider = FutureProvider<void>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return;
  final supabase = ref.watch(supabaseProvider);
  // ignoreDuplicates: true → INSERT … ON CONFLICT DO NOTHING
  // This ensures we never overwrite existing balances, grams, or preferences
  // when auth re-fires (e.g. after a Stripe redirect cold-start).
  await Future.wait([
    supabase.from('profiles').upsert({
      'id': user.id,
      'full_name': user.userMetadata?['full_name'] ?? '',
    }, onConflict: 'id', ignoreDuplicates: true),
    supabase.from('wallets').upsert({
      'user_id': user.id,
      'balance_sek': 0.0,
      'gold_grams': 0.0,
    }, onConflict: 'user_id', ignoreDuplicates: true),
    supabase.from('notification_preferences').upsert({
      'user_id': user.id,
      'push_price_alerts': true,
      'push_transaction_updates': true,
      'push_promotions': false,
      'email_weekly_reports': true,
      'email_monthly_statements': true,
      'email_security_alerts': true,
      'email_product_updates': false,
      'sms_enabled': false,
      'sms_transaction_updates': false,
    }, onConflict: 'user_id', ignoreDuplicates: true),
  ]);
});

// ─── Transactions ─────────────────────────────────────────────────────────────
final transactionsProvider = FutureProvider<List<Transaction>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  final supabase = ref.watch(supabaseProvider);
  final data = await supabase
      .from('transactions')
      .select()
      .eq('user_id', user.id)
      .order('created_at', ascending: false)
      .limit(50);
  return (data as List).map((e) => Transaction.fromMap(e)).toList();
});

// ─── Subscriptions ────────────────────────────────────────────────────────────
final subscriptionsProvider = FutureProvider<List<Subscription>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  final supabase = ref.watch(supabaseProvider);
  final data = await supabase
      .from('subscriptions')
      .select()
      .eq('user_id', user.id)
      .eq('is_active', true);
  return (data as List).map((e) => Subscription.fromMap(e)).toList();
});

// ─── Notification Preferences ─────────────────────────────────────────────────
final notificationPrefsProvider = StateNotifierProvider<
    NotificationPrefsNotifier, AsyncValue<NotificationPreferences?>>((ref) {
  return NotificationPrefsNotifier(ref);
});

class NotificationPrefsNotifier
    extends StateNotifier<AsyncValue<NotificationPreferences?>> {
  final Ref _ref;

  NotificationPrefsNotifier(this._ref) : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    final user = _ref.read(currentUserProvider);
    if (user == null) {
      state = const AsyncValue.data(null);
      return;
    }
    try {
      final data = await _ref
          .read(supabaseProvider)
          .from('notification_preferences')
          .select()
          .eq('user_id', user.id)
          .single();
      state = AsyncValue.data(NotificationPreferences.fromMap(data));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> update(NotificationPreferences prefs) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return;
    final prev = state;
    state = AsyncValue.data(prefs);
    try {
      await _ref
          .read(supabaseProvider)
          .from('notification_preferences')
          .update(
            prefs.toMap()..['updated_at'] = DateTime.now().toIso8601String(),
          )
          .eq('user_id', user.id);
    } catch (_) {
      state = prev;
    }
  }
}

// ─── Selected Payment Method (shared between BuyGoldScreen and sub-screens) ───
final selectedPaymentMethodProvider = StateProvider<String>((ref) => 'wallet');

// ─── Gold Transaction Service ──────────────────────────────────────────────────
final goldTransactionServiceProvider = Provider<GoldTransactionService>((ref) {
  return GoldTransactionService(ref.watch(supabaseProvider), ref);
});

class GoldTransactionService {
  final SupabaseClient _supabase;
  final Ref _ref;

  GoldTransactionService(this._supabase, this._ref);

  static String _paymentToDb(String method) {
    if (method == 'card') return 'credit_card';
    if (method == 'bank') return 'bank_transfer';
    return 'wallet';
  }

  Future<void> buyGoldOnetime({
    required double amountSek,
    required double goldGrams,
    required double goldPricePerGramSek,
    required String paymentMethod,
  }) async {
    if (_ref.read(currentUserProvider) == null) throw Exception('Not authenticated');
    await _supabase.rpc('rpc_buy_gold', params: {
      'p_gold_grams': goldGrams,
      'p_amount_sek': amountSek,
      'p_price_per_gram': goldPricePerGramSek,
      'p_payment_method': _paymentToDb(paymentMethod),
    });
    _ref.invalidate(walletProvider);
    _ref.invalidate(transactionsProvider);
  }

  Future<void> createRecurringSubscription({
    required double amountSek,
    required String frequency,
    required List<String> selectedDays,
    required String paymentMethod,
  }) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) throw Exception('Not authenticated');
    final dbFreq = frequency.toLowerCase();
    final now = DateTime.now();
    final nextDate = dbFreq == 'daily'
        ? now.add(const Duration(days: 1))
        : dbFreq == 'weekly'
            ? now.add(const Duration(days: 7))
            : DateTime(now.year, now.month + 1, 1);
    await _supabase.from('subscriptions').insert({
      'user_id': user.id,
      'amount_sek': amountSek,
      'frequency': dbFreq,
      'days_of_week': dbFreq == 'weekly' ? selectedDays : null,
      'day_of_month': dbFreq == 'monthly' ? 1 : null,
      'payment_method': _paymentToDb(paymentMethod),
      'is_active': true,
      'next_payment_date': nextDate.toIso8601String(),
    });
    _ref.invalidate(subscriptionsProvider);
  }

  Future<void> sellGold({
    required double goldGrams,
    required double goldPricePerGramSek,
  }) async {
    if (_ref.read(currentUserProvider) == null) throw Exception('Not authenticated');
    await _supabase.rpc('rpc_sell_gold', params: {
      'p_gold_grams': goldGrams,
      'p_price_per_gram': goldPricePerGramSek,
    });
    _ref.invalidate(walletProvider);
    _ref.invalidate(transactionsProvider);
  }

  Future<void> addFunds({
    required double amountSek,
    required String paymentMethod,
  }) async {
    if (_ref.read(currentUserProvider) == null) throw Exception('Not authenticated');
    await _supabase.rpc('rpc_add_funds', params: {
      'p_amount_sek': amountSek,
      'p_payment_method': _paymentToDb(paymentMethod),
    });
    _ref.invalidate(walletProvider);
    _ref.invalidate(transactionsProvider);
  }

  Future<void> sendGift({
    required double amountSek,
    required double goldGrams,
    required String recipientName,
    required String recipientEmail,
    required double goldPricePerGramSek,
    required bool isSEKMode,
  }) async {
    if (_ref.read(currentUserProvider) == null) throw Exception('Not authenticated');
    await _supabase.rpc('rpc_send_gift', params: {
      'p_amount_sek': isSEKMode ? amountSek : goldGrams * goldPricePerGramSek,
      'p_gold_grams': isSEKMode ? amountSek / goldPricePerGramSek : goldGrams,
      'p_recipient_name': recipientName,
      'p_recipient_email': recipientEmail,
      'p_price_per_gram': goldPricePerGramSek,
      'p_is_sek_mode': isSEKMode,
    });
    _ref.invalidate(walletProvider);
    _ref.invalidate(transactionsProvider);
  }

  Future<void> cancelSubscription(String subscriptionId) async {
    await _supabase
        .from('subscriptions')
        .update({'is_active': false})
        .eq('id', subscriptionId);
    _ref.invalidate(subscriptionsProvider);
  }

  Future<void> updateSubscription({
    required String subscriptionId,
    required double amountSek,
    required String frequency,
    required List<String> selectedDays,
    required DateTime nextPaymentDate,
  }) async {
    final dbFreq = frequency.toLowerCase();
    await _supabase.from('subscriptions').update({
      'amount_sek': amountSek,
      'frequency': dbFreq,
      'days_of_week': dbFreq == 'weekly' ? selectedDays : null,
      'day_of_month': dbFreq == 'monthly' ? 1 : null,
      'next_payment_date': nextPaymentDate.toIso8601String(),
    }).eq('id', subscriptionId);
    _ref.invalidate(subscriptionsProvider);
  }

  Future<void> requestDelivery({
    required double goldGrams,
    required String deliveryAddress,
  }) async {
    if (_ref.read(currentUserProvider) == null) throw Exception('Not authenticated');
    await _supabase.rpc('rpc_request_delivery', params: {
      'p_gold_grams': goldGrams,
      'p_delivery_address': deliveryAddress,
    });
    _ref.invalidate(walletProvider);
    _ref.invalidate(transactionsProvider);
  }
}

// ─── Auth Notifier ────────────────────────────────────────────────────────────
final authNotifierProvider = Provider<AuthNotifier>((ref) {
  return AuthNotifier(ref.watch(supabaseProvider));
});

class AuthNotifier {
  final SupabaseClient _supabase;
  AuthNotifier(this._supabase);

  Future<void> signIn({required String email, required String password}) async {
    await _supabase.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  Future<void> updatePassword(String newPassword) async {
    await _supabase.auth.updateUser(UserAttributes(password: newPassword));
  }

  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }
}

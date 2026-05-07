import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      await supabase.from('profiles').select().eq('id', user.id).single();
  return UserProfile.fromMap(data);
});

// ─── Gold Price ───────────────────────────────────────────────────────────────
final goldPriceProvider = FutureProvider<GoldPrice>((ref) async {
  // Step 1: Get XAU/USD from GoldAPI
  final goldRes = await http.get(
    Uri.parse('https://www.goldapi.io/api/XAU/USD'),
    headers: {'x-access-token': 'goldapi-80rqlsmo6ribne-io'},
  );

  if (goldRes.statusCode != 200) throw Exception('GoldAPI error');
  final goldData = jsonDecode(goldRes.body) as Map<String, dynamic>;
  final priceUsd = (goldData['price'] as num).toDouble();

  // Step 2: Get USD→SEK from MetalPriceAPI
  final fxRes = await http.get(
    Uri.parse(
      'https://api.metalpriceapi.com/v1/latest'
      '?api_key=315ccf20017e1e6d34635327d8670683'
      '&base=SEK&currencies=USD',
    ),
  );

  if (fxRes.statusCode != 200) throw Exception('MetalPriceAPI error');
  final fxData = jsonDecode(fxRes.body) as Map<String, dynamic>;

  // rates.SEKUSD = how many SEK per 1 USD
  final sekPerUsd = (fxData['rates']['SEKUSD'] as num).toDouble();

  return GoldPrice(
    pricePerOzUsd: priceUsd,
    usdToSek: sekPerUsd,
    timestamp: DateTime.now(),
  );
});

// ─── Wallet ───────────────────────────────────────────────────────────────────
final walletProvider = FutureProvider<Wallet?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  final supabase = ref.watch(supabaseProvider);
  final data =
      await supabase.from('wallets').select().eq('user_id', user.id).single();
  return Wallet.fromMap(data);
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
}

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  static SupabaseClient? _supabase;
  static RealtimeChannel? _channel;

  static Future<void> initialize(SupabaseClient supabase) async {
    _supabase = supabase;
  }

  /// Subscribe to real-time transaction updates and show in-app banners.
  static void listenForTransactions(
    BuildContext context,
    String userId,
  ) {
    _channel?.unsubscribe();
    _channel = _supabase!
        .channel('transactions:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'transactions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            if (!context.mounted) return;
            final type = payload.newRecord['type'] as String? ?? '';
            final amount =
                (payload.newRecord['amount_sek'] as num?)?.toDouble() ?? 0;
            _showBanner(context, type, amount);
          },
        )
        .subscribe();
  }

  static void stopListening() {
    _channel?.unsubscribe();
    _channel = null;
  }

  /// Save device push token to Supabase for future FCM integration.
  static Future<void> savePushToken(String token, String platform) async {
    final user = _supabase?.auth.currentUser;
    if (user == null) return;
    await _supabase?.from('push_tokens').upsert(
      {'user_id': user.id, 'token': token, 'platform': platform},
      onConflict: 'user_id, token',
    );
  }

  static void _showBanner(BuildContext context, String type, double amount) {
    final label = _label(type);
    final amtStr = amount > 0
        ? ' · kr.${amount.toStringAsFixed(0)}'
        : '';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text('$label$amtStr',
              style: const TextStyle(fontWeight: FontWeight.w500)),
        ]),
        backgroundColor: const Color(0xFF2D7A4F),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  static String _label(String type) {
    switch (type) {
      case 'buy':
        return 'Gold purchased';
      case 'sell':
        return 'Gold sold';
      case 'add_funds':
        return 'Funds added';
      case 'gift_sent':
        return 'Gift sent';
      case 'gift_received':
        return 'Gift received';
      case 'delivery':
        return 'Delivery requested';
      case 'recurring_buy':
        return 'Recurring purchase completed';
      default:
        return 'Transaction completed';
    }
  }
}

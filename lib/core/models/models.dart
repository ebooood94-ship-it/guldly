class GoldPrice {
  final double pricePerOzUsd;
  final double usdToSek;
  final DateTime timestamp;

  const GoldPrice({
    required this.pricePerOzUsd,
    required this.usdToSek,
    required this.timestamp,
  });

  double get pricePerOzSek => pricePerOzUsd * usdToSek;
  double get pricePerGramSek => pricePerOzSek / 31.1035;

  static final GoldPrice mock = GoldPrice(
    pricePerOzUsd: 3320.15,
    usdToSek: 9.165,
    timestamp: DateTime(2025, 1, 1),
  );
}

// ─── user_profile.dart ────────────────────────────────────────────────────────
class UserProfile {
  final String id;
  final String? fullName;
  final String? avatarUrl;
  final String? phone;

  const UserProfile({
    required this.id,
    this.fullName,
    this.avatarUrl,
    this.phone,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      fullName: map['full_name'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      phone: map['phone'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'full_name': fullName,
        'avatar_url': avatarUrl,
        'phone': phone,
      };
}

// ─── wallet.dart ──────────────────────────────────────────────────────────────
class Wallet {
  final String id;
  final String userId;
  final double balanceSek;
  final double goldGrams;

  const Wallet({
    required this.id,
    required this.userId,
    required this.balanceSek,
    required this.goldGrams,
  });

  factory Wallet.fromMap(Map<String, dynamic> map) {
    return Wallet(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      balanceSek: (map['balance_sek'] as num).toDouble(),
      goldGrams: (map['gold_grams'] as num).toDouble(),
    );
  }
}

// ─── transaction.dart ─────────────────────────────────────────────────────────
enum TransactionType {
  buy,
  sell,
  giftSent,
  giftReceived,
  addFunds,
  delivery,
  recurringBuy,
}

enum TransactionStatus { pending, completed, failed, cancelled }

enum PaymentMethod { wallet, creditCard, bankTransfer }

class Transaction {
  final String id;
  final String userId;
  final TransactionType type;
  final TransactionStatus status;
  final double amountSek;
  final double? goldGrams;
  final double? goldPricePerGramSek;
  final PaymentMethod? paymentMethod;
  final String? recipientName;
  final String? recipientEmail;
  final String? deliveryAddress;
  final DateTime createdAt;

  const Transaction({
    required this.id,
    required this.userId,
    required this.type,
    required this.status,
    required this.amountSek,
    this.goldGrams,
    this.goldPricePerGramSek,
    this.paymentMethod,
    this.recipientName,
    this.recipientEmail,
    this.deliveryAddress,
    required this.createdAt,
  });

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      type: TransactionType.values.byName(
        _snakeToCamel(map['type'] as String),
      ),
      status: TransactionStatus.values.byName(map['status'] as String),
      amountSek: (map['amount_sek'] as num).toDouble(),
      goldGrams: map['gold_grams'] != null
          ? (map['gold_grams'] as num).toDouble()
          : null,
      goldPricePerGramSek: map['gold_price_per_gram_sek'] != null
          ? (map['gold_price_per_gram_sek'] as num).toDouble()
          : null,
      recipientName: map['recipient_name'] as String?,
      recipientEmail: map['recipient_email'] as String?,
      deliveryAddress: map['delivery_address'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  static String _snakeToCamel(String s) {
    final parts = s.split('_');
    return parts.first +
        parts.skip(1).map((p) => p[0].toUpperCase() + p.substring(1)).join();
  }
}

// ─── subscription.dart ────────────────────────────────────────────────────────
enum RecurringFrequency { daily, weekly, monthly }

class Subscription {
  final String id;
  final String userId;
  final double amountSek;
  final RecurringFrequency frequency;
  final List<String>? daysOfWeek;
  final int? dayOfMonth;
  final PaymentMethod paymentMethod;
  final bool isActive;
  final DateTime? nextPaymentDate;

  const Subscription({
    required this.id,
    required this.userId,
    required this.amountSek,
    required this.frequency,
    this.daysOfWeek,
    this.dayOfMonth,
    required this.paymentMethod,
    required this.isActive,
    this.nextPaymentDate,
  });

  factory Subscription.fromMap(Map<String, dynamic> map) {
    return Subscription(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      amountSek: (map['amount_sek'] as num).toDouble(),
      frequency: RecurringFrequency.values.byName(map['frequency'] as String),
      daysOfWeek: (map['days_of_week'] as List?)?.cast<String>(),
      dayOfMonth: map['day_of_month'] as int?,
      paymentMethod: PaymentMethod.values.byName(
        _snakeToCamel(map['payment_method'] as String),
      ),
      isActive: map['is_active'] as bool,
      nextPaymentDate: map['next_payment_date'] != null
          ? DateTime.parse(map['next_payment_date'] as String)
          : null,
    );
  }

  static String _snakeToCamel(String s) {
    final parts = s.split('_');
    return parts.first +
        parts.skip(1).map((p) => p[0].toUpperCase() + p.substring(1)).join();
  }
}

// ─── notification_prefs.dart ──────────────────────────────────────────────────
class NotificationPreferences {
  final String userId;
  // Push
  final bool pushPriceAlerts;
  final bool pushTransactionUpdates;
  final bool pushPromotions;
  // Email
  final bool emailWeeklyReports;
  final bool emailMonthlyStatements;
  final bool emailSecurityAlerts;
  final bool emailProductUpdates;
  // SMS
  final bool smsEnabled;
  final bool smsTransactionUpdates;

  const NotificationPreferences({
    required this.userId,
    this.pushPriceAlerts = true,
    this.pushTransactionUpdates = true,
    this.pushPromotions = false,
    this.emailWeeklyReports = true,
    this.emailMonthlyStatements = true,
    this.emailSecurityAlerts = true,
    this.emailProductUpdates = false,
    this.smsEnabled = false,
    this.smsTransactionUpdates = false,
  });

  factory NotificationPreferences.fromMap(Map<String, dynamic> map) {
    return NotificationPreferences(
      userId: map['user_id'] as String,
      pushPriceAlerts: map['push_price_alerts'] as bool? ?? true,
      pushTransactionUpdates: map['push_transaction_updates'] as bool? ?? true,
      pushPromotions: map['push_promotions'] as bool? ?? false,
      emailWeeklyReports: map['email_weekly_reports'] as bool? ?? true,
      emailMonthlyStatements: map['email_monthly_statements'] as bool? ?? true,
      emailSecurityAlerts: map['email_security_alerts'] as bool? ?? true,
      emailProductUpdates: map['email_product_updates'] as bool? ?? false,
      smsEnabled: map['sms_enabled'] as bool? ?? false,
      smsTransactionUpdates: map['sms_transaction_updates'] as bool? ?? false,
    );
  }

  NotificationPreferences copyWith({
    bool? pushPriceAlerts,
    bool? pushTransactionUpdates,
    bool? pushPromotions,
    bool? emailWeeklyReports,
    bool? emailMonthlyStatements,
    bool? emailSecurityAlerts,
    bool? emailProductUpdates,
    bool? smsEnabled,
    bool? smsTransactionUpdates,
  }) {
    return NotificationPreferences(
      userId: userId,
      pushPriceAlerts: pushPriceAlerts ?? this.pushPriceAlerts,
      pushTransactionUpdates:
          pushTransactionUpdates ?? this.pushTransactionUpdates,
      pushPromotions: pushPromotions ?? this.pushPromotions,
      emailWeeklyReports: emailWeeklyReports ?? this.emailWeeklyReports,
      emailMonthlyStatements:
          emailMonthlyStatements ?? this.emailMonthlyStatements,
      emailSecurityAlerts: emailSecurityAlerts ?? this.emailSecurityAlerts,
      emailProductUpdates: emailProductUpdates ?? this.emailProductUpdates,
      smsEnabled: smsEnabled ?? this.smsEnabled,
      smsTransactionUpdates:
          smsTransactionUpdates ?? this.smsTransactionUpdates,
    );
  }

  Map<String, dynamic> toMap() => {
        'push_price_alerts': pushPriceAlerts,
        'push_transaction_updates': pushTransactionUpdates,
        'push_promotions': pushPromotions,
        'email_weekly_reports': emailWeeklyReports,
        'email_monthly_statements': emailMonthlyStatements,
        'email_security_alerts': emailSecurityAlerts,
        'email_product_updates': emailProductUpdates,
        'sms_enabled': smsEnabled,
        'sms_transaction_updates': smsTransactionUpdates,
      };
}

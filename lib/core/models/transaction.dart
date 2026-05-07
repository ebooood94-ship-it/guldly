enum TransactionType { buy, sell, gift, deposit, withdrawal }

enum TransactionStatus { pending, completed, failed }

class Transaction {
  final String id;
  final String userId;
  final TransactionType type;
  final double amount;
  final String currency;
  final double? goldAmount;
  final double? pricePerGram;
  final TransactionStatus status;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;

  Transaction({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    this.currency = 'SEK',
    this.goldAmount,
    this.pricePerGram,
    required this.status,
    required this.createdAt,
    this.metadata,
  });
}

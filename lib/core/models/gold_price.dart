class GoldPrice {
  final double marketPricePerGram;
  final double buyPricePerGram;
  final double sellPricePerGram;
  final DateTime timestamp;
  final String currency;

  GoldPrice({
    required this.marketPricePerGram,
    required this.buyPricePerGram,
    required this.sellPricePerGram,
    required this.timestamp,
    this.currency = 'SEK',
  });

  factory GoldPrice.fromJson(Map<String, dynamic> json) {
    final marketPrice = json['market_price'] as double;
    const spread = 0.02; // 2%

    return GoldPrice(
      marketPricePerGram: marketPrice,
      buyPricePerGram: marketPrice * (1 + spread),
      sellPricePerGram: marketPrice * (1 - spread),
      timestamp: DateTime.parse(json['timestamp']),
      currency: json['currency'] ?? 'SEK',
    );
  }

  // Convenience getters used throughout the UI
  double get pricePerGramSek => marketPricePerGram;
  double get pricePerOzSek => marketPricePerGram * 31.1035;
  double get buyPricePerGramSek => buyPricePerGram;
  double get sellPricePerGramSek => sellPricePerGram;

  Map<String, dynamic> toJson() => {
        'market_price': marketPricePerGram,
        'buy_price': buyPricePerGram,
        'sell_price': sellPricePerGram,
        'timestamp': timestamp.toIso8601String(),
        'currency': currency,
      };
}

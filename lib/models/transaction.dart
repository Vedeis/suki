class MoneyTransaction {
  final int? id;
  final String title;
  final String category;
  final int amount;
  final String type; // income | expense
  final String source;
  final String? rawText;
  final DateTime createdAt;

  const MoneyTransaction({
    this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.type,
    required this.source,
    this.rawText,
    required this.createdAt,
  });

  Map<String, Object?> toMap() => {
    'id': id, 'title': title, 'category': category, 'amount': amount,
    'type': type, 'source': source, 'raw_text': rawText,
    'created_at': createdAt.toIso8601String(),
  };

  factory MoneyTransaction.fromMap(Map<String, Object?> map) => MoneyTransaction(
    id: map['id'] as int?,
    title: map['title'] as String,
    category: map['category'] as String,
    amount: map['amount'] as int,
    type: map['type'] as String,
    source: map['source'] as String,
    rawText: map['raw_text'] as String?,
    createdAt: DateTime.parse(map['created_at'] as String),
  );
}

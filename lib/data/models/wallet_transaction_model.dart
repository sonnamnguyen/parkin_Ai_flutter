class WalletTransaction {
  final int id;
  final String type;
  final double amount;
  final String description;
  final DateTime createdAt;
  final String status;
  final String? referenceId;

  WalletTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.createdAt,
    required this.status,
    this.referenceId,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id'] ?? 0,
      type: json['type'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      description: json['description'] ?? '',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      status: json['status'] ?? '',
      referenceId: json['reference_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'amount': amount,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'status': status,
      'reference_id': referenceId,
    };
  }

  bool get isIncome => amount > 0;
  bool get isExpense => amount < 0;
}

class WalletTransactionResponse {
  final List<WalletTransaction> transactions;
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final bool hasNextPage;
  final bool hasPreviousPage;

  WalletTransactionResponse({
    required this.transactions,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });

  factory WalletTransactionResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> transactionsJson = json['data'] ?? [];
    final transactions = transactionsJson
        .map((item) => WalletTransaction.fromJson(item))
        .toList();

    final pagination = json['pagination'] ?? {};
    
    return WalletTransactionResponse(
      transactions: transactions,
      currentPage: pagination['current_page'] ?? 1,
      totalPages: pagination['total_pages'] ?? 1,
      totalItems: pagination['total_items'] ?? 0,
      hasNextPage: pagination['has_next_page'] ?? false,
      hasPreviousPage: pagination['has_previous_page'] ?? false,
    );
  }
}

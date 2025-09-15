class FavoriteItem {
  final int id;
  final int userId;
  final int lotId;
  final String lotName;
  final String lotAddress;
  final String createdAt;

  FavoriteItem({
    required this.id,
    required this.userId,
    required this.lotId,
    required this.lotName,
    required this.lotAddress,
    required this.createdAt,
  });

  factory FavoriteItem.fromJson(Map<String, dynamic> json) => FavoriteItem(
    id: _parseInt(json['id']),
    userId: _parseInt(json['user_id']),
    lotId: _parseInt(json['lot_id']),
    lotName: json['lot_name']?.toString() ?? '',
    lotAddress: json['lot_address']?.toString() ?? '',
    createdAt: json['created_at']?.toString() ?? '',
  );

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

class FavoriteListResponse {
  final List<FavoriteItem> list;
  final int total;

  FavoriteListResponse({
    required this.list,
    required this.total,
  });

  factory FavoriteListResponse.fromJson(Map<String, dynamic> json) => FavoriteListResponse(
    list: (json['list'] as List? ?? [])
        .map((e) => FavoriteItem.fromJson((e as Map).cast<String, dynamic>()))
        .toList(),
    total: FavoriteItem._parseInt(json['total']),
  );
}


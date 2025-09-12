class ParkingReview {
  final int id;
  final int lotId;
  final int userId;
  final String username;
  final int rating;
  final String comment;
  final String? createdAt;
  final String? updatedAt;

  ParkingReview({
    required this.id,
    required this.lotId,
    required this.userId,
    required this.username,
    required this.rating,
    required this.comment,
    this.createdAt,
    this.updatedAt,
  });

  factory ParkingReview.fromJson(Map<String, dynamic> json) {
    int _parseInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }
    return ParkingReview(
      id: _parseInt(json['id']),
      lotId: _parseInt(json['lot_id']),
      userId: _parseInt(json['user_id']),
      username: json['username']?.toString() ?? '',
      rating: _parseInt(json['rating']),
      comment: json['comment']?.toString() ?? '',
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lot_id': lotId,
      'user_id': userId,
      'username': username,
      'rating': rating,
      'comment': comment,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

class CreateReviewRequest {
  final int lotId;
  final int rating;
  final String comment;

  CreateReviewRequest({
    required this.lotId,
    required this.rating,
    required this.comment,
  });

  Map<String, dynamic> toJson() {
    return {
      'lot_id': lotId,
      'rating': rating,
      'comment': comment,
    };
  }
}

class UpdateReviewRequest {
  final int id;
  final int lotId;
  final int rating;
  final String comment;

  UpdateReviewRequest({
    required this.id,
    required this.lotId,
    required this.rating,
    required this.comment,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lot_id': lotId,
      'rating': rating,
      'comment': comment,
    };
  }
}

class ReviewListResponse {
  final List<ParkingReview> reviews;
  final int total;
  final int page;
  final int pageSize;

  ReviewListResponse({
    required this.reviews,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  factory ReviewListResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['list'] as List? ?? [])
        .map((e) => ParkingReview.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
    int _parseInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }
    return ReviewListResponse(
      reviews: list,
      total: _parseInt(json['total']),
      page: _parseInt(json['page']),
      pageSize: _parseInt(json['page_size']),
    );
  }
}

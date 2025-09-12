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
    return ParkingReview(
      id: json['id'] as int,
      lotId: json['lot_id'] as int,
      userId: json['user_id'] as int,
      username: json['username'] as String,
      rating: json['rating'] as int,
      comment: json['comment'] as String,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
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
    return ReviewListResponse(
      reviews: (json['list'] as List)
          .map((e) => ParkingReview.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int,
      page: json['page'] as int,
      pageSize: json['page_size'] as int,
    );
  }
}

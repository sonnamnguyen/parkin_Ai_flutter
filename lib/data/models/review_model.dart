import 'package:flutter/material.dart';

class Review {
  final int id;
  final int userId;
  final String userName;
  final String avatarUrl;
  final int rating;
  final String comment;
  final DateTime createdAt;
  final String userInitial;
  final Color userColor;

  Review({
    required this.id,
    required this.userId,
    required this.userName,
    required this.avatarUrl,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.userInitial,
    required this.userColor,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      userName: json['user_name'] ?? '',
      avatarUrl: json['avatar_url'] ?? '',
      rating: json['rating'] ?? 0,
      comment: json['comment'] ?? '',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      userInitial: json['user_name'] != null && json['user_name'].isNotEmpty
          ? json['user_name'][0].toUpperCase()
          : 'U',
      userColor: _getColorFromString(json['user_name'] ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'avatar_url': avatarUrl,
      'rating': rating,
      'comment': comment,
      'created_at': createdAt.toIso8601String(),
    };
  }

  static Color _getColorFromString(String str) {
    if (str.isEmpty) return Colors.grey;
    
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.red,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.amber,
      Colors.cyan,
    ];
    
    final hash = str.hashCode.abs();
    return colors[hash % colors.length];
  }

  Review copyWith({
    int? id,
    int? userId,
    String? userName,
    String? avatarUrl,
    int? rating,
    String? comment,
    DateTime? createdAt,
    String? userInitial,
    Color? userColor,
  }) {
    return Review(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      userInitial: userInitial ?? this.userInitial,
      userColor: userColor ?? this.userColor,
    );
  }

  @override
  String toString() {
    return 'Review(id: $id, userName: $userName, rating: $rating, comment: $comment)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Review && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
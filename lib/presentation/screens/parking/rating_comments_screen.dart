import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_themes.dart';
import '../../../data/models/parking_lot_model.dart';
import '../../../data/models/review_model.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';

class RatingCommentsScreen extends StatefulWidget {
  final ParkingLot parkingLot;

  const RatingCommentsScreen({super.key, required this.parkingLot});

  @override
  State<RatingCommentsScreen> createState() => _RatingCommentsScreenState();
}

class _RatingCommentsScreenState extends State<RatingCommentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _commentController = TextEditingController();
  int _userRating = 0;
  bool _isSubmittingReview = false;

  // Mock reviews data based on your images
  final List<Review> _reviews = [
    Review(
      id: 1,
      userId: 1,
      userName: 'Phan Phúc Nguyên',
      avatarUrl: '',
      rating: 5,
      comment: 'Nhân viên nhiệt tình',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      userInitial: 'N',
      userColor: Colors.green,
    ),
    Review(
      id: 2,
      userId: 2,
      userName: 'Phạm Đăng Khôi',
      avatarUrl: '',
      rating: 4,
      comment: 'Giá rẻ',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      userInitial: 'K',
      userColor: Colors.blue,
    ),
    Review(
      id: 3,
      userId: 3,
      userName: 'Nguyễn Hoàn Đức Min',
      avatarUrl: '',
      rating: 5,
      comment: 'Sạch sẽ rộng rãi',
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
      userInitial: 'M',
      userColor: Colors.red,
    ),
    Review(
      id: 4,
      userId: 4,
      userName: 'Đỗ Trí Hiếu',
      avatarUrl: '',
      rating: 4,
      comment: 'Bãi xe rộng, tiện lợi cho việc đậu xe. Nhân viên thân thiện',
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
      userInitial: 'H',
      userColor: Colors.teal,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildRatingOverview(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildReviewsList(),
                _buildAddReviewForm(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.white,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(
          Icons.arrow_back_ios,
          color: AppColors.darkGrey,
        ),
      ),
      title: Text(
        widget.parkingLot.name,
        style: AppThemes.headingSmall.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          onPressed: () {
            // TODO: Implement filter/sort
          },
          icon: const Icon(
            Icons.tune,
            color: AppColors.darkGrey,
          ),
        ),
      ],
    );
  }

  Widget _buildRatingOverview() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(
          bottom: BorderSide(
            color: AppColors.lightGrey,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Rating Score
          Column(
            children: [
              Text(
                widget.parkingLot.rating.toString(),
                style: AppThemes.headingLarge.copyWith(
                  fontSize: 48,
                  color: AppColors.darkGrey,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < widget.parkingLot.rating.floor()
                        ? Icons.star
                        : Icons.star_border,
                    color: AppColors.warning,
                    size: 16,
                  );
                }),
              ),
              const SizedBox(height: 4),
              Text(
                '(${widget.parkingLot.reviewCount})',
                style: AppThemes.bodySmall,
              ),
            ],
          ),

          const SizedBox(width: 32),

          // Rating Breakdown
          Expanded(
            child: Column(
              children: [
                _buildRatingBar(5, 85),
                _buildRatingBar(4, 60),
                _buildRatingBar(3, 25),
                _buildRatingBar(2, 10),
                _buildRatingBar(1, 5),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingBar(int stars, int percentage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            '$stars',
            style: AppThemes.bodySmall,
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.star,
            color: AppColors.warning,
            size: 12,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: AppColors.lightGrey,
                borderRadius: BorderRadius.circular(3),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: percentage / 100,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$percentage%',
            style: AppThemes.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppColors.white,
      child: TabBar(
        controller: _tabController,
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_outline, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Đánh giá',
                  style: AppThemes.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add_comment_outlined, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Viết đánh giá',
                  style: AppThemes.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primary,
        indicatorWeight: 3,
      ),
    );
  }

  Widget _buildReviewsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _reviews.length,
      itemBuilder: (context, index) {
        final review = _reviews[index];
        return _buildReviewCard(review);
      },
    );
  }

  Widget _buildReviewCard(Review review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // User Avatar
              CircleAvatar(
                radius: 20,
                backgroundColor: review.userColor.withOpacity(0.2),
                backgroundImage: review.avatarUrl.isNotEmpty
                    ? NetworkImage(review.avatarUrl)
                    : null,
                child: review.avatarUrl.isEmpty
                    ? Text(
                        review.userInitial,
                        style: AppThemes.bodyMedium.copyWith(
                          color: review.userColor,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),

              const SizedBox(width: 12),

              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName,
                      style: AppThemes.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatDate(review.createdAt),
                      style: AppThemes.bodySmall,
                    ),
                  ],
                ),
              ),

              // More Options
              PopupMenuButton(
                icon: const Icon(
                  Icons.more_horiz,
                  color: AppColors.textSecondary,
                ),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'report',
                    child: Row(
                      children: [
                        Icon(Icons.report_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('Báo cáo'),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  // Handle menu actions
                },
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Rating Stars
          Row(
            children: List.generate(5, (index) {
              return Icon(
                index < review.rating ? Icons.star : Icons.star_border,
                color: AppColors.warning,
                size: 16,
              );
            }),
          ),

          const SizedBox(height: 8),

          // Comment
          Text(
            review.comment,
            style: AppThemes.bodyMedium.copyWith(
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddReviewForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rating Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Đánh giá của bạn',
                  style: AppThemes.headingSmall.copyWith(
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Chọn số sao:',
                  style: AppThemes.bodyMedium,
                ),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(5, (index) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _userRating = index + 1;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Icon(
                          index < _userRating ? Icons.star : Icons.star_border,
                          color: AppColors.warning,
                          size: 32,
                        ),
                      ),
                    );
                  }),
                ),
                if (_userRating > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    _getRatingText(_userRating),
                    style: AppThemes.bodyMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Comment Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chia sẻ trải nghiệm',
                  style: AppThemes.headingSmall.copyWith(
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _commentController,
                  label: 'Bình luận',
                  hintText: 'Chia sẻ trải nghiệm của bạn về bãi xe này...',
                  maxLines: 4,
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Submit Button
          CustomButton(
            text: 'Gửi đánh giá',
            onPressed: _userRating > 0 ? _submitReview : null,
            isLoading: _isSubmittingReview,
            backgroundColor: _userRating > 0 ? AppColors.primary : AppColors.textSecondary,
          ),
        ],
      ),
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return 'Rất tệ';
      case 2:
        return 'Tệ';
      case 3:
        return 'Bình thường';
      case 4:
        return 'Tốt';
      case 5:
        return 'Tuyệt vời';
      default:
        return '';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return 'Hôm nay';
    } else if (difference == 1) {
      return 'Hôm qua';
    } else if (difference < 7) {
      return '$difference ngày trước';
    } else if (difference < 30) {
      final weeks = (difference / 7).floor();
      return '$weeks tuần trước';
    } else {
      final months = (difference / 30).floor();
      return '$months tháng trước';
    }
  }

  void _submitReview() async {
    if (_userRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn số sao đánh giá'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isSubmittingReview = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isSubmittingReview = false;
      });

      // Add new review to list (simulate successful submission)
      final newReview = Review(
        id: _reviews.length + 1,
        userId: 999, // Current user ID
        userName: 'Bạn',
        avatarUrl: '',
        rating: _userRating,
        comment: _commentController.text.trim(),
        createdAt: DateTime.now(),
        userInitial: 'B',
        userColor: AppColors.primary,
      );

      setState(() {
        _reviews.insert(0, newReview);
        _userRating = 0;
        _commentController.clear();
      });

      // Switch to reviews tab
      _tabController.animateTo(0);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đánh giá đã được gửi thành công!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }
}
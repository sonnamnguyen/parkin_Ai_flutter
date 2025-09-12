import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_themes.dart';
import '../../../data/models/parking_lot_model.dart';
import '../../../data/models/parking_review_model.dart';
import '../../../core/services/parking_review_service.dart';
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
  final ParkingReviewService _reviewService = ParkingReviewService();
  int _userRating = 0;
  bool _isSubmittingReview = false;
  bool _loading = false;
  String? _error;

  // Reviews data from API
  List<ParkingReview> _reviews = [];
  int _currentPage = 1;
  final int _pageSize = 10;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadReviews();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadReviews({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _reviews.clear();
        _hasMore = true;
      });
    }
    
    setState(() { _loading = true; _error = null; });
    
    try {
      print('=== LOADING REVIEWS ===');
      print('Lot ID: ${widget.parkingLot.id}');
      print('Page: $_currentPage');
      
      final response = await _reviewService.getReviews(
        lotId: widget.parkingLot.id,
        page: _currentPage,
        pageSize: _pageSize,
      );
      
      print('=== REVIEWS LOADED ===');
      print('Number of reviews: ${response.reviews.length}');
      print('Total: ${response.total}');
      
      setState(() {
        if (refresh) {
          _reviews = response.reviews;
        } else {
          _reviews.addAll(response.reviews);
        }
        _hasMore = _reviews.length < response.total;
        _currentPage++;
      });
    } catch (e) {
      print('=== ERROR LOADING REVIEWS ===');
      print('Error: $e');
      setState(() { _error = 'Không tải được đánh giá: $e'; });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  Future<void> _submitReview() async {
    if (_userRating == 0 || _commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn đánh giá và nhập bình luận'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() { _isSubmittingReview = true; });

    try {
      print('=== SUBMITTING REVIEW ===');
      
      final request = CreateReviewRequest(
        lotId: widget.parkingLot.id,
        rating: _userRating,
        comment: _commentController.text.trim(),
      );
      
      final review = await _reviewService.createReview(request);
      
      print('=== REVIEW SUBMITTED ===');
      print('Review ID: ${review.id}');
      
      // Clear form
      _commentController.clear();
      _userRating = 0;
      
      // Reload reviews
      _loadReviews(refresh: true);
      
      // Switch to reviews tab
      _tabController.animateTo(1);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đánh giá đã được gửi thành công'),
          backgroundColor: AppColors.success,
        ),
      );
      
    } catch (e) {
      print('=== ERROR SUBMITTING REVIEW ===');
      print('Error: $e');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi gửi đánh giá: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() { _isSubmittingReview = false; });
    }
  }

  Future<void> _deleteReview(int reviewId) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa đánh giá này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Không'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await _reviewService.deleteReview(reviewId);
                _loadReviews(refresh: true);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã xóa đánh giá')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lỗi khi xóa đánh giá: $e')),
                );
              }
            },
            child: const Text('Có'),
          ),
        ],
      ),
    );
  }

  Future<void> _editReview(ParkingReview review) async {
    final TextEditingController editController = TextEditingController(text: review.comment);
    int editRating = review.rating;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Chỉnh sửa đánh giá'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: List.generate(5, (i) => IconButton(
                splashRadius: 18,
                padding: EdgeInsets.zero,
                onPressed: () { editRating = i + 1; setState(() {}); },
                icon: Icon(i < editRating ? Icons.star : Icons.star_border, color: AppColors.warning),
              )),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: editController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Cập nhật bình luận'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Hủy')),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await _reviewService.updateReview(UpdateReviewRequest(
                  id: review.id,
                  lotId: review.lotId,
                  rating: editRating,
                  comment: editController.text.trim(),
                ));
                _loadReviews(refresh: true);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã cập nhật đánh giá')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lỗi khi cập nhật: $e')),
                );
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
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
    if (_loading && _reviews.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_error != null && _reviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadReviews(refresh: true),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }
    
    if (_reviews.isEmpty) {
      return const Center(
        child: Text('Chưa có đánh giá nào'),
      );
    }
    
    return RefreshIndicator(
      onRefresh: () => _loadReviews(refresh: true),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _reviews.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _reviews.length) {
            return _buildLoadMoreButton();
          }
          final review = _reviews[index];
          return _buildReviewCard(review);
        },
      ),
    );
  }

  Widget _buildLoadMoreButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _hasMore
              ? CustomButton(
                  text: 'Tải thêm',
                  onPressed: () => _loadReviews(),
                  width: double.infinity,
                )
              : const SizedBox(),
    );
  }

  Widget _buildReviewCard(ParkingReview review) {
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
                backgroundColor: _getUserColor(review.userId).withOpacity(0.2),
                child: Text(
                  review.username.isNotEmpty ? review.username[0].toUpperCase() : 'U',
                  style: AppThemes.bodyMedium.copyWith(
                    color: _getUserColor(review.userId),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.username,
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
                  const PopupMenuItem(value: 'edit', child: Text('Chỉnh sửa')),
                  const PopupMenuItem(value: 'delete', child: Text('Xóa')),
                ],
                onSelected: (value) {
                  if (value == 'edit') {
                    _editReview(review);
                  } else if (value == 'delete') {
                    _deleteReview(review.id);
                  }
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

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Không xác định';
    
    try {
      final date = DateTime.parse(dateString);
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
    } catch (e) {
      return dateString;
    }
  }

  Color _getUserColor(int userId) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];
    return colors[userId % colors.length];
  }

}
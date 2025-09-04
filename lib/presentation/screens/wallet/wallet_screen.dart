import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_themes.dart';
import '../../widgets/common/custom_button.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final double _balance = 125000.0;
  
  final List<Map<String, dynamic>> _transactions = [
    {
      'type': 'parking',
      'amount': -20000.0,
      'description': 'Bãi đậu xe Lê Văn Tám',
      'date': DateTime.now().subtract(const Duration(hours: 2)),
      'status': 'completed',
    },
    {
      'type': 'topup',
      'amount': 100000.0,
      'description': 'Nạp tiền từ thẻ Visa',
      'date': DateTime.now().subtract(const Duration(days: 1)),
      'status': 'completed',
    },
    {
      'type': 'parking',
      'amount': -15000.0,
      'description': 'Bãi đậu xe Bến Thành',
      'date': DateTime.now().subtract(const Duration(days: 2)),
      'status': 'completed',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Ví của tôi',
          style: AppThemes.headingMedium.copyWith(
            color: AppColors.darkGrey,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              // TODO: Navigate to transaction history
            },
            icon: const Icon(Icons.history, color: AppColors.darkGrey),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBalanceCard(),
            const SizedBox(height: 24),
            _buildQuickActions(),
            const SizedBox(height: 24),
            _buildRecentTransactions(),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.gradientStart, AppColors.gradientEnd],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Số dư hiện tại',
            style: AppThemes.bodyMedium.copyWith(
              color: AppColors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_balance.toInt().toString().replaceAllMapped(
              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
              (Match m) => '${m[1]},',
            )} VNĐ',
            style: AppThemes.headingLarge.copyWith(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.account_balance_wallet,
                      size: 16,
                      color: AppColors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'ParkIn Wallet',
                      style: AppThemes.bodySmall.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.visibility,
                color: AppColors.white,
                size: 20,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            icon: Icons.add,
            label: 'Nạp tiền',
            color: AppColors.success,
            onTap: () {
              // TODO: Navigate to top up
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildActionButton(
            icon: Icons.send,
            label: 'Chuyển tiền',
            color: AppColors.info,
            onTap: () {
              // TODO: Navigate to transfer
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppThemes.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Giao dịch gần đây',
              style: AppThemes.headingSmall.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                // TODO: Navigate to all transactions
              },
              child: Text(
                'Xem tất cả',
                style: AppThemes.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ..._transactions.map((transaction) => _buildTransactionItem(transaction)),
      ],
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> transaction) {
    final isIncome = transaction['amount'] > 0;
    final amount = transaction['amount'] as double;
    final description = transaction['description'] as String;
    final date = transaction['date'] as DateTime;
    final type = transaction['type'] as String;

    IconData getIcon() {
      switch (type) {
        case 'parking': return Icons.local_parking;
        case 'topup': return Icons.add_circle;
        default: return Icons.account_balance_wallet;
      }
    }

    Color getColor() {
      return isIncome ? AppColors.success : AppColors.error;
    }

    String formatDate(DateTime date) {
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays > 0) {
        return '${difference.inDays} ngày trước';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} giờ trước';
      } else {
        return '${difference.inMinutes} phút trước';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: getColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              getIcon(),
              color: getColor(),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: AppThemes.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formatDate(date),
                  style: AppThemes.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${isIncome ? '+' : ''}${amount.toInt().toString().replaceAllMapped(
              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
              (Match m) => '${m[1]},',
            )} VNĐ',
            style: AppThemes.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: getColor(),
            ),
          ),
        ],
      ),
    );
  }
}
             
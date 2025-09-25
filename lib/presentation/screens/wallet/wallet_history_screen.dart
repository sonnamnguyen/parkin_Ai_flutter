import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_themes.dart';
import '../../../core/services/wallet_service.dart';
import '../../../data/models/wallet_transaction_model.dart';

class WalletHistoryScreen extends StatefulWidget {
  const WalletHistoryScreen({super.key});

  @override
  State<WalletHistoryScreen> createState() => _WalletHistoryScreenState();
}

class _WalletHistoryScreenState extends State<WalletHistoryScreen> {
  final WalletService _walletService = WalletService();
  final ScrollController _scrollController = ScrollController();
  
  List<WalletTransaction> _transactions = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  bool _hasMoreData = true;
  String _selectedType = 'all';
  String _searchDescription = '';

  final List<String> _transactionTypes = [
    'all',
    'deposit',
    'withdrawal',
    'parking',
    'topup',
  ];

  final Map<String, String> _typeLabels = {
    'all': 'Tất cả',
    'deposit': 'Nạp tiền',
    'withdrawal': 'Rút tiền',
    'parking': 'Đậu xe',
    'topup': 'Nạp tiền',
  };

  @override
  void initState() {
    super.initState();
    _loadTransactions();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreTransactions();
    }
  }

  Future<void> _loadTransactions({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _isLoading = true;
        _currentPage = 1;
        _transactions.clear();
        _hasMoreData = true;
      });
    }

    try {
      final transactionResponse = await _walletService.getWalletTransactions(
        type: _selectedType == 'all' ? null : _selectedType,
        description: _searchDescription.isEmpty ? null : _searchDescription,
        page: _currentPage,
        pageSize: 20,
      );

      setState(() {
        if (refresh) {
          _transactions = transactionResponse.transactions;
        } else {
          _transactions.addAll(transactionResponse.transactions);
        }
        _hasMoreData = transactionResponse.hasNextPage;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải dữ liệu: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _loadMoreTransactions() async {
    if (_isLoadingMore || !_hasMoreData) return;

    setState(() {
      _isLoadingMore = true;
    });

    _currentPage++;
    await _loadTransactions();
  }

  void _onTypeChanged(String? type) {
    if (type != null && type != _selectedType) {
      setState(() {
        _selectedType = type;
      });
      _loadTransactions(refresh: true);
    }
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchDescription = value;
    });
    // Debounce search
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_searchDescription == value) {
        _loadTransactions(refresh: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.darkGrey),
        ),
        title: Text(
          'Lịch sử giao dịch',
          style: AppThemes.headingMedium.copyWith(
            color: AppColors.darkGrey,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => _loadTransactions(refresh: true),
            icon: const Icon(Icons.refresh, color: AppColors.darkGrey),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _transactions.isEmpty
                    ? _buildEmptyState()
                    : _buildTransactionList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.white,
      child: Column(
        children: [
          // Search bar
          TextField(
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Tìm kiếm theo mô tả...',
              prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Type filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _transactionTypes.map((type) {
                final isSelected = _selectedType == type;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(_typeLabels[type] ?? type),
                    selected: isSelected,
                    onSelected: (selected) => _onTypeChanged(type),
                    selectedColor: AppColors.primary.withOpacity(0.2),
                    checkmarkColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long,
            size: 64,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Không có giao dịch nào',
            style: AppThemes.headingSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Các giao dịch của bạn sẽ hiển thị ở đây',
            style: AppThemes.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList() {
    return RefreshIndicator(
      onRefresh: () => _loadTransactions(refresh: true),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _transactions.length + (_hasMoreData ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _transactions.length) {
            return _buildLoadingMore();
          }
          return _buildTransactionItem(_transactions[index]);
        },
      ),
    );
  }

  Widget _buildLoadingMore() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: _isLoadingMore
            ? const CircularProgressIndicator()
            : TextButton(
                onPressed: _loadMoreTransactions,
                child: const Text('Tải thêm'),
              ),
      ),
    );
  }

  Widget _buildTransactionItem(WalletTransaction transaction) {
    final isIncome = transaction.isIncome;
    final amount = transaction.amount;
    final description = transaction.description;
    final date = transaction.createdAt;
    final type = transaction.type;

    IconData getIcon() {
      switch (type) {
        case 'parking': return Icons.local_parking;
        case 'topup':
        case 'deposit': return Icons.add_circle;
        case 'withdrawal': return Icons.remove_circle;
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
                Row(
                  children: [
                    Text(
                      formatDate(date),
                      style: AppThemes.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        type.toUpperCase(),
                        style: AppThemes.bodySmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
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
              const SizedBox(height: 2),
              Text(
                transaction.status.toUpperCase(),
                style: AppThemes.bodySmall.copyWith(
                  color: transaction.status == 'completed' 
                      ? AppColors.success 
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

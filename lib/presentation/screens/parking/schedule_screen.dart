import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_themes.dart';
import '../../widgets/common/custom_button.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  DateTime selectedDate = DateTime.now();
  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;

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
          'Chi tiết đơn đặt chỗ',
          style: AppThemes.headingMedium.copyWith(
            color: AppColors.darkGrey,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        margin: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _buildCalendar(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomActionBar(),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.gradientStart, AppColors.gradientEnd],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Text(
            'LỊCH ĐẶT CHỖ',
            style: AppThemes.bodyMedium.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tháng ${selectedMonth} năm ${selectedYear}',
            style: AppThemes.headingSmall.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildWeekDaysHeader(),
          const SizedBox(height: 16),
          Expanded(
            child: _buildCalendarGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekDaysHeader() {
    final weekDays = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];
    
    return Row(
      children: weekDays.map((day) {
        return Expanded(
          child: Center(
            child: Text(
              day,
              style: AppThemes.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(selectedYear, selectedMonth, 1);
    final lastDayOfMonth = DateTime(selectedYear, selectedMonth + 1, 0);
    final firstWeekday = firstDayOfMonth.weekday % 7;
    final daysInMonth = lastDayOfMonth.day;

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: firstWeekday + daysInMonth,
      itemBuilder: (context, index) {
        if (index < firstWeekday) {
          return const SizedBox(); // Empty cells for days before month starts
        }
        
        final day = index - firstWeekday + 1;
        final date = DateTime(selectedYear, selectedMonth, day);
        final isToday = _isSameDay(date, DateTime.now());
        final isSelected = _isSameDay(date, selectedDate);
        final isPast = date.isBefore(DateTime.now().subtract(const Duration(days: 1)));
        
        return _buildCalendarDay(day, isToday, isSelected, isPast, date);
      },
    );
  }

  Widget _buildCalendarDay(int day, bool isToday, bool isSelected, bool isPast, DateTime date) {
    Color? backgroundColor;
    Color? textColor = AppColors.darkGrey;
    
    if (isPast) {
      textColor = AppColors.textSecondary.withOpacity(0.5);
    } else if (isSelected) {
      backgroundColor = AppColors.primary;
      textColor = AppColors.white;
    } else if (isToday) {
      backgroundColor = AppColors.primary.withOpacity(0.1);
      textColor = AppColors.primary;
    }

    return GestureDetector(
      onTap: isPast ? null : () => _selectDate(date),
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            day.toString(),
            style: AppThemes.bodyMedium.copyWith(
              color: textColor,
              fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: CustomButton(
          text: 'Xác nhận ngày',
          onPressed: () => _confirmDate(),
          width: double.infinity,
        ),
      ),
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  void _selectDate(DateTime date) {
    setState(() {
      selectedDate = date;
    });
  }

  void _confirmDate() {
    Navigator.of(context).pop(selectedDate);
  }
}

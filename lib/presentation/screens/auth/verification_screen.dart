import 'package:flutter/material.dart';
import 'dart:async';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_themes.dart';
import '../../widgets/common/custom_button.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(4, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (index) => FocusNode());
  
  bool _isLoading = false;
  int _countdown = 60;
  Timer? _timer;
  String? _phoneNumber;
  String? _fromScreen;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get arguments passed from previous screen
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    _phoneNumber = args?['phone'] ?? '+849876544321';
    _fromScreen = args?['from'] ?? 'register';
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() {
      _countdown = 60;
    });
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() {
          _countdown--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  String get _maskedPhoneNumber {
    if (_phoneNumber == null || _phoneNumber!.length < 4) return _phoneNumber ?? '';
    return '${_phoneNumber!.substring(0, _phoneNumber!.length - 4)}${'*' * 4}';
  }

  void _onCodeChanged(String value, int index) {
    if (value.isNotEmpty) {
      if (index < 3) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        _verifyCode();
      }
    }
  }

  void _onCodeDeleted(int index) {
    if (index > 0) {
      _controllers[index - 1].clear();
      _focusNodes[index - 1].requestFocus();
    }
  }

  String get _verificationCode {
    return _controllers.map((controller) => controller.text).join();
  }

  Future<void> _verifyCode() async {
    final code = _verificationCode;
    if (code.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập đầy đủ mã xác nhận'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Implement actual verification logic
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call
      
      if (mounted) {
        // Show success screen
        Navigator.of(context).pushNamed('/verification-success');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Xác thực thất bại: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resendCode() async {
    try {
      // TODO: Implement resend code logic
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call
      
      _startCountdown();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã gửi lại mã xác nhận'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gửi lại mã thất bại: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_ios),
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
              ),

              const SizedBox(height: 20),

              // Header with geometric design
              Expanded(
                flex: 2,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.gradientStart, AppColors.gradientEnd],
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Stack(
                    children: [
                      // Geometric circles
                      Positioned(
                        top: 20,
                        right: 30,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.white.withOpacity(0.1),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 30,
                        left: -20,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.white.withOpacity(0.05),
                          ),
                        ),
                      ),
                      
                      // Content
                      Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.verificationCode,
                              style: AppThemes.headingLarge.copyWith(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Vui lòng nhập mã xác nhận được gửi đến số điện thoại của bạn ${_maskedPhoneNumber}',
                              style: AppThemes.bodyLarge.copyWith(
                                color: AppColors.white.withOpacity(0.9),
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Verification Code Input
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    Text(
                      'Verification Code',
                      style: AppThemes.bodyMedium.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    
                    const SizedBox(height: 24),

                    // Code Input Fields
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(4, (index) {
                        return SizedBox(
                          width: 60,
                          height: 60,
                          child: TextFormField(
                            controller: _controllers[index],
                            focusNode: _focusNodes[index],
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            maxLength: 1,
                            style: AppThemes.headingMedium.copyWith(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              counterText: '',
                              filled: true,
                              fillColor: AppColors.lightGrey,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: const BorderSide(
                                  color: AppColors.primary, 
                                  width: 2,
                                ),
                              ),
                            ),
                            onChanged: (value) => _onCodeChanged(value, index),
                            onTap: () {
                              _controllers[index].selection = TextSelection.fromPosition(
                                TextPosition(offset: _controllers[index].text.length),
                              );
                            },
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 32),

                    // Resend Code
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Không nhận được mã? ',
                          style: AppThemes.bodyMedium,
                        ),
                        if (_countdown > 0)
                          Text(
                            'Gửi lại sau ${_countdown}s',
                            style: AppThemes.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          )
                        else
                          TextButton(
                            onPressed: _resendCode,
                            child: Text(
                              'Gửi lại',
                              style: AppThemes.bodyMedium.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),

                    const Spacer(),

                    // Verify Button
                    CustomButton(
                      text: 'Xác nhận ngay',
                      onPressed: _isLoading ? null : _verifyCode,
                      isLoading: _isLoading,
                      width: double.infinity,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
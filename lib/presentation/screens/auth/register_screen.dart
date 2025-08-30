import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_themes.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/custom_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  bool _agreeToTerms = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
    });
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đồng ý với điều khoản và điều kiện'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Implement actual registration logic
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call
      
      if (mounted) {
        // Navigate to verification screen
        Navigator.of(context).pushNamed(
          '/verification',
          arguments: {
            'phone': _phoneController.text,
            'from': 'register',
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đăng ký thất bại: ${e.toString()}'),
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

  void _navigateToLogin() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
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

              // App Logo
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.gradientStart, AppColors.gradientEnd],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.local_parking,
                        color: AppColors.white,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppStrings.appName,
                      style: AppThemes.headingMedium,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Title
              Text(
                AppStrings.register,
                style: AppThemes.headingMedium.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Tạo tài khoản mới để sử dụng dịch vụ',
                style: AppThemes.bodyMedium,
              ),

              const SizedBox(height: 32),

              // Registration Form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Full Name Field
                    CustomTextField(
                      controller: _fullNameController,
                      label: AppStrings.fullName,
                      hintText: 'Nguyễn Văn A',
                      prefixIcon: Icons.person_outlined,
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Vui lòng nhập họ tên';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // Username Field
                    CustomTextField(
                      controller: _usernameController,
                      label: AppStrings.username,
                      hintText: 'nguyenvana',
                      prefixIcon: Icons.alternate_email_outlined,
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Vui lòng nhập tên đăng nhập';
                        }
                        if (value!.length < 3) {
                          return 'Tên đăng nhập phải có ít nhất 3 ký tự';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // Email Field
                    CustomTextField(
                      controller: _emailController,
                      label: AppStrings.email,
                      hintText: 'example@gmail.com',
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: Icons.email_outlined,
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Vui lòng nhập email';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
                          return 'Email không hợp lệ';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // Phone Field
                    CustomTextField(
                      controller: _phoneController,
                      label: AppStrings.phone,
                      hintText: '+849876544321',
                      keyboardType: TextInputType.phone,
                      prefixIcon: Icons.phone_outlined,
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Vui lòng nhập số điện thoại';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // Password Field
                    CustomTextField(
                      controller: _passwordController,
                      label: AppStrings.password,
                      hintText: '●●●●●●●●●●●●',
                      obscureText: !_isPasswordVisible,
                      prefixIcon: Icons.lock_outlined,
                      suffixIcon: IconButton(
                        onPressed: _togglePasswordVisibility,
                        icon: Icon(
                          _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Vui lòng nhập mật khẩu';
                        }
                        if (value!.length < 6) {
                          return 'Mật khẩu phải có ít nhất 6 ký tự';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // Confirm Password Field
                    CustomTextField(
                      controller: _confirmPasswordController,
                      label: AppStrings.confirmPassword,
                      hintText: '●●●●●●●●●●●●',
                      obscureText: !_isConfirmPasswordVisible,
                      prefixIcon: Icons.lock_outlined,
                      suffixIcon: IconButton(
                        onPressed: _toggleConfirmPasswordVisibility,
                        icon: Icon(
                          _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Vui lòng nhập lại mật khẩu';
                        }
                        if (value != _passwordController.text) {
                          return 'Mật khẩu không khớp';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // Terms and Conditions Checkbox
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: _agreeToTerms,
                          onChanged: (value) {
                            setState(() {
                              _agreeToTerms = value ?? false;
                            });
                          },
                          activeColor: AppColors.primary,
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: RichText(
                              text: TextSpan(
                                style: AppThemes.bodyMedium,
                                children: [
                                  const TextSpan(text: 'Tôi đồng ý với các '),
                                  TextSpan(
                                    text: 'điều khoản và điều kiện',
                                    style: AppThemes.bodyMedium.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Register Button
                    CustomButton(
                      text: AppStrings.createAccount,
                      onPressed: _isLoading ? null : _register,
                      isLoading: _isLoading,
                      width: double.infinity,
                    ),

                    const SizedBox(height: 24),

                    // Login Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Đã có tài khoản? ',
                          style: AppThemes.bodyMedium,
                        ),
                        TextButton(
                          onPressed: _navigateToLogin,
                          child: Text(
                            AppStrings.login,
                            style: AppThemes.bodyMedium.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
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
class RegisterRequest {
  final String username;
  final String email;
  final String password;
  final String phone;
  final String fullName;
  final String gender;
  final String birthDate;

  RegisterRequest({
    required this.username,
    required this.email,
    required this.password,
    required this.phone,
    required this.fullName,
    required this.gender,
    required this.birthDate,
  });

  Map<String, dynamic> toJson() => {
    'username': username,
    'email': email,
    'password': password,
    'phone': phone,
    'full_name': fullName,
    'gender': gender,
    'birth_date': birthDate,
  };
}

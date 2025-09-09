class LoginRequest {
  final String account;
  final String password;

  LoginRequest({
    required this.account,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
    'account': account,
    'password': password,
  };
}

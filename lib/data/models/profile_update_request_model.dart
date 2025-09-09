class ProfileUpdateRequest {
  final String? fullName;
  final String? email;
  final String? phone;
  final String? gender;
  final String? birthDate;
  final String? avatarUrl;

  ProfileUpdateRequest({
    this.fullName,
    this.email,
    this.phone,
    this.gender,
    this.birthDate,
    this.avatarUrl,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    
    if (fullName != null) data['full_name'] = fullName;
    if (email != null) data['email'] = email;
    if (phone != null) data['phone'] = phone;
    if (gender != null) data['gender'] = gender;
    if (birthDate != null) data['birth_date'] = birthDate;
    if (avatarUrl != null) data['avatar_url'] = avatarUrl;
    
    return data;
  }

  @override
  String toString() => 'ProfileUpdateRequest(fullName: $fullName, email: $email, phone: $phone)';
}

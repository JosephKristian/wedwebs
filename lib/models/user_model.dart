class User {
  final int? user_id;
  final String name;
  final String email;
  final String password;
  final String? emailVerifiedAt;
  final String role;
  final String? rememberToken;
  final String? createdAt;
  final String? updatedAt;

  User({
    this.user_id,
    required this.name,
    required this.email,
    required this.password,
    this.emailVerifiedAt,
    this.role = 'user',
    this.rememberToken,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'user_id': user_id,
      'name': name,
      'email': email,
      'password': password,
      'email_verified_at': emailVerifiedAt,
      'role': role,
      'remember_token': rememberToken,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      user_id: map['user_id'],
      name: map['name'],
      email: map['email'],
      password: map['password'],
      emailVerifiedAt: map['email_verified_at'],
      role: map['role'],
      rememberToken: map['remember_token'],
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
    );
  }
}

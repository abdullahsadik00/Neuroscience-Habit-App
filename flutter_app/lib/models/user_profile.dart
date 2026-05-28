class UserProfile {
  final String name;
  final String role;

  const UserProfile({required this.name, required this.role});

  static const UserProfile empty = UserProfile(name: '', role: '');

  UserProfile copyWith({String? name, String? role}) =>
      UserProfile(name: name ?? this.name, role: role ?? this.role);

  Map<String, dynamic> toJson() => {'name': name, 'role': role};

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      UserProfile(name: json['name'] as String, role: json['role'] as String);
}

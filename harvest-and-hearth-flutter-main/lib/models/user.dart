class AppUser {
  final String id;
  final String email;
  final String name;
  final String? avatarUrl;

  const AppUser({
    required this.id,
    required this.email,
    required this.name,
    this.avatarUrl,
  });

  AppUser copyWith({String? id, String? email, String? name, String? avatarUrl}) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'avatarUrl': avatarUrl,
      };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        email: json['email'] as String,
        name: json['name'] as String,
        avatarUrl: json['avatarUrl'] as String?,
      );
}

class User {
  final String id;
  final String name;
  final String designation;
  final String? center;

  User({
    required this.id,
    required this.name,
    required this.designation,
    this.center,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['user_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      designation: json['designation'] ?? '',
      center: json['center'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': id,
      'name': name,
      'designation': designation,
      'center': center,
    };
  }
}
class UserModel {
  static const admin = "admin";
  static const mechanic = "mechanic";
  static const user = "user";

  final String uid;
  final String name;
  final String phone;
  final String role;

  UserModel({
    required this.uid,
    required this.name,
    required this.phone,
    required this.role,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'phone': phone,
      'role': role,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      role: map['role'] ?? '',
    );
  }
}

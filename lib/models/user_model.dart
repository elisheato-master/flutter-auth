// lib/models/user_model.dart
class UserModel {
  final String id;
  final String email;
  final String? displayName;

  UserModel({
    required this.id,
    required this.email,
    this.displayName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      email: map['email'],
      displayName: map['displayName'],
    );
  }
}

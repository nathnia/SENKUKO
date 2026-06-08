class UserModel {
  final String id;
  final String code;
  final String name;
  final String? phone;
  final String? email;
  final String memberType;

  UserModel({
    required this.id,
    required this.code,
    required this.name,
    this.phone,
    this.email,
    required this.memberType,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json["id"] ?? "",
      code: json["code"] ?? "",
      name: json["name"] ?? "",
      phone: json["phone"],
      email: json["email"],
      memberType: json["member_type"] ?? "",
    );
  }
}
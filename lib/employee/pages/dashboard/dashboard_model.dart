// dashboard_model.dart
class User {
  final String id;
  final String name;
  final String email;
  final String username;
  final String mobile;
  final String image;
  final String type;
  final String address;
  final String status;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.username,
    required this.mobile,
    required this.image,
    required this.type,
    required this.address,
    required this.status,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      username: json['username'],
      mobile: json['mobile'].toString(),
      image: json['image'],
      type: json['type'],
      address: json['address'],
      status: json['status'],
    );
  }
}

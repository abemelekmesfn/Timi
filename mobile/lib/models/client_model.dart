class ClientModel {
  final String id;
  final String firstName;
  final String lastName;

  ClientModel({
    required this.id,
    required this.firstName,
    required this.lastName,
  });

  factory ClientModel.fromJson(Map<String, dynamic> json) {
    return ClientModel(
      id: json["id"],
      firstName: json["first_name"],
      lastName: json["last_name"] ?? "",
    );
  }

  String get fullName => "$firstName ${lastName.trim()}".trim();
}

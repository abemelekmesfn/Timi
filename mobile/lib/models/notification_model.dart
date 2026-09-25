class NotificationModel {
  final String id;
  final String messageEn;
  final String messageAm;
  final bool isRead;
  final String createdAt;

  NotificationModel({
    required this.id,
    required this.messageEn,
    required this.messageAm,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json["id"],
      messageEn: json["message_en"],
      messageAm: json["message_am"],
      isRead: json["is_read"],
      createdAt: json["created_at"],
    );
  }
}

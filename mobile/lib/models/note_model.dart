class NoteModel {
  final String id;
  final String title;
  final String content;
  final bool pinned;
  final String createdBy;
  final String updatedAt;

  NoteModel({
    required this.id,
    required this.title,
    required this.content,
    required this.pinned,
    required this.createdBy,
    required this.updatedAt,
  });

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    return NoteModel(
      id: json["id"],
      title: json["title"] ?? "",
      content: json["content"],
      pinned: json["pinned"],
      createdBy: json["created_by_name"] ?? "",
      updatedAt: json["updated_at"],
    );
  }

  Map<String, dynamic> toJson() => {
    "title": title,
    "content": content,
    "pinned": pinned,
  };
}

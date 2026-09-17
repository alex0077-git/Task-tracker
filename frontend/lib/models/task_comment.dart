class TaskComment {
  const TaskComment({
    required this.id,
    required this.body,
    required this.authorName,
    required this.createdAt,
  });

  final int id;
  final String body;
  final String authorName;
  final DateTime createdAt;

  factory TaskComment.fromJson(Map<String, dynamic> json) {
    return TaskComment(
      id: json['id'] as int,
      body: json['body'] as String,
      authorName: json['author_name'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

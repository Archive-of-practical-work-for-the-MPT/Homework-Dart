class Post {
  final String id;
  final String title;
  final String content;
  final String authorEmail;
  final DateTime createdAt;

  Post({
    required this.id,
    required this.title,
    required this.content,
    required this.authorEmail,
    required this.createdAt,
  });

  // Преобразовать экземпляр Post в Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'authorEmail': authorEmail,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  // Создать экземпляр Post из Map
  factory Post.fromMap(Map<String, dynamic> map) {
    return Post(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      authorEmail: map['authorEmail'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
    );
  }
}
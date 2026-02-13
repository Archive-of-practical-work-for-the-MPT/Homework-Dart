import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/post_model.dart';

class PostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Ссылка на коллекцию постов
  CollectionReference get _postsCollection => _firestore.collection('posts');

  // Добавить новый пост
  Future<void> addPost(String title, String content, String authorEmail) async {
    try {
      String id = const Uuid().v4(); // Генерировать уникальный ID
      await _postsCollection.doc(id).set({
        'id': id,
        'title': title,
        'content': content,
        'authorEmail': authorEmail,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Ошибка при добавлении поста: $e');
    }
  }

  // Обновить существующий пост
  Future<void> updatePost(String id, String title, String content) async {
    try {
      await _postsCollection.doc(id).update({
        'title': title,
        'content': content,
      });
    } catch (e) {
      print('Ошибка при обновлении поста: $e');
    }
  }

  // Удалить пост
  Future<void> deletePost(String id) async {
    try {
      await _postsCollection.doc(id).delete();
    } catch (e) {
      print('Ошибка при удалении поста: $e');
    }
  }

  // Получить поток всех постов
  Stream<List<Post>> getPostsStream() {
    return _postsCollection.orderBy('createdAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        // Обработка преобразования серверного времени
        Timestamp timestamp = data['createdAt'] as Timestamp;
        return Post(
          id: data['id'],
          title: data['title'],
          content: data['content'],
          authorEmail: data['authorEmail'],
          createdAt: timestamp.toDate(),
        );
      }).toList();
    });
  }

  // Получить конкретный пост по ID
  Future<Post?> getPostById(String id) async {
    try {
      DocumentSnapshot doc = await _postsCollection.doc(id).get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        Timestamp timestamp = data['createdAt'] as Timestamp;
        return Post(
          id: data['id'],
          title: data['title'],
          content: data['content'],
          authorEmail: data['authorEmail'],
          createdAt: timestamp.toDate(),
        );
      }
      return null;
    } catch (e) {
      print('Ошибка получения поста: $e');
      return null;
    }
  }
}
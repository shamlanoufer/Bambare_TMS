import 'package:cloud_firestore/cloud_firestore.dart';

class MemoryItem {
  const MemoryItem({
    required this.id,
    required this.imageUrl,
    required this.title,
    required this.story,
    required this.createdAt,
  });

  final String id;
  final String imageUrl; // storage url or data:image/... (web fallback)
  final String title;
  final String story;
  final Timestamp? createdAt;

  static MemoryItem fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final m = doc.data() ?? const <String, dynamic>{};
    return MemoryItem(
      id: doc.id,
      imageUrl: (m['image_url'] ?? '').toString(),
      title: (m['title'] ?? '').toString(),
      story: (m['story'] ?? '').toString(),
      createdAt: m['created_at'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'image_url': imageUrl,
      'title': title,
      'story': story,
    };
  }
}


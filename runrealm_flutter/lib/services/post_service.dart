import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/social.dart';
import 'firebase_service.dart';

class PostService {
  static Stream<List<Post>> subscribeGlobalFeed() {
    return FirebaseService.db
        .collection('posts')
        .where('visibility', isEqualTo: 'global')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Post.fromMap(doc.data(), doc.id)).toList());
  }

  static Stream<List<Post>> subscribeFriendsFeed(List<String> followingUids) {
    if (followingUids.isEmpty) return Stream.value([]);
    
    // Firestore 'whereIn' is limited to 10 items.
    // For MVP, we'll just take the first 10. In production, we'd need client-side merging or multiple queries.
    final limitedUids = followingUids.take(10).toList();

    return FirebaseService.db
        .collection('posts')
        .where('visibility', isEqualTo: 'friends')
        .where('authorUid', whereIn: limitedUids)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Post.fromMap(doc.data(), doc.id)).toList());
  }

  static Stream<List<Post>> subscribeMultiClubFeed(List<String> clubIds) {
    if (clubIds.isEmpty) return Stream.value([]);
    
    final limitedClubIds = clubIds.take(10).toList();

    return FirebaseService.db
        .collection('posts')
        .where('visibility', isEqualTo: 'club')
        .where('clubId', whereIn: limitedClubIds)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Post.fromMap(doc.data(), doc.id)).toList());
  }

  static Future<void> createPost(Post post) async {
    await FirebaseService.db.collection('posts').add(post.toMap());
  }
}

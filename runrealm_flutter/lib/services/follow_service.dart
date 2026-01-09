import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_service.dart';

class FollowService {
  static Stream<List<String>> subscribeFollowers(String uid) {
    return FirebaseService.db
        .collection('follows')
        .where('followingUid', isEqualTo: uid)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .where((doc) => doc.data()['status'] == 'accepted' || doc.data()['status'] == null) // Backward compatibility
            .map((doc) => doc.data()['followerUid'] as String)
            .toList());
  }

  static Stream<List<String>> subscribeFollowing(String uid) {
    return FirebaseService.db
        .collection('follows')
        .where('followerUid', isEqualTo: uid)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .where((doc) => doc.data()['status'] == 'accepted' || doc.data()['status'] == null)
            .map((doc) => doc.data()['followingUid'] as String)
            .toList());
  }

  static Future<void> followUser(String followerUid, String followingUid) async {
    await FirebaseService.db.collection('follows').add({
      'followerUid': followerUid,
      'followingUid': followingUid,
      'createdAt': Timestamp.now(),
      'status': 'pending', // Default to pending
    });
  }

  static Future<void> unfollowUser(String followerUid, String followingUid) async {
    final query = await FirebaseService.db
        .collection('follows')
        .where('followerUid', isEqualTo: followerUid)
        .where('followingUid', isEqualTo: followingUid)
        .get();
    for (var doc in query.docs) {
      await doc.reference.delete();
    }
  }

  // Returns 'none', 'pending', or 'accepted'
  static Future<String> checkFollowStatus(String followerUid, String followingUid) async {
    final query = await FirebaseService.db
        .collection('follows')
        .where('followerUid', isEqualTo: followerUid)
        .where('followingUid', isEqualTo: followingUid)
        .limit(1)
        .get();
    
    if (query.docs.isEmpty) return 'none';
    
    final data = query.docs.first.data();
    return data['status'] ?? 'accepted'; // Default to accepted for old records
  }

  static Stream<List<Map<String, dynamic>>> subscribePendingRequests(String uid) {
    return FirebaseService.db
        .collection('follows')
        .where('followingUid', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => {
              'id': doc.id,
              ...doc.data(),
            }).toList());
  }

  static Future<void> acceptRequest(String docId) async {
    await FirebaseService.db.collection('follows').doc(docId).update({
      'status': 'accepted',
    });
  }

  static Future<void> declineRequest(String docId) async {
    await FirebaseService.db.collection('follows').doc(docId).delete();
  }
}

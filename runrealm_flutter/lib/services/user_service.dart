import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/social.dart';
import 'firebase_service.dart';

class UserService {
  static Future<UserProfile?> getUserProfile(String uid) async {
    final doc = await FirebaseService.db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserProfile.fromMap(doc.data()!, uid);
  }

  static Future<void> createUserProfile(String uid) async {
    final profile = UserProfile(
      uid: uid,
      displayName: 'User-${uid.substring(0, 5)}',
      setupComplete: false,
      createdAt: Timestamp.now(),
      totalDistanceKm: 0,
      totalRuns: 0,
      clubsJoined: [],
    );
    await FirebaseService.db.collection('users').doc(uid).set(profile.toMap());
  }

  static Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    await FirebaseService.db.collection('users').doc(uid).update(data);
  }

  static Stream<UserProfile?> subscribeUserProfile(String uid) {
    return FirebaseService.db.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserProfile.fromMap(doc.data()!, uid);
    });
  }
  static Future<void> addClubToProfile(String uid, String clubId) async {
    await FirebaseService.db.collection('users').doc(uid).update({
      'clubsJoined': FieldValue.arrayUnion([clubId]),
    });
  }
  static Future<List<UserProfile>> getMembersOfClub(String clubId) async {
    final snapshot = await FirebaseService.db
        .collection('users')
        .where('clubsJoined', arrayContains: clubId)
        .get();
    
    return snapshot.docs.map((doc) => UserProfile.fromMap(doc.data(), doc.id)).toList();
  }

  static Future<void> removeClubFromProfile(String uid, String clubId) async {
    await FirebaseService.db.collection('users').doc(uid).update({
      'clubsJoined': FieldValue.arrayRemove([clubId]),
    });
  }

  static Future<List<UserProfile>> searchUsers(String query) async {
    if (query.isEmpty) return [];

    // Simple prefix search on displayName
    // Note: This is case-sensitive and requires a specific index in Firestore for complex queries.
    // For a production app, consider using Algolia or a dedicated search service.
    // Here we use the standard Firestore range query for prefix matching.
    
    final snapshot = await FirebaseService.db
        .collection('users')
        .where('displayName', isGreaterThanOrEqualTo: query)
        .where('displayName', isLessThan: query + 'z')
        .limit(20)
        .get();

    return snapshot.docs
        .map((doc) => UserProfile.fromMap(doc.data(), doc.id))
        .toList();
  }

  static Future<List<UserProfile>> getUsers(List<String> uids) async {
    if (uids.isEmpty) return [];

    // Firestore whereIn is limited to 10 items. We need to chunk the requests.
    List<UserProfile> profiles = [];
    for (var i = 0; i < uids.length; i += 10) {
      final end = (i + 10 < uids.length) ? i + 10 : uids.length;
      final chunk = uids.sublist(i, end);

      final snapshot = await FirebaseService.db
          .collection('users')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();

      profiles.addAll(
          snapshot.docs.map((doc) => UserProfile.fromMap(doc.data(), doc.id)));
    }
    return profiles;
  }
}

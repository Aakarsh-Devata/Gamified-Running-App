import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/social.dart';
import 'firebase_service.dart';
import 'user_service.dart';

class ClubService {
  static Future<List<Club>> getAllClubs() async {
    try {
      final snapshot = await FirebaseService.db.collection('clubs').get();
      return snapshot.docs.map((doc) {
        try {
          return Club.fromMap(doc.data(), doc.id);
        } catch (e) {
          print('Error parsing club ${doc.id}: $e');
          return null;
        }
      }).whereType<Club>().toList();
    } catch (e) {
      print('Error fetching clubs: $e');
      return [];
    }
  }

  static Future<Club?> getClub(String clubId) async {
    final doc = await FirebaseService.db.collection('clubs').doc(clubId).get();
    if (!doc.exists) return null;
    return Club.fromMap(doc.data()!, doc.id);
  }
  static Future<String> createClub(Club club) async {
    final docRef = await FirebaseService.db.collection('clubs').add(club.toMap());
    return docRef.id;
  }

  static Future<void> joinClub(String clubId, String userId) async {
    // 1. Add club to user's profile
    await UserService.addClubToProfile(userId, clubId);

    // 2. Increment member count in club
    await FirebaseService.db.collection('clubs').doc(clubId).update({
      'memberCount': FieldValue.increment(1),
    });
  }

  static Future<void> leaveClub(String clubId, String userId) async {
    // 1. Remove club from user's profile
    await UserService.removeClubFromProfile(userId, clubId);

    // 2. Decrement member count in club
    await FirebaseService.db.collection('clubs').doc(clubId).update({
      'memberCount': FieldValue.increment(-1),
    });
  }
}

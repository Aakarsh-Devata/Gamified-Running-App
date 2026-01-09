import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/social.dart';
import 'firebase_service.dart';

class RunService {
  static Future<String?> saveRun(Run run) async {
    final docRef = await FirebaseService.db.collection('runs').add(run.toMap());
    return docRef.id;
  }

  static Stream<List<Run>> subscribeUserRuns(String uid) {
    return FirebaseService.db
        .collection('runs')
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Run.fromMap(doc.data(), doc.id)).toList());
  }

  static Future<Run?> getRun(String runId) async {
    final doc = await FirebaseService.db.collection('runs').doc(runId).get();
    if (!doc.exists) return null;
    return Run.fromMap(doc.data()!, doc.id);
  }

  static Future<void> updateUserStats(String uid, double distanceKm) async {
    final userRef = FirebaseService.db.collection('users').doc(uid);
    final doc = await userRef.get();
    if (doc.exists) {
      final data = doc.data()!;
      final currentDistance = (data['totalDistanceKm'] as num?)?.toDouble() ?? 0;
      final currentRuns = data['totalRuns'] as int? ?? 0;
      await userRef.update({
        'totalDistanceKm': currentDistance + distanceKm,
        'totalRuns': currentRuns + 1,
      });
    }
  }
}

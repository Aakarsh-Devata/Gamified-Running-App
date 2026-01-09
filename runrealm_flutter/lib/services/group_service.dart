import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GroupService {
  static final _db = FirebaseFirestore.instance;

  // Create a new group
  static Future<String?> createGroup(String name, List<String> memberIds) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      // Add self to members if not present
      final members = List<String>.from(memberIds);
      if (!members.contains(user.uid)) {
        members.add(user.uid);
      }

      final docRef = await _db.collection('groups').add({
        'name': name,
        'members': members,
        'admin': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'memberCount': members.length,
      });

      return docRef.id;
    } catch (e) {
      print('Error creating group: $e');
      return null;
    }
  }

  // Fetch groups for current user
  static Stream<List<Map<String, dynamic>>> getUserGroups() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value([]);

    return _db
        .collection('groups')
        .where('members', arrayContains: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => {
              'id': doc.id,
              ...doc.data(),
            }).toList());
  }

  // Add member to group
  static Future<void> addMembers(String groupId, List<String> newMemberIds) async {
    await _db.collection('groups').doc(groupId).update({
      'members': FieldValue.arrayUnion(newMemberIds),
      // 'memberCount': FieldValue.increment(newMemberIds.length) // Requires careful handling
    });
  }
}

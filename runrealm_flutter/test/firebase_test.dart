import 'package:flutter_test/flutter_test.dart';
import 'package:runrealm_flutter/services/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await FirebaseService.initialize();
  });

  test('Firebase initialization', () {
    expect(FirebaseService.auth, isNotNull);
    expect(FirebaseService.db, isNotNull);
  });

  test('Add and retrieve data from Firestore', () async {
    // Add a test document
    final testData = {'testField': 'testValue', 'timestamp': DateTime.now()};
    final docRef = await FirebaseService.db.collection('testCollection').add(testData);

    // Retrieve the document
    final docSnapshot = await docRef.get();
    expect(docSnapshot.exists, true);
    expect(docSnapshot.data()!['testField'], 'testValue');

    // Clean up
    await docRef.delete();
  });
}

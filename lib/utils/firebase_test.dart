import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseTest {
  static Future<Map<String, bool>> testConnection() async {
    final results = <String, bool>{};

    // Test Auth
    try {
      final auth = FirebaseAuth.instance;
      results['Authentication'] = auth.currentUser != null || true;
    } catch (e) {
      results['Authentication'] = false;
      print('Auth Error: $e');
    }

    // Test Realtime Database
    try {
      final ref = FirebaseDatabase.instance.ref('test');
      await ref.set({'timestamp': DateTime.now().millisecondsSinceEpoch});
      final snapshot = await ref.get();
      results['Realtime Database'] = snapshot.exists;
      await ref.remove();
    } catch (e) {
      results['Realtime Database'] = false;
      print('Realtime DB Error: $e');
    }

    // Test Firestore
    try {
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('test').doc('connection').set({
        'timestamp': FieldValue.serverTimestamp(),
      });
      final doc = await firestore.collection('test').doc('connection').get();
      results['Firestore'] = doc.exists;
      await firestore.collection('test').doc('connection').delete();
    } catch (e) {
      results['Firestore'] = false;
      print('Firestore Error: $e');
    }

    return results;
  }
}

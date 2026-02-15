import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UsageRepository {
  final FirebaseFirestore _firestore;

  UsageRepository(this._firestore);

  Future<int> getGenerationCount(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data()?['generationCount'] as int? ?? 0;
      }
      return 0;
    } catch (e) {
      throw Exception('Failed to get generation count: $e');
    }
  }

  Future<void> incrementGenerationCount(String uid) async {
    try {
      final docRef = _firestore.collection('users').doc(uid);
      await docRef.set({
        'generationCount': FieldValue.increment(1),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to increment generation count: $e');
    }
  }
}

final usageRepositoryProvider = Provider<UsageRepository>((ref) {
  return UsageRepository(FirebaseFirestore.instance);
});

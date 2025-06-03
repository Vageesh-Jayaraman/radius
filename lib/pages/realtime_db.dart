import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class RealtimeDBService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> updateUserLocation({
    required String teamId,
    required double latitude,
    required double longitude,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _database.ref('teams/$teamId/$uid').set({
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': ServerValue.timestamp,
    });
  }

  Stream<Map<String, dynamic>> teamLocationsStream(String teamId) {
    return _database.ref('teams/$teamId').onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>? ?? {};
      return data.map((key, value) => MapEntry(key as String, value));
    });
  }
}

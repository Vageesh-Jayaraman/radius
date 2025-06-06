import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RealtimeDBService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

  Stream<List<UserLocationData>> teamLocationsStream(String teamId) {
    return _database.ref('teams/$teamId').onValue.asyncMap((event) async {
      final data = event.snapshot.value as Map<dynamic, dynamic>? ?? {};
      final List<UserLocationData> locations = [];

      for (final entry in data.entries) {
        final userId = entry.key as String;
        final location = entry.value as Map;

        final userDoc = await _firestore.collection('users').doc(userId).get();
        final userData = userDoc.data();

        if (userData != null) {
          locations.add(
            UserLocationData(
              userId: userId,
              latitude: (location['latitude'] as num).toDouble(),
              longitude: (location['longitude'] as num).toDouble(),
              username: userData['username'] ?? 'Unknown',
              avatarSeed: userData['avatarSeed'] ?? 'default',
            ),
          );
        }
      }
      return locations;
    });
  }
}

class UserLocationData {
  final String userId;
  final double latitude;
  final double longitude;
  final String username;
  final String avatarSeed;

  UserLocationData({
    required this.userId,
    required this.latitude,
    required this.longitude,
    required this.username,
    required this.avatarSeed,
  });
}

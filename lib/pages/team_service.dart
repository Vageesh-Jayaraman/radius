import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TeamService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String?> createTeam() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return null;

      final teamDoc = await _firestore.collection('teams').add({
        'createdAt': FieldValue.serverTimestamp(),
        'members': [uid],
        'validUntil': DateTime.now().add(const Duration(days: 3)),
      });

      return teamDoc.id;
    } catch (e) {
      print('Create team error: $e');
      return null;
    }
  }

  Future<String?> joinTeam(String teamId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    try {
      final teamRef = _firestore.collection('teams').doc(teamId);
      final snapshot = await teamRef.get();

      if (!snapshot.exists) return null;

      await teamRef.update({
        'members': FieldValue.arrayUnion([uid])
      });

      return teamId;
    } catch (e) {
      print('Join team error: $e');
      return null;
    }
  }

  Future<List<String>> getTeamMembers(String teamId) async {
    try {
      final doc = await _firestore.collection('teams').doc(teamId).get();
      if (doc.exists) {
        return List<String>.from(doc['members'] ?? []);
      }
    } catch (e) {
      print('Fetch team members error: $e');
    }
    return [];
  }
}

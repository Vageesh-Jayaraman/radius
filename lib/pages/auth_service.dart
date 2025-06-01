import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final ValueNotifier<User?> currentUser = ValueNotifier<User?>(null);

  FirebaseAuthService() {
    _auth.authStateChanges().listen((user) {
      currentUser.value = user;
    });
  }

  // Sign in
  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      currentUser.value = cred.user;
      return cred.user;
    } catch (e) {
      print('Sign in error: $e');
      return null;
    }
  }

  // Create account
  Future<User?> createAccount(String email, String password) async {
    try {
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      currentUser.value = cred.user;
      return cred.user;
    } catch (e) {
      print('Create account error: $e');
      return null;
    }
  }

  // Save additional user info
  Future<void> saveUserProfile(String uid, String username, String avatarSeed) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'username': username,
        'avatarSeed': avatarSeed,
        'email': currentUser.value?.email,
      });
    } catch (e) {
      print('Save profile error: $e');
    }
  }

  // Get user profile
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) return doc.data() as Map<String, dynamic>;
    } catch (e) {
      print('Get profile error: $e');
    }
    return null;
  }


  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      currentUser.value = null;
    } catch (e) {
      print('Sign out error: $e');
    }
  }

  // Reset password via email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print('Reset email error: $e');
    }
  }

  // Update display name
  Future<void> updateUsername(String newName) async {
    try {
      User? user = currentUser.value;
      if (user != null) {
        await user.updateDisplayName(newName);
        await user.reload();
        currentUser.value = _auth.currentUser;
      }
    } catch (e) {
      print('Update username error: $e');
    }
  }

  // Delete account
  Future<void> deleteAccount() async {
    try {
      await currentUser.value?.delete();
      currentUser.value = null;
    } catch (e) {
      print('Delete account error: $e');
    }
  }

  // Reset password using current password
  Future<bool> resetPasswordWithCurrent(
      String email, String currentPassword, String newPassword) async {
    try {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );
      await currentUser.value?.reauthenticateWithCredential(credential);
      await currentUser.value?.updatePassword(newPassword);
      return true;
    } catch (e) {
      print('Reset password error: $e');
      return false;
    }
  }

  // Dispose notifier when no longer needed
  void dispose() {
    currentUser.dispose();
  }
}

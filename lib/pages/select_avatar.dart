import 'package:flutter/material.dart';
import 'package:random_avatar/random_avatar.dart';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';
import 'login.dart';

class ChooseUsernamePage extends StatefulWidget {
  final User user;

  const ChooseUsernamePage({super.key, required this.user});

  @override
  State<ChooseUsernamePage> createState() => _ChooseUsernamePageState();
}

class _ChooseUsernamePageState extends State<ChooseUsernamePage> {
  final TextEditingController usernameController = TextEditingController();
  final FirebaseAuthService _authService = FirebaseAuthService();
  final Random _random = Random();
  late String _avatarSeed;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _generateAvatarSeed();
  }

  void _generateAvatarSeed() {
    setState(() {
      _avatarSeed = _randomString(10);
    });
  }

  String _randomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return String.fromCharCodes(
      Iterable.generate(
        length,
            (_) => chars.codeUnitAt(_random.nextInt(chars.length)),
      ),
    );
  }

  Future<void> _showAlert(String title, String content) async {
    return showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _chooseUsername() async {
    setState(() => _isLoading = true);

    final username = usernameController.text.trim();

    if (username.isEmpty) {
      await _showAlert("Missing Field", "Please enter a username.");
      setState(() => _isLoading = false);
      return;
    }

    await _authService.saveUserProfile(widget.user.uid, username, _avatarSeed);

    await _showAlert("Profile Saved", "Welcome, $username!");

    setState(() => _isLoading = false);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Avatar with edit icon
                SizedBox(
                  width: 180,
                  height: 180,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircleAvatar(
                        radius: 90,
                        backgroundColor: Colors.black,
                        child: CircleAvatar(
                          radius: 85,
                          backgroundColor: Colors.red,
                          child: RandomAvatar(_avatarSeed, height: 140, width: 140, trBackground: true),
                        ),
                      ),
                      Positioned(
                        bottom: 15,
                        right: 12,
                        child: GestureDetector(
                          onTap: _generateAvatarSeed,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(),
                            ),
                            padding: const EdgeInsets.all(8),
                            child: const Icon(Icons.edit, color: Colors.black, size: 28),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                const Text(
                  "Choose Username",
                  style: TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: 300,
                  child: TextField(
                    controller: usernameController,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 140,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _chooseUsername,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          textStyle: const TextStyle(
                            fontFamily: 'SF Pro Display',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text("Submit"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

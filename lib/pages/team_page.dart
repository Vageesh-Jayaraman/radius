import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:radius/pages/team_service.dart';
import 'package:radius/pages/auth_service.dart';
import 'package:random_avatar/random_avatar.dart';
import 'map_page.dart';

class TeamPage extends StatefulWidget {
  const TeamPage({super.key});

  @override
  State<TeamPage> createState() => _TeamPageState();
}

class _TeamPageState extends State<TeamPage> {
  final TextEditingController teamController = TextEditingController();
  final TeamService _teamService = TeamService();
  final FirebaseAuthService _authService = FirebaseAuthService();

  bool _isCreatingTeam = false;
  bool _isJoiningTeam = false;

  String? _username;
  String? _avatarSeed;
  bool _profileLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    _authService.currentUser.addListener(() async {
      final user = _authService.currentUser.value;
      if (user != null) {
        final profile = await _authService.getUserProfile(user.uid);
        setState(() {
          _username = profile?['username'] ?? user.email ?? '';
          _avatarSeed = profile?['avatarSeed'] ?? '';
          _profileLoading = false;
        });
      } else {
        setState(() {
          _profileLoading = false;
        });
      }
    });

    final user = _authService.currentUser.value;
    if (user != null) {
      final profile = await _authService.getUserProfile(user.uid);
      setState(() {
        _username = profile?['username'] ?? user.email ?? '';
        _avatarSeed = profile?['avatarSeed'] ?? '';
        _profileLoading = false;
      });
    } else {
      setState(() {
        _profileLoading = false;
      });
    }
  }

  void showTeamIdDialog(String teamId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Your Team ID'),
        content: Row(
          children: [
            Expanded(
              child: SelectableText(
                teamId,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.copy),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: teamId));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Team ID copied to clipboard')),
                );
              },
            )
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => MapPage(teamId: teamId)),
              );
            },
            child: const Text('Continue'),
          )
        ],
      ),
    );
  }

  void handleCreateTeam() async {
    setState(() => _isCreatingTeam = true);
    final teamId = await _teamService.createTeam();
    setState(() => _isCreatingTeam = false);

    if (teamId != null) {
      showTeamIdDialog(teamId);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create team')),
      );
    }
  }

  void handleJoinTeam() async {
    final teamId = teamController.text.trim();
    if (teamId.isEmpty) return;

    setState(() => _isJoiningTeam = true);
    final joinedTeamId = await _teamService.joinTeam(teamId);
    setState(() => _isJoiningTeam = false);

    if (joinedTeamId != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => MapPage(teamId: joinedTeamId)),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Joined team successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid Team ID')),
      );
    }
  }

  void handleSignOut() async {
    await _authService.signOut();
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  void handleDeleteAccount() async {
    try {
      await _authService.deleteAccount();
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (e.toString().contains('requires-recent-login')) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Re-authentication Required'),
            content: const Text(
              'This operation is sensitive and requires recent authentication. Please log out and log in again before retrying this request.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete account error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 24.0, bottom: 12.0),
              child: _profileLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_avatarSeed != null && _avatarSeed!.isNotEmpty)
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.black,
                      child: CircleAvatar(
                        radius: 32,
                        backgroundColor: Colors.red,
                        child: RandomAvatar(_avatarSeed!, height: 48, width: 48, trBackground: true),
                      ),
                    )
                  else
                    const CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.black,
                      child: Icon(Icons.person, color: Colors.white, size: 36),
                    ),
                  const SizedBox(width: 16),
                  Text(
                    _username ?? '',
                    style: const TextStyle(
                      fontFamily: 'SF Pro Display',
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isCreatingTeam ? null : handleCreateTeam,
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
                  child: _isCreatingTeam
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Create a new team"),
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 50.0),
            child: Divider(thickness: 1, color: Colors.grey),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 300,
                    child: TextField(
                      controller: teamController,
                      decoration: InputDecoration(
                        labelText: 'Team ID',
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.black),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.black, width: 2),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isJoiningTeam ? null : handleJoinTeam,
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
                      child: _isJoiningTeam
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Join with Team ID"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: FloatingActionButton(
              heroTag: 'delete',
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              onPressed: handleDeleteAccount,
              child: const Icon(Icons.delete),
            ),
          ),
          FloatingActionButton(
            heroTag: 'signout',
            backgroundColor: Colors.red.shade700,
            foregroundColor: Colors.white,
            onPressed: handleSignOut,
            child: const Icon(Icons.logout),
          ),
        ],
      ),
    );
  }
}

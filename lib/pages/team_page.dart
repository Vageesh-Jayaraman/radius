import 'package:flutter/material.dart';
import 'package:radius/pages/auth_service.dart';
import 'package:radius/pages/team_helper.dart';
import 'package:radius/pages/team_service.dart';
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
          _username = profile?['username'] ?? '';
          _avatarSeed = profile?['avatarSeed'] ?? '';
          _profileLoading = false;
        });
      } else {
        setState(() => _profileLoading = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: buildAppBar(context, showInfoDialog),
      body: Column(
        children: [
          if (!_profileLoading)
            buildProfileHeader(_avatarSeed, _username),
          const Divider(height: 1, color: Colors.black),
          buildCurrentTeamsSection(_teamService, handleDeleteTeam),
          const Divider(height: 1, color: Colors.black),
          Expanded(child: Padding(padding: const EdgeInsets.all(24.0), child: buildCreateTeam(_isCreatingTeam, handleCreateTeam))),
          const Divider(height: 1, color: Colors.black),
          Expanded(child: Padding(padding: const EdgeInsets.all(24.0), child: buildJoinTeam(_isJoiningTeam, teamController, handleJoinTeam))),
        ],
      ),
      floatingActionButton: buildFABs(handleSignOut, handleDeleteAccount),
    );
  }

  void showInfoDialog() => displayInfoDialog(context);

  void showTeamIdDialog(String teamId) => displayTeamIdDialog(context, teamId);

  void handleCreateTeam() async {
    setState(() => _isCreatingTeam = true);
    final teamId = await _teamService.createTeam();
    setState(() => _isCreatingTeam = false);
    if (teamId != null) {
      showTeamIdDialog(teamId);
    } else {
      showSnackBar(context, 'Failed to create team');
    }
  }

  void handleJoinTeam() async {
    final teamId = teamController.text.trim();
    if (teamId.isEmpty) return;
    setState(() => _isJoiningTeam = true);
    final joinedTeamId = await _teamService.joinTeam(teamId);
    setState(() => _isJoiningTeam = false);
    if (joinedTeamId != null) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MapPage(teamId: joinedTeamId)));
      showSnackBar(context, 'Joined team successfully');
    } else {
      showSnackBar(context, 'Invalid Team ID');
    }
  }

  void handleSignOut() async {
    await _authService.signOut();
    if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void handleDeleteAccount() async {
    try {
      await _authService.deleteAccount();
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      handleDeleteError(context, e);
    }
  }

  Future<void> handleDeleteTeam(String teamId) async {
    final confirm = await confirmDeleteTeam(context);
    if (confirm == true) {
      await _teamService.deleteTeam(teamId);
      setState(() {});
      showSnackBar(context, 'Team deleted');
    }
  }
}
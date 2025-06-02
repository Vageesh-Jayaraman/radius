import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  bool _isCreatingTeam = false;
  bool _isJoiningTeam = false;

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
                MaterialPageRoute(builder: (_) => const MapPage()),
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
    final joined = await _teamService.joinTeam(teamId);
    setState(() => _isJoiningTeam = false);

    if (joined) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MapPage()),
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
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
                          borderSide:
                          const BorderSide(color: Colors.black, width: 2),
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
    );
  }
}

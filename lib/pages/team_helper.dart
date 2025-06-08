import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:random_avatar/random_avatar.dart';

PreferredSizeWidget buildAppBar(BuildContext context, VoidCallback onInfoPressed) => AppBar(
  backgroundColor: Colors.black,
  elevation: 0,
  title: const Text('Radius', style: TextStyle(fontFamily: 'SF Pro Display', fontWeight: FontWeight.bold, fontSize: 26, color: Colors.white)),
  actions: [IconButton(icon: const Icon(Icons.info_outline, color: Colors.white), onPressed: onInfoPressed)],
);

Widget buildProfileHeader(String? avatarSeed, String? username) => Padding(
  padding: const EdgeInsets.all(8.0),
  child: Row(
    children: [
      if (avatarSeed != null && avatarSeed.isNotEmpty)
        CircleAvatar(radius: 20, child: RandomAvatar(avatarSeed, height: 60, width: 60, trBackground: true))
      else
        const CircleAvatar(radius: 20, backgroundColor: Colors.grey, child: Icon(Icons.person, size: 20, color: Colors.white)),
      const SizedBox(width: 16),
      Text("Hi ${username!}" ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
    ],
  ),
);

Widget buildCurrentTeamsSection(dynamic teamService, Function(String) handleDeleteTeam) => Expanded(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Padding(padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8), child: Text('Teams Created By You', style: TextStyle(fontFamily: 'SF Pro Display', fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black))),
      Expanded(
        child: FutureBuilder<List<String>>(
          future: teamService.getTeamsCreatedByUser(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            final teams = snapshot.data ?? [];
            if (teams.isEmpty) return const Center(child: Text('No current teams', style: TextStyle(fontSize: 18)));
            return ListView.separated(
              itemCount: teams.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, idx) => buildTeamTile(context, teams[idx], handleDeleteTeam),
            );
          },
        ),
      ),
    ],
  ),
);

ListTile buildTeamTile(BuildContext context, String teamId, Function(String) handleDeleteTeam) => ListTile(
  title: Text(teamId),
  trailing: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      IconButton(icon: const Icon(Icons.copy), onPressed: () => Clipboard.setData(ClipboardData(text: teamId)).then((_) => showSnackBar(context, 'Team ID copied to clipboard'))),
      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => handleDeleteTeam(teamId)),
    ],
  ),
);

Widget buildCreateTeam(bool isCreating, VoidCallback onCreate) => Center(
  child: SizedBox(
    height: 50,
    child: ElevatedButton(
      onPressed: isCreating ? null : onCreate,
      style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), textStyle: const TextStyle(fontFamily: 'SF Pro Display', fontSize: 18, fontWeight: FontWeight.bold)),
      child: isCreating ? const CircularProgressIndicator(color: Colors.white) : const Text("Create a new team"),
    ),
  ),
);

Widget buildJoinTeam(bool isJoining, TextEditingController controller, VoidCallback onJoin) => Center(
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      SizedBox(
        width: 300,
        child: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: 'Team ID', enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black, width: 2))),
        ),
      ),
      const SizedBox(height: 20),
      SizedBox(
        height: 50,
        child: ElevatedButton(
          onPressed: isJoining ? null : onJoin,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), textStyle: const TextStyle(fontFamily: 'SF Pro Display', fontSize: 18, fontWeight: FontWeight.bold)),
          child: isJoining ? const CircularProgressIndicator(color: Colors.white) : const Text("Join with Team ID"),
        ),
      ),
    ],
  ),
);

Column buildFABs(VoidCallback onSignOut, VoidCallback onDeleteAccount) => Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.end,
  children: [
    Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: FloatingActionButton(heroTag: 'delete', backgroundColor: Colors.red, foregroundColor: Colors.white, onPressed: onDeleteAccount, child: const Icon(Icons.delete)),
    ),
    FloatingActionButton(heroTag: 'signout', backgroundColor: Colors.red.shade700, foregroundColor: Colors.white, onPressed: onSignOut, child: const Icon(Icons.logout)),
  ],
);

void showSnackBar(BuildContext context, String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

void displayTeamIdDialog(BuildContext context, String teamId) => showDialog(
  context: context,
  builder: (_) => AlertDialog(
    title: const Text('Your Team ID'),
    content: Row(
      children: [
        Expanded(child: SelectableText(teamId, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20))),
        IconButton(icon: const Icon(Icons.copy), onPressed: () => Clipboard.setData(ClipboardData(text: teamId)).then((_) => showSnackBar(context, 'Team ID copied to clipboard'))),
      ],
    ),
    actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Continue'))],
  ),
);

void displayInfoDialog(BuildContext context) => showDialog(
  context: context,
  builder: (_) => AlertDialog(
    title: const Text('About Radius', style: TextStyle(fontFamily: 'SF Pro Display', fontWeight: FontWeight.bold)),
    content: const Text('Radius lets you securely create or join teams and share real-time locations within a group. Simple, fast, and private.', style: TextStyle(fontFamily: 'SF Pro Display')),
    actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK', style: TextStyle(fontFamily: 'SF Pro Display')))],
  ),
);

Future<bool?> confirmDeleteTeam(BuildContext context) => showDialog<bool>(
  context: context,
  builder: (context) => AlertDialog(
    title: const Text('Delete Team'),
    content: const Text('Are you sure you want to delete this team?'),
    actions: [
      TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
      TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
    ],
  ),
);

void handleDeleteError(BuildContext context, dynamic e) {
  if (e.toString().contains('requires-recent-login')) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Re-authentication Required'),
        content: const Text('This operation is sensitive and requires recent authentication. Please log out and log in again before retrying this request.'),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK'))],
      ),
    );
  } else {
    showSnackBar(context, 'Delete account error: $e');
  }
}
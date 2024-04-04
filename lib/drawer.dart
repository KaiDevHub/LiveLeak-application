import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile.dart';
import 'login.dart';
import 'yourpost.dart';
import 'userinterest.dart';
import 'searchuser.dart';
import 'inbox.dart';

class DrawerContent extends StatefulWidget {
  final User? currentUser;

  const DrawerContent({Key? key, required this.currentUser}) : super(key: key);

  @override
  _DrawerContentState createState() => _DrawerContentState();
}

class _DrawerContentState extends State<DrawerContent> {
  String? _username;
  String? _email;
  String? _photoURL;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  void _fetchUserData() async {
  final userSnapshot = await FirebaseFirestore.instance
      .collection('users')
      .doc(widget.currentUser?.uid)
      .get();

  Map<String, dynamic>? data = userSnapshot.data();

  if (data != null) {
    _username = data['username'] as String?;
    _email = data['email'] as String?;
    _photoURL = data['photoURL'] as String?;
  }

  if (mounted) {
    setState(() {});  // Refresh the UI
  }
}



  @override
Widget build(BuildContext context) {
  return Drawer(
    child: Container(
      color: Color.fromARGB(255, 80, 184, 165),  // Background color to match AppBar
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: Color.fromARGB(255, 17, 136, 138),  // Darker shade for header for contrast
            ),
            accountName: Text(
              _username ?? '',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(
              _email ?? '',
              style: TextStyle(fontSize: 16),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundImage: _photoURL != null ? NetworkImage(_photoURL!) : null,
              child: _photoURL == null ? const Icon(Icons.person, size: 40.0, color: Colors.white) : null,
            ),
            onDetailsPressed: () {
              if (widget.currentUser != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => UserProfile(user: widget.currentUser!)),
                );
              }
            },
          ),
          _buildTile(Icons.featured_play_list, 'Your Posts', YourPostsPage()),
          _buildTile(Icons.interests_outlined, 'Your Interest', UserInterestPage()),
          _buildTile(Icons.search, 'Search Users', SearchUserPage()),
          _buildTile(Icons.inbox, 'Inbox', InboxPage()),
          Divider(color: const Color.fromARGB(137, 36, 1, 1)),
          _buildTile(Icons.logout, 'Log Out', LoginPage(), isLogout: true),
        ],
      ),
    ),
  );
}

Widget _buildTile(IconData icon, String title, Widget page, {bool isLogout = false}) {
  return ListTile(
    leading: Icon(icon, color: Colors.white),
    title: Text(title, style: TextStyle(color: Colors.white)),
    onTap: () {
      if (isLogout) {
        FirebaseAuth.instance.signOut().then(
          (_) => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => page),
          ),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => page),
        );
      }
    },
  );
}
}
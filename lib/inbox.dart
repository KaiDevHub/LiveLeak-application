import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat.dart';
import 'package:google_fonts/google_fonts.dart';

class InboxPage extends StatefulWidget {
  @override
  _InboxPageState createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> {
  final CollectionReference chats = FirebaseFirestore.instance.collection('chats');
  final CollectionReference users = FirebaseFirestore.instance.collection('users');
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;

  Future<String> getUsername(String userId) async {
  DocumentSnapshot userSnapshot = await users.doc(userId).get();
  Map<String, dynamic>? userData = userSnapshot.data() as Map<String, dynamic>?; // Explicitly cast here
  return userData?['username'] ?? 'Unknown';
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
        title: Text(
    'Inbox', 
    style: GoogleFonts.lobster(
      textStyle: TextStyle(
        color: Color.fromARGB(255, 253, 254, 254),
        fontSize: 26.0,
        fontWeight: FontWeight.bold,
      ),
    ),
  ),
  backgroundColor: Color.fromARGB(255, 30, 144, 125),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: chats.where('participants', arrayContains: _currentUserId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          } else {
            List<DocumentSnapshot> chatDocs = snapshot.data!.docs;

            return ListView.builder(
              itemCount: chatDocs.length,
              itemBuilder: (context, index) {
                List<String> participants = List<String>.from(chatDocs[index]['participants']);  // Casting here
                String peerUserId = participants.firstWhere((id) => id != _currentUserId);

                return FutureBuilder<String>(
                  future: getUsername(peerUserId),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return ListTile(title: CircularProgressIndicator());
                    } else {
                   return ListTile(
  title: Align(
    alignment: Alignment.centerLeft,
    child: Container(
      padding: EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        color: Color.fromARGB(255, 30, 144, 125),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '${snapshot.data}',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  ),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(peerUserId: peerUserId),
      ),
    );
  },
);



                    }
                  },
                );
              },
            );
          }
        },
      ),
    );
  }
}

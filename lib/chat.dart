import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatPage extends StatefulWidget {
  final String peerUserId;

  ChatPage({required this.peerUserId});

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _messageController = TextEditingController();
  
  // Assuming that a user is always logged in when this page is accessed.
  // If there's a possibility of no user being logged in, handle this scenario gracefully.
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;

  final CollectionReference chats = FirebaseFirestore.instance.collection('chats');

  String getChatId(String user1, String user2) {
    return (user1.hashCode <= user2.hashCode)
        ? '$user1-$user2'
        : '$user2-$user1';
  }

  Future<void> _deleteMessage(String messageId) async {
    await chats
        .doc(getChatId(_currentUserId, widget.peerUserId))
        .collection('messages')
        .doc(messageId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
        title: Text(
    'Chat', 
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
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: chats
                  .doc(getChatId(_currentUserId, widget.peerUserId))
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                } else {
                  // Using the non-null assertion (!) operator to guarantee snapshot.data is non-null.
                  List<DocumentSnapshot> messages = snapshot.data!.docs;
                  return ListView.builder(
                    reverse: true,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      bool isCurrentUser = messages[index]['senderId'] == _currentUserId;
                      final messageId = messages[index].id;
                      return GestureDetector(
  onLongPress: isCurrentUser
      ? () async {
          final selected = await showMenu(
            context: context,
            position: RelativeRect.fill,
            items: [
              PopupMenuItem(
                value: 'delete',
                child: Text('Delete Message'),
              ),
            ],
          );

          if (selected == 'delete') {
            await _deleteMessage(messageId);
          }
        }
      : null,
  child: Align(
    alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 8.0),
      padding: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        color: isCurrentUser ? Colors.blue[200] : Colors.grey[200],
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: Column(
        crossAxisAlignment: isCurrentUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Text(
            messages[index]['text'],
            style: TextStyle(
                color: isCurrentUser ? Colors.white : Colors.black),
          ),
          SizedBox(height: 5),
        ],
      ),
    ),
  ),
);
                    },
                  );
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      labelText: 'Message',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () async {
                    if (_messageController.text.isNotEmpty) {
                      final chatDocRef = chats.doc(getChatId(_currentUserId, widget.peerUserId));

                      await chatDocRef.collection('messages').add({
                        'text': _messageController.text,
                        'senderId': _currentUserId,
                        'timestamp': Timestamp.now(),
                      });

                      // Update the participants field
                      await chatDocRef.set({
                        'participants': [_currentUserId, widget.peerUserId]
                      }, SetOptions(merge: true));

                      _messageController.clear();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

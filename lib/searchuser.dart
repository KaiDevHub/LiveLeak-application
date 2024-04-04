import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat.dart';
import 'package:google_fonts/google_fonts.dart';

class SearchUserPage extends StatefulWidget {
  const SearchUserPage({super.key});

  @override
  _SearchUserPageState createState() => _SearchUserPageState();
}

class _SearchUserPageState extends State<SearchUserPage> {
  final TextEditingController _usernameController = TextEditingController();
  final CollectionReference _usersCollection = FirebaseFirestore.instance.collection('users');
  final CollectionReference chats = FirebaseFirestore.instance.collection('chats');

  List<QueryDocumentSnapshot> _searchResults = [];
  final _currentUserId = FirebaseAuth.instance.currentUser?.uid;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    DocumentSnapshot userDoc = await _usersCollection.doc(_currentUserId).get();
    if (userDoc.exists && userDoc['statusAdmin'] == true) {
     if(mounted){
      setState(() {
        _isAdmin = true;
      });
     }
    }
  }

  String getChatId(String? user1, String? user2) {
    if (user1 == null || user2 == null) {
      throw ArgumentError('User IDs should not be null');
    }

    return (user1.hashCode <= user2.hashCode)
        ? '$user1-$user2'
        : '$user2-$user1';
  }

Future<void> _searchForUser() async {
  String searchString = _usernameController.text.trim();
  if (searchString.isNotEmpty) {
    QuerySnapshot usernameQuerySnapshot = await _usersCollection
        .where('username', isEqualTo: searchString)
        .get();
    QuerySnapshot emailQuerySnapshot = await _usersCollection
        .where('email', isEqualTo: searchString)
        .get();

    List<QueryDocumentSnapshot> combinedResults = [];
    combinedResults.addAll(usernameQuerySnapshot.docs);
    combinedResults.addAll(emailQuerySnapshot.docs);

    if (combinedResults.isEmpty) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('No users found'),
            content: const Text('There are no users with that username or email'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    } else {
      if (mounted) {
        setState(() {
          _searchResults = combinedResults;
        });
      }
    }
  } else {
    if (mounted) {
      setState(() {
        _searchResults = [];
      });
    }
  }
}



Future<void> _banUser(String userId) async {
  await _usersCollection.doc(userId).set({'banStatus': true}, SetOptions(merge: true));

  // Re-fetch users after a change
  _searchForUser();
}

Future<void> _unbanUser(String userId) async {
  await _usersCollection.doc(userId).set({'banStatus': false}, SetOptions(merge: true));

  // Re-fetch users after a change
  _searchForUser();
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
       appBar: AppBar(
        title: Text(
          'Find User',
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username or Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16.0),
           ElevatedButton(
  onPressed: _searchForUser,
  child: const Text('Search'),
  style: ElevatedButton.styleFrom(
    primary: Colors.deepPurpleAccent,  // Button color
    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 2),  // Adjust padding for better fit
  ),
),


            const SizedBox(height: 1.0),
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  bool isBanned = (_searchResults[index].data() as Map<String, dynamic>)?['banStatus'] ?? false;


                  
                  return ListTile(
                    title: Text(_searchResults[index]['username']),
                    subtitle: Text(_searchResults[index]['email']),
                    trailing: Wrap(
                      spacing: 8.0,  // gap between adjacent buttons
                      children: [
                        if (_searchResults[index].id != _currentUserId)
                          ElevatedButton(
                            onPressed: () async {
                              final chatId = getChatId(_currentUserId, _searchResults[index].id);
                              final chatDocRef = chats.doc(chatId);

                              await chatDocRef.set({
                                'participants': [_currentUserId, _searchResults[index].id]
                              }, SetOptions(merge: true));

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatPage(peerUserId: _searchResults[index].id),
                                ),
                              );
                            },
                            child: const Text('Chat'),
                          ),
                      if (_isAdmin && _searchResults[index].id != _currentUserId)
                        ElevatedButton(
                             onPressed: isBanned
                              ? () => _unbanUser(_searchResults[index].id)
                                : () => _banUser(_searchResults[index].id),
                                   child: Text(isBanned ? 'Unban' : 'Ban'),
                                      style: ElevatedButton.styleFrom(primary: isBanned ? Colors.green : Colors.red),
  ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

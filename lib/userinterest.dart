import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'top_categories_model.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

class UserInterestPage extends StatefulWidget {
  const UserInterestPage({Key? key}) : super(key: key);

  @override
  _UserInterestPageState createState() => _UserInterestPageState();
}

class _UserInterestPageState extends State<UserInterestPage> {
  late Stream<DocumentSnapshot> _userStream;

  @override
void initState() {
    super.initState();
    
    final userId = FirebaseAuth.instance.currentUser!.uid;
    _userStream = FirebaseFirestore.instance.collection('users').doc(userId).snapshots();

    _storeInterestsToFirestore();  // Automatically set or update interests when the page is loaded
}

Future<void> _storeInterestsToFirestore() async {
    final topCategories = Provider.of<TopCategoriesModel>(context, listen: false).categories;
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final userRef = FirebaseFirestore.instance.collection('users').doc(userId);

    // Fetch current interests from Firestore
   DocumentSnapshot snapshot = await userRef.get();
if (snapshot.exists && snapshot.data() is Map<String, dynamic>) {
    Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
    List<String> currentInterests = List<String>.from((data['interest'] as List?) ?? []);

    // Compare currentInterests with topCategories
    bool interestsChanged = !Set<String>.from(currentInterests).containsAll(topCategories) || 
                            !Set<String>.from(topCategories).containsAll(currentInterests);

    // If interests have changed, then update Firestore
    if (interestsChanged) {
        await userRef.set({'interest': topCategories}, SetOptions(merge: true));
    }
}

      }

    @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Interest',
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
      body: RefreshIndicator(
        onRefresh: _storeInterestsToFirestore,
        child: StreamBuilder<DocumentSnapshot>(
          stream: _userStream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}'),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            final userData = snapshot.data!.data() as Map<String, dynamic>;
            final interest = List<String>.from(userData['interest'] as List? ?? []);

            if (interest.isEmpty) {
              return const Center(
                child: Text('No interests found.'),
              );
            }

            return ListView.builder(
              itemCount: interest.length,
              itemBuilder: (context, index) {
                final category = interest[index];
                return Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: EdgeInsets.all(10.0),
                      decoration: BoxDecoration(
                        color: Color.fromARGB(255, 30, 144, 125),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        category,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
} // <-- This is the corrected closing brace for _UserInterestPageState class

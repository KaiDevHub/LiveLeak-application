import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login.dart';


class BanPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FutureBuilder<void>(
          // As soon as the BanPage is opened, this FutureBuilder will execute the showDialog function.
          future: _showBannedDialog(context),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              // Once the dialog is closed, navigate back to LoginPage.
              WidgetsBinding.instance?.addPostFrameCallback((_) {
                Navigator.of(context).pushReplacement(MaterialPageRoute(
                  builder: (context) => LoginPage(),
                ));
              });
            }
            return Container(); // An empty container, since our main UI is in the dialog.
          },
        ),
      ),
    );
  }

  Future<void> _showBannedDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap button to close dialog.
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Access Denied'),
          content: Text('You have been banned'),
          actions: <Widget>[
            ElevatedButton(
              child: Text('Okay'),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.of(dialogContext).pop(); // Closes the dialog
              },
            ),
          ],
        );
      },
    );
  }
}

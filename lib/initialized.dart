import 'package:flutter/material.dart';
import 'notification_manager.dart';
import 'readnews.dart';


class InitializationPage extends StatefulWidget {
  @override
  _InitializationPageState createState() => _InitializationPageState();
}

class _InitializationPageState extends State<InitializationPage> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _initializeNotificationManager();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => ReadNewsPage()),
    );
  }

  Future<void> _initializeNotificationManager() async {
    final notificationManager = NotificationManager();
    await notificationManager.init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: CircularProgressIndicator()), // or any loading widget
    );
  }
}

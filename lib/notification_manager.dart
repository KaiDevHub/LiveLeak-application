import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'recommendation.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class NotificationManager {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> init() async {
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: true,
    );

    
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        onNotificationReceived(
          title: message.notification!.title ?? 'Notification',
          body: message.notification!.body ?? '',
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationTap();
    });

    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap();
    }

    _firebaseMessaging.getToken().then((token) {
      print('FCM Token: $token');
      _storeFCMTokenToFirestore(token);
    });
  }

  Future<void> onNotificationReceived({required String title, required String body}) async {
    
  }

  void _storeFCMTokenToFirestore(String? token) async {
    User? currentUser = _auth.currentUser;

    if (currentUser != null && token != null) {
      DocumentReference userRef = _firestore.collection('users').doc(currentUser.uid);

      try {
        await userRef.update({'fcmToken': token});
        print('FCM Token stored in Firestore.');
      } catch (e) {
        print('Error storing FCM Token: $e');
      }
    }
  }

  void _handleNotificationTap() {
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => RecommendationPage(),
      ),
    );
  }
}

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  
}

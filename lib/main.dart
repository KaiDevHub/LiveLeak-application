import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'readnews.dart';
import 'package:provider/provider.dart';
import 'top_categories_model.dart'; 
import 'notification_manager.dart';



Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();



   runApp(
    ChangeNotifierProvider<TopCategoriesModel>(
      create: (context) => TopCategoriesModel(),
      child: MyApp(),
    ),
  );
}


class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LiveLeak',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      navigatorKey: navigatorKey,  
      home: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasData) {
            // User is signed in, display the ReadNewsPage().
            return const ReadNewsPage();
          } else {
            // User is not signed in, display the LoginPage.
            return  LoginPage();
          }
        },
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

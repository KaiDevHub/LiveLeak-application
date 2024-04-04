import 'package:flutter/material.dart';
import 'nearestnews.dart';
import 'recommendation.dart';
import 'package:google_fonts/google_fonts.dart';

import 'readnews.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onNearYouPressed;
  final VoidCallback onAllNewsPressed;
  final VoidCallback onForYouPressed;

  CustomAppBar({
    required this.onNearYouPressed,
    required this.onAllNewsPressed,
    required this.onForYouPressed,
  });

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + 48.0); // combined height of AppBar and bottom bar

  @override
  Widget build(BuildContext context) {
    return AppBar(
    title: Text(
    'Live Leak', 
    style: GoogleFonts.lobster(
      textStyle: TextStyle(
        color: Color.fromARGB(255, 253, 254, 254),
        fontSize: 26.0,
        fontWeight: FontWeight.bold,
      ),
    ),
  ),
      backgroundColor: Color.fromARGB(255, 30, 144, 125),
      actions: [],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(48.0),
        child: Container(
          color: Color.fromARGB(255, 30, 144, 125),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
           children: [
  ElevatedButton(
    style: ElevatedButton.styleFrom(
      primary: Colors.transparent,  // Make button background transparent
      onPrimary: Colors.transparent,  // Remove splash color
      shadowColor: Colors.transparent,  // No shadow
      side: BorderSide(width: 0, color: Colors.transparent),  // No border
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(0),
      ),
      padding: EdgeInsets.zero,  // Remove default padding
    ),
    onPressed: () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const NearestNewsPage()),
      );
    },
    child: Text(
      'Near You',
      style: TextStyle(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.bold,
      ),
    ),
  ),
  ElevatedButton(
    style: ElevatedButton.styleFrom(
      primary: Colors.transparent,
      onPrimary: Colors.transparent,
      shadowColor: Colors.transparent,
      side: BorderSide(width: 0, color: Colors.transparent),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(0),
      ),
      padding: EdgeInsets.zero,
    ),
    onPressed: () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ReadNewsPage()),
      );
    },
    child: Text(
      'All News',
      style: TextStyle(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.bold,
      ),
    ),
  ),
  ElevatedButton(
    style: ElevatedButton.styleFrom(
      primary: Colors.transparent,
      onPrimary: Colors.transparent,
      shadowColor: Colors.transparent,
      side: BorderSide(width: 0, color: Colors.transparent),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(0),
      ),
      padding: EdgeInsets.zero,
    ),
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const RecommendationPage()),
      );
    },
    child: Text(
      'For You',
      style: TextStyle(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.bold,
      ),
    ),
  ),
],

          ),
        ),
      ),
    );
  }
}
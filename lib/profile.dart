import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

class UserProfile extends StatefulWidget {
  final User user;

  const UserProfile({Key? key, required this.user}) : super(key: key);

  @override
  _UserProfileState createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  final TextEditingController _usernameController = TextEditingController();
  
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  late File _imageFile;
  bool _hasImage = false;
  String? _photoURL; // Variable to store the user's photoURL

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

 void _fetchUserData() async {
  final userSnapshot = await FirebaseFirestore.instance
      .collection('users')
      .doc(widget.user.uid)
      .get();

  Map<String, dynamic>? data = userSnapshot.data();

  if (data != null) {
    _usernameController.text = data['username'] as String? ?? '';
    _photoURL = data['photoURL'] as String?;
  }

  if (mounted) {
    setState(() {});  // Refresh the UI
  }
}


  void _updateProfile() async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .update({
        'username': _usernameController.text,
        
        'photoURL': _photoURL,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: $e')),
      );
    }
  }

  void _updatePassword() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    if (_passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters long')),
      );
      return;
    }

    try {
      await widget.user.updatePassword(_passwordController.text);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update password: $e')),
      );
    }
  }

  Future<void> _pickImage() async {
    final pickedImage = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      _imageFile = File(pickedImage.path);
      _hasImage = true;

      // Upload image to Firebase Storage
      final userId = widget.user.uid;
      final storageRef = firebase_storage.FirebaseStorage.instance.ref().child('user_profile_images/$userId.jpg');
      await storageRef.putFile(_imageFile);

      // Get the download URL of the uploaded image
      final imageUrl = await storageRef.getDownloadURL();

      // Update the _photoURL state
      _photoURL = imageUrl;
      if (mounted) {
        setState(() {});  // Refresh the UI
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50.0,
                    backgroundImage: _hasImage
                      ? FileImage(_imageFile)
                      : (_photoURL != null ? NetworkImage(_photoURL!) : null) as ImageProvider<Object>?,
                    child: _hasImage ? null : const Icon(Icons.person),
                  ),
                  const SizedBox(height: 8.0),
                  const Text('Change Profile Picture'),
                ],
              ),
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: _confirmPasswordController,
              decoration: const InputDecoration(
                labelText: 'Confirm New Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _updateProfile,
              child: const Text('Update Profile'),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _updatePassword,
              child: const Text('Update Password'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'readnews.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';
import 'package:google_fonts/google_fonts.dart';

class PostNewsPage extends StatefulWidget {
  const PostNewsPage({Key? key}) : super(key: key);

  @override
  _PostNewsPageState createState() => _PostNewsPageState();
}

class _PostNewsPageState extends State<PostNewsPage> {
  Position? _currentPosition;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  File? _imageFile;
  File? _videoFile;
  String? _selectedCategory;
  VideoPlayerController? _videoController;

  Future<void> _pickImage(ImageSource source) async {
    final locationPermissionStatus = await Permission.location.request();
    if (locationPermissionStatus.isGranted) {
      _currentPosition = await Geolocator.getCurrentPosition();
      final pickedImage = await ImagePicker().pickImage(
        source: source,
        imageQuality: 50,
      );
      if (mounted){
      setState(() {
        _imageFile = File(pickedImage!.path);
        _videoFile = null;
      });
      }
    } else {
      // Handle if the location permission is denied
    }
  }

  Future<void> _pickVideo(ImageSource source) async {
    final locationPermissionStatus = await Permission.location.request();
    if (locationPermissionStatus.isGranted) {
      _currentPosition = await Geolocator.getCurrentPosition();
      final pickedVideo = await ImagePicker().pickVideo(
        source: source,
      );
      setState(() {
        _videoFile = File(pickedVideo!.path);
        _imageFile = null;
        _videoController = VideoPlayerController.file(_videoFile!);
        _videoController!.initialize().then((_) {
          setState(() {});
          _videoController!.play();
        });
      });
    } else {
      // Handle if the location permission is denied
    }
  }

  Future<void> _uploadData() async {
    final User? user = FirebaseAuth.instance.currentUser;
    final String? userId = user?.uid;
    final latitude = _currentPosition?.latitude ?? 0.0;
    final longitude = _currentPosition?.longitude ?? 0.0;
    final storage = FirebaseStorage.instance;
    final ref = storage.ref().child('news_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
    String? imageUrl;
    String? videoUrl;

    if (_imageFile != null) {
      final imageRef = storage.ref().child('news_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
      final imageTask = imageRef.putFile(_imageFile!);
      imageUrl = await (await imageTask).ref.getDownloadURL();
    }

    if (_videoFile != null) {
      final videoRef = storage.ref().child('news_videos/${DateTime.now().millisecondsSinceEpoch}.mp4');
      final videoTask = videoRef.putFile(_videoFile!);
      videoUrl = await (await videoTask).ref.getDownloadURL();
    }

    // Retrieve the username from the users collection in Firestore
    String? username;
    final userSnapshot = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (userSnapshot.exists) {
      final userData = userSnapshot.data() as Map<String, dynamic>;
      username = userData['username'];
    }

    await FirebaseFirestore.instance.collection('news').add({
      'title': _titleController.text,
      'description': _descriptionController.text,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (videoUrl != null) 'videoUrl': videoUrl,
      'timestamp': DateTime.now(),
      'category': _selectedCategory,
      'posted_by': username,
      'userId': userId, // Save the current user ID to Firestore
      'latitude': latitude,
      'longitude': longitude,
    });

    // Increment the liked category counter in the users collection
    if (_selectedCategory != null && userId != null) {
      await addCategoryToUser(userId, _selectedCategory!);
    }

    _titleController.clear();
    _descriptionController.clear();
    setState(() {
      _imageFile = null;
      _videoFile = null;
      _selectedCategory = null;
      _currentPosition = null;
      _videoController?.dispose();
    });

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const ReadNewsPage(),
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('News posted successfully')),
    );
  }

  void _submitForm() {
    if (_titleController.text.isNotEmpty &&
        _descriptionController.text.isNotEmpty &&
        ((_imageFile != null && _videoFile == null) ||
            (_imageFile == null && _videoFile != null)) &&
        _selectedCategory != null) {
      _uploadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all the fields')),
      );
    }
  }

  Future<void> addCategoryToUser(String userId, String category) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
    await userRef.update({
      'liked_categories.$category': FieldValue.increment(1),
    });
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
       appBar: AppBar(
        title: Text(
          'Post News',
          style: GoogleFonts.lobster(
            textStyle: TextStyle(
              color: Colors.white,
              fontSize: 26.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        backgroundColor: Color.fromARGB(255, 30, 144, 125),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_imageFile != null)
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: FileImage(_imageFile!),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              if (_videoFile != null)
                AspectRatio(
                  aspectRatio: _videoController!.value.aspectRatio,
                  child: VideoPlayer(_videoController!),
                ),
              const SizedBox(height: 16.0),
              ElevatedButton.icon(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.camera_alt),
                          title: const Text('Take a picture'),
                          onTap: () {
                            _pickImage(ImageSource.camera);
                            Navigator.of(context).pop();
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.photo_album),
                          title: const Text('Choose from gallery'),
                          onTap: () {
                            _pickImage(ImageSource.gallery);
                            Navigator.of(context).pop();
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.video_library),
                          title: const Text('Choose a video'),
                          onTap: () {
                            _pickVideo(ImageSource.gallery);
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    ),
                  );
                },
               icon: Icon(Icons.camera_alt),
                  label: Text('Choose Media'),
                  style: ElevatedButton.styleFrom(
                    primary: Color.fromARGB(255, 30, 144, 125),
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
              ),
              SizedBox(height: 16.0),
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    filled: true,
                    fillColor: Colors.white,
                    hintText: 'Enter the title',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                SizedBox(height: 16.0),
                TextField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    filled: true,
                    fillColor: Colors.white,
                    hintText: 'Enter the description',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  maxLines: null,
                ),
                SizedBox(height: 16.0),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Category',
                    filled: true,
                    fillColor: Colors.white,
                    hintText: 'Select a category',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  value: _selectedCategory,
                  onChanged: (newValue) {
                    setState(() {
                      _selectedCategory = newValue;
                    });
                  },
                  items: <String>[
                    'General', 'Politics', 'Sports', 'Entertainment', 'Technology', 'Business',
                    'Health', 'Education', 'Fashion', 'Food', 'Travel', 'Environment'
                  ].map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                    onPressed: _submitForm,
                    child: const Text('Post'),
                  style: ElevatedButton.styleFrom(
                    primary: Color.fromARGB(255, 30, 144, 125),
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
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

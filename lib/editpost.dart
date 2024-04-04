import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:chewie/chewie.dart';
import 'package:google_fonts/google_fonts.dart';

class EditPostPage extends StatefulWidget {
  final String postId;

  const EditPostPage({required this.postId});

  @override
  _EditPostPageState createState() => _EditPostPageState();
}

class _EditPostPageState extends State<EditPostPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  File? _imageFile;
  File? _videoFile;
  String? _selectedCategory;
  VideoPlayerController? _videoController;
  ChewieController? _editVideoController;

  @override
  void initState() {
    super.initState();
    // Retrieve post data from Firestore and update it
    FirebaseFirestore.instance
    .collection('news')
    .doc(widget.postId)
    .get()
    .then((docSnapshot) {
      print("Full document data: ${docSnapshot.data()}"); 
      if (mounted) {
        final doc = docSnapshot.data() as Map<String, dynamic>;
        setState(() {
          _titleController.text = doc['title'];
          _descriptionController.text = doc['description'];
          _selectedCategory = doc['category'];

          // Download the existing image or video
          if (doc['imageUrl'] != null) {
            _loadFileFromUrl(doc['imageUrl']).then((file) {
              if (file != null) {
                if (mounted) {
                  setState(() {
                    _imageFile = file;
                  });
                }
              }
            });
          } else if (doc['videoUrl'] != null) {
            _loadFileFromUrl(doc['videoUrl']).then((file) {
              if (file != null) {
                if (mounted) {
                  setState(() {
                    _videoFile = file;
                    _videoController = VideoPlayerController.file(_videoFile!);
                    _videoController!.initialize().then((_) {
                      if (mounted) {
                        setState(() {});
                        _videoController!.play();
                      }
                    });
                  });
                }
              }
            });
          }
        });
      }
    }).catchError((error) {
      print(error);
    });

  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedImage = await ImagePicker().pickImage(
      source: source,
      imageQuality: 50,
    );
    if (pickedImage != null) {
      if (mounted) {
        setState(() {
          _imageFile = File(pickedImage.path);
          _videoFile = null;
        });
      }
    }
  }

  Future<void> _pickVideo(ImageSource source) async {
    final pickedVideo = await ImagePicker().pickVideo(
      source: source,
    );
    if (pickedVideo != null) {
      if (mounted) {
        setState(() {
          _videoFile = File(pickedVideo.path);
          _imageFile = null;
          _videoController = VideoPlayerController.file(_videoFile!);
          _videoController!.initialize().then((_) {
            setState(() {});
            _videoController!.play();
          });
        });
      }
    }
  }

  Future<File?> _loadFileFromUrl(String url) async {
    try {
      print("Loading file from URL: $url");
      final response = await http.get(Uri.parse(url));
      print('HTTP status code: ${response.statusCode}');
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/${url.split('/').last}');
        print('File path: ${file.path}');
        await file.writeAsBytes(bytes);
        return file;
      } else {
        print('HTTP request failed with status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Exception occurred while loading file: $e');
      return null;
    }
  }

   Future<void> _updateData() async {
  // Update basic data in Firestore
  await FirebaseFirestore.instance.collection('news').doc(widget.postId).set({
    'title': _titleController.text,
    'description': _descriptionController.text,
    'category': _selectedCategory,
    'imageUrl': '', // Initialize imageUrl with empty string
    'videoUrl': '', // Initialize videoUrl with empty string
  }, SetOptions(merge: true));

  // Retrieve the current post data
  final postSnapshot = await FirebaseFirestore.instance.collection('news').doc(widget.postId).get();

  final imageUrl = postSnapshot['imageUrl'] as String?;
  final videoUrl = postSnapshot['videoUrl'] as String?;

  final storage = FirebaseStorage.instance;

  // Delete the current image/video from Firebase Storage before uploading the new one
   if (imageUrl != null && imageUrl.isNotEmpty) {
    final photoRef = storage.refFromURL(imageUrl);
    await photoRef.delete();
    await FirebaseFirestore.instance.collection('news').doc(widget.postId).update({
      'imageUrl': FieldValue.delete(),
    });
  }
 if (videoUrl != null && videoUrl.isNotEmpty) {
    final videoRef = storage.refFromURL(videoUrl);
    await videoRef.delete();
    await FirebaseFirestore.instance.collection('news').doc(widget.postId).update({
      'videoUrl': FieldValue.delete(),
    });
  }
  // Upload the updated image if available
  if (_imageFile != null) {
    final ref = storage.ref().child('news_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
    final task = ref.putFile(_imageFile!);
    final newImageUrl = await (await task).ref.getDownloadURL();
    await FirebaseFirestore.instance.collection('news').doc(widget.postId).update({
      'imageUrl': newImageUrl,
    });
  }

  // Upload the updated video if available
  if (_videoFile != null) {
    final ref = storage.ref().child('news_videos/${DateTime.now().millisecondsSinceEpoch}.mp4');
    final task = ref.putFile(_videoFile!);
    final newVideoUrl = await (await task).ref.getDownloadURL();
    await FirebaseFirestore.instance.collection('news').doc(widget.postId).update({
      'videoUrl': newVideoUrl,
    });
  }

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Post updated successfully')),
  );
  Navigator.pop(context);
}



  void _submitForm() {
    if (_titleController.text.isNotEmpty &&
        _descriptionController.text.isNotEmpty &&
        ((_imageFile != null && _videoFile == null) ||
            (_imageFile == null && _videoFile != null)) &&
        _selectedCategory != null) {
      _updateData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all the fields')),
      );
    }
  }

  void _deletePost() async {
    // Retrieve the post data
    final postSnapshot =
        await FirebaseFirestore.instance.collection('news').doc(widget.postId).get();

    final imageUrl = postSnapshot['imageUrl'] as String?;
    final videoUrl = postSnapshot['videoUrl'] as String?; // assuming you have this field

    // Delete the image and/or video from Firebase Storage if they exist
    final storage = FirebaseStorage.instance;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      final photoRef = storage.refFromURL(imageUrl);
      await photoRef.delete();
    }
    if (videoUrl != null && videoUrl.isNotEmpty) {
      final videoRef = storage.refFromURL(videoUrl);
      await videoRef.delete();
    }

    // Delete the post from Firestore
    await FirebaseFirestore.instance.collection('news').doc(widget.postId).delete();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Post deleted successfully')),
    );
    Navigator.pop(context);
  }

  Widget _videoPlayerWidget() {
    if (_videoFile != null) {
      final videoPlayerController = VideoPlayerController.file(_videoFile!);
      _editVideoController = ChewieController(
        videoPlayerController: videoPlayerController,
        autoInitialize: true,
        looping: false,
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Text(
              errorMessage,
              style: TextStyle(color: Colors.white),
            ),
          );
        },
      );

      return Container(
        height: 200.0,
        child: Chewie(controller: _editVideoController!),
      );
    } else {
      return Container(); // Return an empty container if _videoFile is null
    }
  }
@override
  void dispose() {
    _videoController?.dispose();
    _editVideoController?.dispose(); // Add this line to dispose of the ChewieController
    super.dispose();
  }
 @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Edit Post',
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
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 8.0),
                _imageFile != null
                    ? Container(
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          image: DecorationImage(
                            image: FileImage(_imageFile!),
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                    : _videoPlayerWidget(),
                SizedBox(height: 16.0),
               ElevatedButton.icon(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.camera_alt),
                          title: const Text('Take a new photo'),
                          onTap: () {
                            _pickImage(ImageSource.camera);
                            Navigator.pop(context);
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.photo_library),
                          title: const Text('Choose from gallery'),
                          onTap: () {
                            _pickImage(ImageSource.gallery);
                            Navigator.pop(context);
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.video_library),
                          title: const Text('Choose a video'),
                          onTap: () {
                            _pickVideo(ImageSource.gallery);
                            Navigator.pop(context);
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
                SizedBox(height: 16.0),
                ElevatedButton(
                    onPressed: _submitForm,
                    child: const Text('Save'),
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
      ),
    );
  }
}

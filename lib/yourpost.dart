import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'editpost.dart';
import 'package:google_fonts/google_fonts.dart';

class YourPostsPage extends StatefulWidget {
  const YourPostsPage({Key? key}) : super(key: key);

  @override
  _YourPostsPageState createState() => _YourPostsPageState();
}

class _YourPostsPageState extends State<YourPostsPage> {
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;
  late List<DocumentSnapshot> _newsList = [];

  @override
  void initState() {
    super.initState();
    _fetchNews();
  }

  Future<void> _fetchNews() async {
    final QuerySnapshot newsSnapshot = await FirebaseFirestore.instance
        .collection('news')
        .where('userId', isEqualTo: _currentUserId)
        .get();
    if(mounted){
    setState(() {
      _newsList = newsSnapshot.docs;
    });
    }
  }

  Future<void> _refreshNews() async {
    await _fetchNews();
  }

  Future<void> _deleteNews(String newsId) async {
    await FirebaseFirestore.instance.collection('news').doc(newsId).delete();
    await _fetchNews();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
    'Post', 
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
        onRefresh: _refreshNews,
        child: _newsList.isEmpty
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(5.0),  // Added Padding
                itemCount: _newsList.length,
                itemBuilder: (context, index) {
                  final newsData =
                      _newsList[index].data()! as Map<String, dynamic>;
                  final newsId = _newsList[index].id;
                  final title = newsData['title'] ?? '';
                  final postedBy = newsData['posted_by'] ?? '';
                  final description = newsData['description'] ?? '';
                  final imageUrl = newsData['imageUrl'] ?? '';
                  final videoUrl = newsData['videoUrl'] ?? '';

                  return Card(
                    elevation: 20.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),  // Rounded edges
                    ),
                    margin: const EdgeInsets.only(bottom: 25),  // Spaced cards
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ListTile(
                          /*leading: CircleAvatar(
                            backgroundImage: NetworkImage(
                              FirebaseAuth.instance.currentUser!.photoURL ??
                                  '',
                            ),
                          ),*/
                          title: Text(
                            postedBy,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16.0,
                            ),
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.close),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: Text('Delete News'),
                                    content: Text(
                                        'Are you sure you want to delete this news?'),
                                    actions: [
                                      TextButton(
                                        child: Text('Cancel'),
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                      TextButton(
                                        child: Text('Delete'),
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                          _deleteNews(newsId);
                                        },
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                        ),
                        if (videoUrl.isNotEmpty)
                          Container(
                            height: 300.0,  // Adjusted height
                            child: VideoPlayerWidget(videoUrl: videoUrl),
                          ),
                        if (imageUrl.isNotEmpty && videoUrl.isEmpty)
                          Container(
                            height: 300.0,  // Adjusted height
                            child: ClipRRect(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(15.0),
                                topRight: Radius.circular(15.0),
                              ),
                              child: Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Center(
                                    child: Icon(Icons.error, color: Colors.red),
                                  );
                                },
                              ),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.all(15.0),
                          child: Text(
                            title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18.0,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 15.0, vertical: 5.0),
                          child: Text(description),
                        ),
                        ButtonBar(  // Adjusted to ButtonBar for alignment
                          alignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                            icon: Icon(Icons.edit, color: Colors.deepPurpleAccent),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditPostPage(postId: newsId),
                                ),
                              );
                            },
                          ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerWidget({Key? key, required this.videoUrl})
      : super(key: key);

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _videoPlayerController;
  late ChewieController _chewieController;

  @override
  void initState() {
    super.initState();
    _videoPlayerController = VideoPlayerController.network(widget.videoUrl);
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      autoInitialize: true,
      looping: true,
      errorBuilder: (context, errorMessage) {
        return Center(
          child: Text(
            errorMessage,
            style: TextStyle(color: Colors.white),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Chewie(
      controller: _chewieController,
    );
  }
}

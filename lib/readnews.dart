import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'nearestnews.dart';
import 'recommendation.dart';
import 'drawer.dart';
import 'package:video_player/video_player.dart';
import 'postnews.dart';
import 'package:chewie/chewie.dart';
import 'comment.dart';
import 'editpost.dart';
import 'notification_manager.dart';
import 'chat.dart';
import 'appbar.dart';
import 'mapview.dart';

class ReadNewsPage extends StatefulWidget {
  const ReadNewsPage({Key? key}) : super(key: key);

  @override
  _ReadNewsPageState createState() => _ReadNewsPageState();
}

class _ReadNewsPageState extends State<ReadNewsPage> {
  List<DocumentSnapshot<Map<String, dynamic>>> _newsList = [];
  bool isAdmin = false;
  final CollectionReference newsCollection =
      FirebaseFirestore.instance.collection('news');

  Map<String, bool> likeStatus = {}; // Map to store like status for each news item
  
  



  @override
void initState() {
  super.initState();


  _checkAdminStatus(); 
  _refreshNews();
  
  

}
Future<void> _initializeNotificationManager() async {
  final notificationManager = NotificationManager();
  await notificationManager.init();
}

void navigatePage(double latitude, double longitude) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => MapViewPage(latitude: latitude, longitude: longitude),
    ),
  );
}



Future<void> _checkAdminStatus() async {
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser != null) {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
    final userData = userDoc.data() as Map<String, dynamic>?;
    if (userData != null && userData.containsKey('statusAdmin')) {
      if (mounted) {
        setState(() {
          isAdmin = userData['statusAdmin'];
        });
      }
    }
  }
}



Future<void> _refreshNews() async {
  QuerySnapshot snapshot =
      await newsCollection.orderBy('timestamp', descending: true).get();
  if (mounted) {
    setState(() {
      _newsList = snapshot.docs.cast<DocumentSnapshot<Map<String, dynamic>>>().toList();

      // Initialize the likeStatus map
      likeStatus = {};
      for (var newsDoc in snapshot.docs) {
        final newsId = newsDoc.id;
        final data = newsDoc.data() as Map<String, dynamic>;
        final likes = data.containsKey('likes') ? data['likes'] : {};

        // Set the like status for the current user
        final currentUser = FirebaseAuth.instance.currentUser;
        final userId = currentUser?.uid ?? '';
        final userLikes = likes != null ? likes[userId] : null;
        likeStatus[newsId] = userLikes != null && userLikes == true;
      }
    });
  }
}


  void toggleLike(String newsId) async {
  final currentUser = FirebaseAuth.instance.currentUser;
  final userId = currentUser?.uid;
  final userLikes = likeStatus[newsId] ?? false;

  DocumentReference newsDocRef = newsCollection.doc(newsId);
  DocumentSnapshot newsDocSnapshot = await newsDocRef.get();
  final newsData = newsDocSnapshot.data() as Map<String, dynamic>;

  if (userLikes) {
    // remove the like
    newsDocRef.update({
      'likes.$userId': FieldValue.delete(),
      'likesCount': FieldValue.increment(-1)
    });

    // remove the category from user
    if(userId != null) removeCategoryFromUser(userId, newsId);
    
    if (mounted) {
      setState(() {
        likeStatus[newsId] = false;
      });
    }

  } else {
    // add the like
    newsDocRef.update({
      'likes.$userId': true,
      'likesCount': FieldValue.increment(1)
    });

    // add the category to user
    if(userId != null) addCategoryToUser(userId, newsId);
    
    if (mounted) {
      setState(() {
        likeStatus[newsId] = true;
      });
    }
  }
}



  Future<void> addCategoryToUser(String userId, String newsId) async {
    final newsDoc = await newsCollection.doc(newsId).get();
    final newsData = newsDoc.data() as Map<String, dynamic>?;

    if (newsData != null) {
      final category = newsData['category'];

      if (category != null) {
        final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
        final categoryData = {
          'liked_categories.$category': FieldValue.increment(1),
        };
        await userRef.update(categoryData);
      }
    }
  }

  Future<void> removeCategoryFromUser(String userId, String newsId) async {
    final newsDoc = await newsCollection.doc(newsId).get();
    final newsData = newsDoc.data() as Map<String, dynamic>?;

    if (newsData != null) {
      final category = newsData['category'];

      if (category != null) {
        final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
        final categoryData = {
          'liked_categories.$category': FieldValue.increment(-1),
        };
        await userRef.update(categoryData);
      }
    }
  }

  bool isLiked(String newsId) {
    return likeStatus.containsKey(newsId) && likeStatus[newsId]!;
  }

  Future<String> _getEmailByUserId(String userId) async {
  final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();

  if (userDoc.exists) {
    final userData = userDoc.data()!;
    return userData['email'] ?? '';
  }

  return '';
}

 @override
Widget build(BuildContext context) {
  final currentUser = FirebaseAuth.instance.currentUser;
  return Scaffold(
   appBar: CustomAppBar(
    onNearYouPressed: () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const NearestNewsPage()),
      );
    },
    onAllNewsPressed: () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ReadNewsPage()),
      );
    },
    onForYouPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const RecommendationPage()),
      );
    },
  ),
    drawer: DrawerContent(currentUser: currentUser),
    body: RefreshIndicator(
      onRefresh: _refreshNews,
      child: ListView.builder(
        padding: const EdgeInsets.all(5.0),
        itemCount: _newsList.length,
        itemBuilder: (context, index) {
          final newsData = _newsList[index].data()! as Map<String, dynamic>;
          final newsId = _newsList[index].id;
          final title = newsData['title'] ?? '';
          final postedBy = newsData['posted_by'] ?? '';
          final description = newsData['description'] ?? '';
          final imageUrl = newsData['imageUrl'] ?? '';
          final videoUrl = newsData['videoUrl'] ?? '';
          final likeCounter = newsData['likesCount'] ?? 0;

          return FutureBuilder<String>(
           future: isAdmin ? _getEmailByUserId(newsData['userId']) : Future.value(''),
           builder: (context, snapshot) {
          final email = snapshot.data ?? '';
          
             return Card(
  elevation: 20.0,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(30),
  ),
  margin: const EdgeInsets.only(bottom: 25),
  child: Stack(
    children: [
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            title: Text(
              isAdmin && email.isNotEmpty ? '$postedBy ($email)' : postedBy,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
            ),
          ),
          if (videoUrl.isNotEmpty)
            Container(
              height: 300.0,
              child: VideoPlayerWidget(videoUrl: videoUrl),
            ),
          if (imageUrl.isNotEmpty && videoUrl.isEmpty)
            Container(
              height: 300.0,
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(15.0),
                  topRight: Radius.circular(15.0),
                ),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(child: Icon(Icons.error, color: Colors.red));
                  },
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Text(
              title,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 5.0),
            child: Text(description),
          ),
          ButtonBar(
            alignment: MainAxisAlignment.start,
            children: [
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CommentPage(newsId: newsId),
                    ),
                  );
                },
                icon: Icon(Icons.comment, color: Colors.deepPurpleAccent),
                label: Text('Comment', style: TextStyle(color: Colors.deepPurpleAccent)),
              ),
/*
              TextButton.icon(
               onPressed: () => toggleLike(newsId),
                icon: Icon(
                isLiked(newsId) ? Icons.favorite : Icons.favorite_border,
                 color: isLiked(newsId) ? Colors.red : Colors.deepPurpleAccent,
               ),
              label: Row(
              children: [
               Text(
                 isLiked(newsId) ? 'Liked' : 'Like',
                 style: TextStyle(color: isLiked(newsId) ? Colors.red : Colors.deepPurpleAccent),
                 ),
                  SizedBox(width: 5.0), // some spacing
                     Text(likeCounter.toString(), style: TextStyle(color: Colors.deepPurpleAccent)), // display the likeCounter
    ],
  ),
),*/

              TextButton.icon(
                onPressed: () => toggleLike(newsId),
                icon: Icon(
                  isLiked(newsId) ? Icons.favorite : Icons.favorite_border,
                  color: isLiked(newsId) ? Colors.red : Colors.deepPurpleAccent,
                ),
                label: Text(
                  isLiked(newsId) ? 'Liked' : 'Like',
                  style: TextStyle(color: isLiked(newsId) ? Colors.red : Colors.deepPurpleAccent),
                ),
              ),
              if (currentUser?.uid != newsData['userId'])
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatPage(peerUserId: newsData['userId']),
                      ),
                    );
                  },
                  icon: Icon(Icons.chat, color: Colors.deepPurpleAccent),
                  label: Text('Chat', style: TextStyle(color: Colors.deepPurpleAccent)),
                ),
              if (isAdmin)
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
      Positioned(
        top: 10.0,
        right: 10.0,
        child: IconButton(
          icon: Icon(IconData(0xe3c8, fontFamily: 'MaterialIcons')),
          onPressed: () {
            final latitude = newsData['latitude'];
            final longitude = newsData['longitude'];
            navigatePage(latitude, longitude);
          },
        ),
      ),
    ],
  ),
);

              //);
            },
          );
        },
      ),
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PostNewsPage()),
        );
      },
      child: const Icon(Icons.add),
      backgroundColor: Colors.deepPurpleAccent,
    ),
  );
}

}

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerWidget({Key? key, required this.videoUrl}) : super(key: key);

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

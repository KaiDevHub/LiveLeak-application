import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'postnews.dart'; 
import 'comment.dart';
import 'drawer.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:provider/provider.dart';
import 'top_categories_model.dart';
import 'appbar.dart';
import 'editpost.dart';
import 'chat.dart';
import 'nearestnews.dart';
import 'readnews.dart';
import 'mapview.dart';


class RecommendationPage extends StatefulWidget {
  const RecommendationPage({Key? key}) : super(key: key);

  @override
  _RecommendationPageState createState() => _RecommendationPageState();
}

class _RecommendationPageState extends State<RecommendationPage> {
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _newsList = [];
  bool isAdmin = false;
  final CollectionReference newsCollection =
      FirebaseFirestore.instance.collection('news');

  Map<String, bool> likeStatus = {}; // Map to store like status for each news item

  @override
  void initState() {
    super.initState();
    
     _checkAdminStatus(); 
    _fetchRecommendations(); // Fetch the news based on user's top 3 categories
  }
Future<void> _refreshNews() async {
  // This will refresh the news list based on user's top categories.
  await _fetchRecommendations();
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

  Future<void> _fetchRecommendations() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final userId = currentUser?.uid;
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();

    final userCategoryData =
        userDoc.data()?['liked_categories'] as Map<String, dynamic>?;

    if (userCategoryData != null) {
      final topCategories = userCategoryData.keys.toList()
        ..sort((a, b) => userCategoryData[b].compareTo(userCategoryData[a]));

      // Get the top 3 categories based on the highest counter value
      final top3Categories = topCategories.take(3).toList();
      final topCategoriesModel = Provider.of<TopCategoriesModel>(context, listen: false);
      topCategoriesModel.updateCategories(top3Categories);

      final List<QuerySnapshot<Map<String, dynamic>>> categorySnapshots =
          await Future.wait(top3Categories.map(
        (category) => newsCollection
            .where('category', isEqualTo: category)
            .orderBy('timestamp', descending: true)
            .limit(5)
            .get() as Future<QuerySnapshot<Map<String, dynamic>>>,
      ));
      if(mounted){
      setState(() {
        _newsList = categorySnapshots.expand((snapshot) => snapshot.docs).toList();

        // Initialize the likeStatus map
        likeStatus = {};
        for (var newsDoc in _newsList) {
          final newsId = newsDoc.id;
          final data = newsDoc.data()! as Map<String, dynamic>;
          final likes = data.containsKey('likes') ? data['likes'] : {};

          // Set the like status for the current user
          final userLikes = likes != null ? likes[userId] : null;
          likeStatus[newsId] = userLikes != null && userLikes == true;
        }
      });
      }
    }
  }

  void toggleLike(String newsId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final userId = currentUser?.uid;
    final userLikes = likeStatus[newsId] ?? false;

    // Check if the current user already liked the news
    if (userLikes) {
      // Remove the like from Firestore and local state
      await newsCollection.doc(newsId).update({
        'like_counter': FieldValue.increment(-1),
        'likes.$userId': FieldValue.delete(),
      });
      
      setState(() {
        likeStatus[newsId] = false;
      });
      

      // Remove the news category from the user's categories collection
      await removeCategoryFromUser(userId!, newsId); // assert userId is not null
    } else {
      // Add the like to Firestore and local state
      await newsCollection.doc(newsId).update({
        'like_counter': FieldValue.increment(1),
        'likes.$userId': true,
      });
      
      setState(() {
        likeStatus[newsId] = true;
      });
      

      // Add the news category to the user's categories collection
      await addCategoryToUser(userId!, newsId); // assert userId is not null
    }
  }

  Future<void> addCategoryToUser(String userId, String newsId) async {
    final newsDoc = await newsCollection.doc(newsId).get();
    final newsData = newsDoc.data()! as Map<String, dynamic>?; 

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
    final newsData = newsDoc.data()! as Map<String, dynamic>?;

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

  void navigatePage(double latitude, double longitude) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => MapViewPage(latitude: latitude, longitude: longitude),
    ),
  );
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

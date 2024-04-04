import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' show cos, sqrt, asin;
import 'readnews.dart';
import 'searchuser.dart';
import 'recommendation.dart';
import 'drawer.dart';
import 'package:video_player/video_player.dart';
import 'postnews.dart';
import 'package:chewie/chewie.dart';
import 'comment.dart';
import 'appbar.dart';
import 'editpost.dart';
import 'chat.dart';
import 'mapview.dart';

class NearestNewsPage extends StatefulWidget {
  const NearestNewsPage({Key? key}) : super(key: key);

  @override
  _NearestNewsPageState createState() => _NearestNewsPageState();
}

class _NearestNewsPageState extends State<NearestNewsPage> {
  List<DocumentSnapshot> _newsList = [];
    bool isAdmin = false;
  final CollectionReference newsCollection =
      FirebaseFirestore.instance.collection('news');

  Position? _currentPosition;
  Map<String, bool> likeStatus = {}; // Map to store like status for each news item

  @override
  void initState() {
    super.initState();
    _checkAdminStatus(); 
    _getCurrentLocation();
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


  Future<void> _getCurrentLocation() async {
    final geolocator = GeolocatorPlatform.instance;
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }
    permission = await geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        return Future.error(
            'Location permissions are denied (actual value: $permission).');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }
    final position = await geolocator.getCurrentPosition();
    if (mounted) {
      setState(() {
        _currentPosition = position;
        _refreshNews();
      });
    }
  }

  @override
  void didUpdateWidget(covariant NearestNewsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _refreshNews(); // Automatically refresh when the user goes to the page
  }

  Future<void> _refreshNews() async {
  if (_currentPosition != null) {
    final QuerySnapshot snapshot = await newsCollection
        .orderBy('timestamp', descending: true)
        .get();
    final List<DocumentSnapshot> newsList = snapshot.docs;

    // Calculate distances and filter news based on distance
    final List<DocumentSnapshot> filteredNewsList = [];
    for (final news in newsList) {
      final newsData = news.data()! as Map<String, dynamic>;
      final latitude = newsData['latitude'] ?? 0.0;
      final longitude = newsData['longitude'] ?? 0.0;
      final distance = _calculateDistance(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        latitude,
        longitude,
      );
      if (distance <= 10) {
        filteredNewsList.add(news);
      }
    }

    // Sort the filtered news items based on their distance
    filteredNewsList.sort((a, b) {
      final newsDataA = a.data()! as Map<String, dynamic>;
      final newsDataB = b.data()! as Map<String, dynamic>;
      final latitudeA = newsDataA['latitude'] ?? 0.0;
      final longitudeA = newsDataA['longitude'] ?? 0.0;
      final latitudeB = newsDataB['latitude'] ?? 0.0;
      final longitudeB = newsDataB['longitude'] ?? 0.0;

      final distanceA = _calculateDistance(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        latitudeA,
        longitudeA,
      );

      final distanceB = _calculateDistance(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        latitudeB,
        longitudeB,
      );

      // Compare distances to sort from nearest to farthest
      return distanceA.compareTo(distanceB);
    });
    if(mounted) {
    setState(() {
      _newsList = filteredNewsList;

      // Initialize the likeStatus map
      likeStatus = {};
      for (var newsDoc in _newsList) {
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
}


  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const p = 0.017453292519943295;
    const c = cos;
    final a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
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

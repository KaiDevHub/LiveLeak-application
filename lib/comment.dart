import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class CommentPage extends StatefulWidget {
  final String newsId;

  const CommentPage({Key? key, required this.newsId}) : super(key: key);

  @override
  _CommentPageState createState() => _CommentPageState();
}

class _CommentPageState extends State<CommentPage> {
  final TextEditingController _commentController = TextEditingController();
   final CollectionReference newsCollection = FirebaseFirestore.instance.collection('news');

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

  void _postComment() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final userId = currentUser?.uid;
    String username = 'Anonymous'; // Default value

    if (userId != null) {
      final userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userSnapshot.exists) {
        username = userSnapshot.data()?['username'] ?? 'Anonymous';
      }
    }

    final commentText = _commentController.text.trim();

    if (commentText.isNotEmpty) {
      final commentData = {
        'username': username,
        'comment': commentText,
        'timestamp': FieldValue.serverTimestamp(),
        'userId': userId, // Add the userId to the comment data
      };

      await FirebaseFirestore.instance
          .collection('news')
          .doc(widget.newsId)
          .collection('comments')
          .add(commentData);

      if (userId != null) {
        await addCategoryToUser(userId, widget.newsId);
      }

      if (mounted){
        setState(() {
          _commentController.clear();
        });
      }
    }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
       appBar: AppBar(
        title: Text(
          'Comments',
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
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('news')
                  .doc(widget.newsId)
                  .collection('comments')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final comments = snapshot.data?.docs;

                if (comments == null || comments.isEmpty) {
                  return Center(
                    child: Text('No comments yet.'),
                  );
                }

                return ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final commentData =
                        comments[index].data() as Map<String, dynamic>;
                    final username = commentData['username'] ?? 'Anonymous';
                    final comment = commentData['comment'] ?? '';
                    final timestamp =
                        commentData['timestamp'] as Timestamp?;
                    final commentId = comments[index].id;
                    final isCurrentUserComment =
                        FirebaseAuth.instance.currentUser?.uid ==
                            commentData['userId'];

                    return LongPressPopupMenu(
                      commentId: commentId,
                      isCurrentUserComment: isCurrentUserComment,
                      onDelete: () => _deleteComment(commentId),
                      child: ListTile(
                        leading: Icon(Icons.account_circle),
                        title: Text(username),
                        subtitle: Text(comment),
                        trailing: Text(
                          timestamp != null ? _formatTimestamp(timestamp) : '',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(hintText: 'Write a comment...'),
                  ),
                ),
                IconButton(
                  onPressed: _postComment,
                  icon: Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    final time = TimeOfDay.fromDateTime(date).format(context);
    final formattedDate = '${date.day}/${date.month}/${date.year}';
    return '$time - $formattedDate';
  }

  void _deleteComment(String commentId) async {
    final commentDoc = await FirebaseFirestore.instance
        .collection('news')
        .doc(widget.newsId)
        .collection('comments')
        .doc(commentId)
        .get();

    if (commentDoc.exists) {
        final userId = commentDoc.data()?['userId'] as String?;

        // Delete the comment
        await FirebaseFirestore.instance
            .collection('news')
            .doc(widget.newsId)
            .collection('comments')
            .doc(commentId)
            .delete();

        // Decrease the counter if userId exists
        if (userId != null) {
            await removeCategoryFromUser(userId, widget.newsId);
        }
    }
}

}

class LongPressPopupMenu extends StatelessWidget {
  final String commentId;
  final bool isCurrentUserComment;
  final VoidCallback onDelete;
  final Widget child;

  LongPressPopupMenu({
    required this.commentId,
    required this.isCurrentUserComment,
    required this.onDelete,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        final actions = <PopupMenuEntry>[
          if (isCurrentUserComment)
            PopupMenuItem(
              key: Key(commentId), // Unique key based on commentId
              child: Text('Delete'),
              onTap: onDelete,
            ),
        ];

        showMenu(
          context: context,
          position: RelativeRect.fromLTRB(0, 0, 0, 0),
          items: actions,
        );
      },
      child: child,
    );
  }
}

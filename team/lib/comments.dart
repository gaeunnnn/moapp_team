import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommentsPage extends StatefulWidget {
  final String projectId;
  final String boardId;

  CommentsPage({required this.projectId, required this.boardId});

  @override
  _CommentsPageState createState() => _CommentsPageState();
}

class _CommentsPageState extends State<CommentsPage> {
  final _commentController = TextEditingController();
  final User? currentUser = FirebaseAuth.instance.currentUser;
  Map<String, dynamic> boardContent = {};
  String commentName = '';
  String authorName = '';
  String profileImageUrl = '';

  @override
  void initState() {
    super.initState();
    _fetchBoardContent();
  }

  Future<void> _fetchBoardContent() async {
    final boardDoc = await FirebaseFirestore.instance
        .collection('projects')
        .doc(widget.projectId)
        .collection('board')
        .doc(widget.boardId)
        .get();

    if (boardDoc.exists) {
      final authorUID = boardDoc['author'];
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(authorUID)
          .get();

      authorName = userDoc.exists ? userDoc['name'] : 'Unknown';
      profileImageUrl = userDoc.exists ? userDoc['profileImageUrl'] : null;

      setState(() {
        boardContent = {
          'content': boardDoc['content'],
          'author_name': authorName,
          'author': boardDoc['author'],
          'profileImageUrl': profileImageUrl,
          'imageUrl': boardDoc['imageUrl']
        };
      });
    }
  }

  Future<void> _addComment() async {
    if (_commentController.text.isNotEmpty) {
      final comment = {
        'content': _commentController.text,
        'author': currentUser!.uid,
        'profileImageUrl': profileImageUrl,
        'createdAt': FieldValue.serverTimestamp(),
      };
      await FirebaseFirestore.instance
          .collection('projects')
          .doc(widget.projectId)
          .collection('board')
          .doc(widget.boardId)
          .collection('comments')
          .add(comment);

      _commentController.clear();
    }
  }

  Future<void> _deleteComment(String commentId) async {
    await FirebaseFirestore.instance
        .collection('projects')
        .doc(widget.projectId)
        .collection('board')
        .doc(widget.boardId)
        .collection('comments')
        .doc(commentId)
        .delete();
  }

  Future<Map<String, dynamic>> _fetchAuthorInfo(String uid) async {
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();

    if (userDoc.exists) {
      return {
        'name': userDoc['name'],
        'profileImageUrl': userDoc['profileImageUrl'],
      };
    } else {
      return {
        'name': 'Unknown',
        'profileImageUrl': null,
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('댓글'),
      ),
      body: Column(
        children: [
          if (boardContent.isNotEmpty)
            Card(
              color: Colors.white,
              margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Divider(color: Colors.grey),
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundImage: NetworkImage(profileImageUrl),
                        ),
                        SizedBox(width: 10),
                        Text(
                          boardContent['author_name'] ?? 'Unknown',
                          style: TextStyle(fontSize: 16),
                        ),
                        Spacer(),
                      ],
                    ),
                    Divider(color: Colors.grey),
                    SizedBox(height: 10),
                    Text(
                      boardContent['content'],
                      style: TextStyle(fontSize: 14),
                    ),
                    SizedBox(height: 10),
                    if (boardContent['imageUrl'] != null)
                      Image.network(boardContent['imageUrl'],
                          width: 500, height: 250, fit: BoxFit.fill),
                    SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('projects')
                  .doc(widget.projectId)
                  .collection('board')
                  .doc(widget.boardId)
                  .collection('comments')
                  .orderBy('createdAt', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final comments = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    final commentData = comment.data() as Map<String, dynamic>;

                    return FutureBuilder<Map<String, dynamic>>(
                      future: _fetchAuthorInfo(commentData['author']),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return CircularProgressIndicator();
                        }

                        final authorInfo = snapshot.data!;
                        final commentName = authorInfo['name'];
                        final profileImageUrl = authorInfo['profileImageUrl'];

                        return Container(
                          margin: const EdgeInsets.symmetric(
                              vertical: 4.0, horizontal: 8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipOval(
                                child: profileImageUrl != null
                                    ? Image.network(
                                        profileImageUrl,
                                        width: 40,
                                        height: 40,
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: Colors.grey,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.person,
                                          size: 20,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      commentName,
                                      style: TextStyle(
                                          fontSize: 12, color: Colors.grey),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(10.0),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius:
                                            BorderRadius.circular(10.0),
                                      ),
                                      child: Text(commentData['content']),
                                    ),
                                  ],
                                ),
                              ),
                              if (currentUser!.uid == commentData['author'])
                                IconButton(
                                  icon: Icon(Icons.delete),
                                  onPressed: () {
                                    _deleteComment(comment.id);
                                  },
                                ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: '댓글을 입력하세요',
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _addComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

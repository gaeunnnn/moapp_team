import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:team/editBoard.dart';
import 'package:team/addBoard.dart';
import 'comments.dart';

class BoardPage extends StatefulWidget {
  final String projectId;

  const BoardPage({Key? key, required this.projectId}) : super(key: key);
  @override
  _BoardPageState createState() => _BoardPageState();
}

class _BoardPageState extends State<BoardPage> {
  late String projectId = widget.projectId;
  List<Map<String, dynamic>> _boards = [];
  final User? currentUser = FirebaseAuth.instance.currentUser;
  int _selectedIndex = 3;

  void _onItemTapped(int index) {
    switch (index) {
      case 0:
        Navigator.pop(context);
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/detail',
            arguments: widget.projectId);
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/calendar',
            arguments: widget.projectId);
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/board',
            arguments: widget.projectId);
        break;
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchBoards();
  }

  Future<void> _fetchBoards() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .collection('board')
          .orderBy('createdAt', descending: true)
          .get();

      final List<Map<String, dynamic>> boards = [];

      for (var doc in querySnapshot.docs) {
        final authorUID = doc['author'];
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(authorUID)
            .get();

        final authorName = userDoc.exists ? userDoc['name'] : 'Unknown';
        final profileImageUrl =
            userDoc.exists ? userDoc['profileImageUrl'] : null;
        final createdAt = doc['createdAt'];
        String createdAtStr;
        if (createdAt is Timestamp) {
          createdAtStr = createdAt.toDate().toString();
        } else if (createdAt is String) {
          createdAtStr = createdAt;
        } else {
          createdAtStr = '';
        }

        boards.add({
          'content': doc['content'],
          'id': doc.id,
          'author': doc['author'],
          'author_name': authorName,
          'authorProfileImageUrl': profileImageUrl,
          'imageUrl': doc['imageUrl'],
          'createdAt': createdAtStr,
          'location': doc['location'],
          'address': doc['address'],
        });
      }

      setState(() {
        _boards = boards;
      });
    } catch (e) {
      print('Error fetching boards: $e');
    }
  }

  void _deleteBoard(int index) async {
    if (_boards[index]['author'] == currentUser!.uid) {
      await FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .collection('board')
          .doc(_boards[index]['id'])
          .delete();

      setState(() {
        _boards.removeAt(index);
      });
    }
  }

  void _navigateToAddBoardPage(BuildContext context, [int? index]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddBoardPage(
          board: index != null ? _boards[index] : null,
          projectId: projectId,
        ),
      ),
    );

    if (result != null) {
      await _fetchBoards();
    }
  }

  void _navigateToEditBoardPage(BuildContext context, int index) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditBoardPage(
          board: _boards[index],
          projectId: projectId,
          boardId: _boards[index]['id'],
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _boards[index] = result;
      });
    }
  }

  void _navigateToCommentsPage(BuildContext context, String? boardId) async {
    if (boardId != null) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CommentsPage(
            projectId: projectId,
            boardId: boardId,
          ),
        ),
      );
    } else {
      print('Error: Board ID is null');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('게시판'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => _navigateToAddBoardPage(context),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _boards.length,
        itemBuilder: (context, index) {
          return Card(
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
                      ClipOval(
                        child: _boards[index]['authorProfileImageUrl'] != null
                            ? Image.network(
                                _boards[index]['authorProfileImageUrl'],
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
                      Text(
                        _boards[index]['author_name'] ?? 'Unknown',
                        style: TextStyle(fontSize: 16),
                      ),
                      Spacer(),
                      if (_boards[index]['author'] == currentUser!.uid)
                        PopupMenuButton<String>(
                          color: Colors.white,
                          onSelected: (String result) {
                            if (result == 'edit') {
                              _navigateToEditBoardPage(context, index);
                            } else if (result == 'delete') {
                              _deleteBoard(index);
                            }
                          },
                          itemBuilder: (BuildContext context) =>
                              <PopupMenuEntry<String>>[
                            const PopupMenuItem<String>(
                              value: 'edit',
                              child: Text('편집'),
                            ),
                            const PopupMenuItem<String>(
                              value: 'delete',
                              child: Text('삭제'),
                            ),
                          ],
                        ),
                    ],
                  ),
                  Divider(color: Colors.grey),
                  SizedBox(height: 10),
                  Text(
                    _boards[index]['content'],
                    style: TextStyle(fontSize: 14),
                  ),
                  SizedBox(height: 10),
                  if (_boards[index]['imageUrl'] != null)
                    Image.network(_boards[index]['imageUrl'],
                        width: 500, height: 250, fit: BoxFit.fill),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.comment),
                        onPressed: () {
                          final boardId = _boards[index]['id'];
                          _navigateToCommentsPage(context, boardId);
                        },
                      ),
                      TextButton(
                        child: Text(
                          "댓글 달기",
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                        onPressed: () {
                          final boardId = _boards[index]['id'];
                          _navigateToCommentsPage(context, boardId);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Detail',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.forum),
            label: 'Board',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        onTap: _onItemTapped,
      ),
    );
  }
}

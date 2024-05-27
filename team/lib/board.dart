import 'package:flutter/material.dart';
import 'addBoard.dart';

class BoardPage extends StatefulWidget {
  @override
  _BoardPageState createState() => _BoardPageState();
}

class _BoardPageState extends State<BoardPage> {
  List<Map<String, String>> _boards = [];

  void _addBoard(Map<String, String> board) {
    setState(() {
      _boards.add(board);
    });
  }

  int _selectedIndex = 2;

  void _onItemTapped(int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/calendar');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/board');
        break;
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  void _editBoard(int index, Map<String, String> board) {
    setState(() {
      _boards[index] = board;
    });
  }

  void _deleteBoard(int index) {
    setState(() {
      _boards.removeAt(index);
    });
  }

  void _navigateToAddBoardPage(BuildContext context, [int? index]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddBoardPage(
          board: index != null ? _boards[index] : null,
        ),
      ),
    );

    if (result != null) {
      if (index == null) {
        _addBoard(result);
      } else {
        _editBoard(index, result);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('게시판'),
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
                      CircleAvatar(
                        backgroundImage: AssetImage('assets/avatar.png'),
                        radius: 20,
                      ),
                      SizedBox(width: 10),
                      Text(
                        '장가은학부생',
                        style: TextStyle(fontSize: 16),
                      ),
                      Spacer(),
                      PopupMenuButton<String>(
                        onSelected: (String result) {
                          if (result == 'edit') {
                            _navigateToAddBoardPage(context, index);
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
                    _boards[index]['content']!,
                    style: TextStyle(fontSize: 14),
                  ),
                  SizedBox(height: 10),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bubble_chart),
            label: 'Board',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.black,
        onTap: _onItemTapped,
      ),
    );
  }
}

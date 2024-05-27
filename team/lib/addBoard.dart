import 'package:flutter/material.dart';

class AddBoardPage extends StatefulWidget {
  final Map<String, String>? board;

  AddBoardPage({this.board});

  @override
  _AddBoardPageState createState() => _AddBoardPageState();
}

class _AddBoardPageState extends State<AddBoardPage> {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.board != null) {
      _contentController.text = widget.board!['content']!;
    }
  }

  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  void _saveBoard() {
    if (_formKey.currentState!.validate()) {
      final board = {
        'content': _contentController.text,
      };
      Navigator.pop(context, board);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text('게시글 생성'),
        actions: [
          TextButton(
            onPressed: _saveBoard,
            child: Text(
              '생성하기',
              style: TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Divider(color: Colors.grey),
              Row(
                children: [
                  CircleAvatar(
                    backgroundImage:
                        AssetImage('assets/avatar.png'), // 이미지 경로 설정
                    radius: 20,
                  ),
                  SizedBox(width: 10),
                  Text(
                    '장가은학부생', // 사용자 이름
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
              Divider(color: Colors.grey),
              SizedBox(height: 20),
              TextFormField(
                controller: _contentController,
                decoration: InputDecoration(
                  hintText: '글 내용을 입력해주세요.',
                ),
                maxLines: 10,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '내용을 입력해주세요';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: Icon(Icons.camera),
              ),
            ],
          ),
        ),
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
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        onTap: _onItemTapped,
      ),
    );
  }
}

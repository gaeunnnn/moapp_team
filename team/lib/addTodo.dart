import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'event.dart';

class AddTodoPage extends StatefulWidget {
  final String projectId;
  final DateTime selectedDate;

  const AddTodoPage(
      {Key? key, required this.projectId, required this.selectedDate})
      : super(key: key);

  @override
  _AddTodoPageState createState() => _AddTodoPageState();
}

class _AddTodoPageState extends State<AddTodoPage> {
  final _controller = TextEditingController();
  String _type = '개인';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('일정 추가'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: '*일정 이름',
                suffixIcon: IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () => _controller.clear(),
                ),
              ),
            ),
            SizedBox(height: 16.0),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '*유형',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 8.0),
            Row(
              children: [
                _buildTypeOption('개인', Colors.purple),
                SizedBox(width: 16.0),
                _buildTypeOption('공동', Colors.green),
              ],
            ),
            Spacer(),
            ElevatedButton(
              onPressed: _addTodo,
              child: Text('생성'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeOption(String type, Color color) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _type = type;
        });
      },
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.rectangle,
              border: Border.all(
                color: _type == type ? color : Colors.grey,
                width: 2,
              ),
              color:
                  _type == type ? color.withOpacity(0.2) : Colors.transparent,
            ),
            width: 24,
            height: 24,
            child: _type == type
                ? Icon(Icons.check, size: 16.0, color: color)
                : null,
          ),
          SizedBox(width: 8.0),
          Text(
            type,
            style: TextStyle(
              color: _type == type ? color : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addTodo() async {
    if (_controller.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('일정 이름을 입력하세요')),
      );
      return;
    }

    final todoCollectionRef = FirebaseFirestore.instance
        .collection('projects')
        .doc(widget.projectId)
        .collection('todolists');

    User? currentUser = FirebaseAuth.instance.currentUser;
    Map<String, dynamic> todoData = {
      'title': _controller.text,
      'date': Timestamp.fromDate(DateTime(widget.selectedDate.year,
          widget.selectedDate.month, widget.selectedDate.day)),
      'type': _type,
      'isDone': false,
    };

    if (_type == '개인' && currentUser != null) {
      todoData['teamMember1'] = currentUser.uid;
    } else if (_type == '공동') {
      final projectRef = FirebaseFirestore.instance
          .collection('projects')
          .doc(widget.projectId);
      final projectSnapshot = await projectRef.get();
      if (projectSnapshot.exists) {
        Map<String, dynamic> projectData =
            projectSnapshot.data() as Map<String, dynamic>;
        int membersCount = projectData['members'];
        for (int i = 1; i <= membersCount; i++) {
          String teamMemberField = 'teamMember$i';
          if (projectData.containsKey(teamMemberField)) {
            todoData[teamMemberField] = projectData[teamMemberField];
          }
        }
      }
    }

    try {
      await todoCollectionRef.doc(_controller.text).set(todoData);
      print('Todo successfully added to Firestore');
      Navigator.pop(context, true);
    } catch (e) {
      print('Failed to add todo: $e');
    }
  }
}

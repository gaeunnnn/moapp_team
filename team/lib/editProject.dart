import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'numberInc.dart'; // 위젯 파일을 임포트합니다
import 'project.dart';

class EditProjectPage extends StatefulWidget {
  final Project project;
  final ValueChanged<Project> onSave;

  const EditProjectPage({
    Key? key,
    required this.project,
    required this.onSave,
  }) : super(key: key);

  @override
  _EditProjectPageState createState() => _EditProjectPageState();
}

class _EditProjectPageState extends State<EditProjectPage> {
  final TextEditingController _projectNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  int _members = 1;

  @override
  void initState() {
    super.initState();
    _projectNameController.text = widget.project.title;
    _descriptionController.text = widget.project.description;
    _startDate =
        DateFormat('yyyy-MM-dd').parse(widget.project.duration.split(' ~ ')[0]);
    _endDate =
        DateFormat('yyyy-MM-dd').parse(widget.project.duration.split(' ~ ')[1]);
    _members = widget.project.members;
  }

  @override
  void dispose() {
    _projectNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart
          ? (_startDate ?? DateTime.now())
          : (_endDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != (isStart ? _startDate : _endDate)) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _updateProject() async {
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      DateTime now = DateTime.now();
      double progress = 0.0;

      if (_startDate != null &&
          _endDate != null &&
          _startDate!.isBefore(_endDate!)) {
        int totalDays = _endDate!.difference(_startDate!).inDays;
        int elapsedDays = now.difference(_startDate!).inDays;
        progress = (elapsedDays / totalDays).clamp(0.0, 1.0);
      }

      final updatedProject = {
        'title': _projectNameController.text,
        'startDate': _startDate != null
            ? DateFormat('yyyy-MM-dd').format(_startDate!)
            : '',
        'endDate':
            _endDate != null ? DateFormat('yyyy-MM-dd').format(_endDate!) : '',
        'members': _members,
        'description': _descriptionController.text,
        'progress': progress,
        'isCompleted': progress != 1.0 ? false : true,
      };

      await FirebaseFirestore.instance
          .collection('projects')
          .doc(widget.project.id)
          .update(updatedProject);

      Map<String, String?> teamMembers = {};
      for (int i = 1; i <= _members; i++) {
        String teamMemberField = 'teamMember$i';
        teamMembers[teamMemberField] =
            widget.project.teamMembers[teamMemberField];
      }

      Project editedProject = Project(
        id: widget.project.id,
        leaderUid: widget.project.leaderUid,
        title: _projectNameController.text,
        duration:
            '${_startDate != null ? DateFormat('yyyy-MM-dd').format(_startDate!) : ''} ~ ${_endDate != null ? DateFormat('yyyy-MM-dd').format(_endDate!) : ''}',
        members: _members,
        description: _descriptionController.text,
        progress: progress,
        isCompleted: progress != 1.0 ? false : true,
        teamMembers: teamMembers,
      );

      widget.onSave(editedProject);
      Navigator.of(context).pop();
    } else {
      print('사용자가 로그인하지 않았습니다.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('프로젝트 수정'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '프로젝트 수정',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            Text(
              '*프로젝트 이름',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextField(
              controller: _projectNameController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(vertical: 10, horizontal: 10),
              ),
            ),
            SizedBox(height: 20),
            Text(
              '*시작 날짜',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextField(
              readOnly: true,
              decoration: InputDecoration(
                hintText: _startDate != null
                    ? DateFormat('yyyy-MM-dd').format(_startDate!)
                    : '날짜를 선택하세요',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(vertical: 10, horizontal: 10),
              ),
              onTap: () => _selectDate(context, true),
            ),
            SizedBox(height: 20),
            Text(
              '*마감 날짜',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextField(
              readOnly: true,
              decoration: InputDecoration(
                hintText: _endDate != null
                    ? DateFormat('yyyy-MM-dd').format(_endDate!)
                    : '날짜를 선택하세요',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(vertical: 10, horizontal: 10),
              ),
              onTap: () => _selectDate(context, false),
            ),
            SizedBox(height: 20),
            Text(
              '*인원',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            NumberInputWithIncrementDecrement(
              minValue: 1,
              maxValue: 100,
              initialValue: _members,
              onChanged: (value) {
                setState(() {
                  _members = value;
                });
              },
            ),
            SizedBox(height: 20),
            Text(
              '상세 설명',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextField(
              controller: _descriptionController,
              maxLines: 5,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(vertical: 10, horizontal: 10),
              ),
            ),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _updateProject,
                child: Text('수정'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

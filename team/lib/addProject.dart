import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

class AddProjectPage extends StatefulWidget {
  @override
  _AddProjectPageState createState() => _AddProjectPageState();
}

class _AddProjectPageState extends State<AddProjectPage> {
  final TextEditingController _projectNameController = TextEditingController();
  final TextEditingController _membersController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  String _qrData = '';

  @override
  void dispose() {
    _projectNameController.dispose();
    _membersController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
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

  String generateRandomCode(int length) {
    const String _chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random _rnd = Random();
    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length)),
      ),
    );
  }

  Future<void> _addProject() async {
    String projectCode = generateRandomCode(4);
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

      final project = {
        'leaderUid': currentUser.uid,
        'title': _projectNameController.text,
        'startDate': _startDate != null
            ? DateFormat('yyyy-MM-dd').format(_startDate!)
            : '',
        'endDate':
            _endDate != null ? DateFormat('yyyy-MM-dd').format(_endDate!) : '',
        'members': int.tryParse(_membersController.text) ?? 1,
        'teamMember1': currentUser.uid,
        'description': _descriptionController.text,
        'progress': progress,
        'isCompleted': progress != 1.0 ? false : true,
      };

      await FirebaseFirestore.instance
          .collection('projects')
          .doc(projectCode)
          .set(project);

      // Create an empty todolists collection for the new project
      await FirebaseFirestore.instance
          .collection('projects')
          .doc(projectCode)
          .collection('todolists')
          .add({'initialized': true});

      setState(() {
        _qrData =
            '프로젝트 코드: $projectCode\n프로젝트 이름: ${_projectNameController.text}\n시작 날짜: ${_startDate != null ? DateFormat('yyyy-MM-dd').format(_startDate!) : ''}\n마감 날짜: ${_endDate != null ? DateFormat('yyyy-MM-dd').format(_endDate!) : ''}\n인원: ${_membersController.text}\n상세 설명: ${_descriptionController.text}';
      });
    } else {
      print('사용자가 로그인하지 않았습니다.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('프로젝트 생성'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '팀 프로젝트 생성',
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
            TextField(
              controller: _membersController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(vertical: 10, horizontal: 10),
              ),
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
                onPressed: _addProject,
                child: Text('+ 생성'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                ),
              ),
            ),
            SizedBox(height: 20),
            if (_qrData.isNotEmpty)
              Column(
                children: [
                  Center(
                    child: QrImageView(
                      data: _qrData,
                      backgroundColor: Colors.white,
                      size: 200,
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/');
                    },
                    child: Text('완성'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: IconButton(
          icon: Icon(Icons.home),
          onPressed: () {
            Navigator.pushNamed(context, '/');
          },
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import 'numberInc.dart'; // 위젯 파일을 임포트합니다
import 'QRPage.dart'; // QR 코드 페이지를 임포트합니다

class AddProjectPage extends StatefulWidget {
  @override
  _AddProjectPageState createState() => _AddProjectPageState();
}

class _AddProjectPageState extends State<AddProjectPage> {
  final TextEditingController _projectNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  String _qrData = '';
  int _members = 1;

  @override
  void dispose() {
    _projectNameController.dispose();
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
        'members': _members,
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
            '프로젝트 코드: $projectCode\n프로젝트 이름: ${_projectNameController.text}\n시작 날짜: ${_startDate != null ? DateFormat('yyyy-MM-dd').format(_startDate!) : ''}\n마감 날짜: ${_endDate != null ? DateFormat('yyyy-MM-dd').format(_endDate!) : ''}\n인원: $_members\n상세 설명: ${_descriptionController.text}';
      });

      _navigateToQRCodePage(_qrData); // QR 코드 페이지로 이동
      // _showQRCodeDialog(_qrData); // QR 코드 다이얼로그 호출
    } else {
      print('사용자가 로그인하지 않았습니다.');
    }
  }

  void _navigateToQRCodePage(String qrData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QRCodePage(qrData: qrData),
      ),
    );
  }

  // void _showQRCodeDialog(String qrData) {
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         title: Text('QR 코드'),
  //         content: SingleChildScrollView(
  //           child: Column(
  //             mainAxisSize: MainAxisSize.min,
  //             children: [
  //               QrImageView(
  //                 data: qrData,
  //                 backgroundColor: Colors.white,
  //                 size: 100,
  //               ),
  //               SizedBox(height: 20),
  //               Text(
  //                 qrData,
  //                 textAlign: TextAlign.center,
  //               ),
  //             ],
  //           ),
  //         ),
  //         actions: [
  //           TextButton(
  //             child: Text('확인'),
  //             onPressed: () {
  //               Navigator.pushNamedAndRemoveUntil(
  //                   context, '/', (route) => false);
  //             },
  //           ),
  //           TextButton(
  //             child: Text('취소'),
  //             onPressed: () {
  //               Navigator.of(context).pop(); // 팝업 닫기
  //             },
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

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
                onPressed: _addProject,
                child: Text('+ 생성'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                ),
              ),
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

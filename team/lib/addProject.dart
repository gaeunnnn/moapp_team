import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class AddProjectPage extends StatefulWidget {
  @override
  _AddProjectPageState createState() => _AddProjectPageState();
}

class _AddProjectPageState extends State<AddProjectPage> {
  final TextEditingController _projectNameController = TextEditingController();
  final TextEditingController _deadlineController = TextEditingController();
  final TextEditingController _membersController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String _qrData = '';

  @override
  void dispose() {
    _projectNameController.dispose();
    _deadlineController.dispose();
    _membersController.dispose();
    _descriptionController.dispose();
    super.dispose();
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
              '*기한',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextField(
              controller: _deadlineController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(vertical: 10, horizontal: 10),
              ),
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
                onPressed: () {
                  setState(() {
                    _qrData =
                        '프로젝트 이름: ${_projectNameController.text}\n기한: ${_deadlineController.text}\n인원: ${_membersController.text}\n상세 설명: ${_descriptionController.text}';
                  });
                },
                child: Text('+ 생성'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black, // Background color
                ),
              ),
            ),
            SizedBox(height: 20),
            if (_qrData.isNotEmpty)
              Center(
                child: QrImageView(
                  data: _qrData,
                  backgroundColor: Colors.white,
                  size: 200,
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: IconButton(
          icon: Icon(Icons.home),
          onPressed: () {
            // Add your onPressed code here!
          },
        ),
      ),
    );
  }
}

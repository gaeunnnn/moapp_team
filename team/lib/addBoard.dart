import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:io';
import 'map_picker.dart';

class AddBoardPage extends StatefulWidget {
  final Map<String, dynamic>? board;
  final String projectId;

  AddBoardPage({this.board, required this.projectId});

  @override
  _AddBoardPageState createState() => _AddBoardPageState();
}

class _AddBoardPageState extends State<AddBoardPage> {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();
  final User? currentUser = FirebaseAuth.instance.currentUser;
  File? _image;
  LatLng? _selectedLocation;
  final picker = ImagePicker();
  String authorName = '';

  @override
  void initState() {
    super.initState();
    if (widget.board != null) {
      _contentController.text = widget.board!['content'];
    }
    _fetchAuthorName();
  }

  Future<void> _fetchAuthorName() async {
    if (currentUser != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .get();

      if (userDoc.exists) {
        setState(() {
          authorName = userDoc['name'];
        });
      }
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      } else {
        print('No image selected.');
      }
    });
  }

  Future<String?> _uploadImage(File image) async {
    try {
      final storageRef = FirebaseStorage.instance.ref();
      final imageRef = storageRef.child(
          'images/${DateTime.now().toIso8601String()}_${currentUser!.uid}.jpg');
      final uploadTask = imageRef.putFile(image);
      final snapshot = await uploadTask.whenComplete(() => null);
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  void _pickLocation() async {
    final selectedLocation = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MapPickerPage()),
    );

    if (selectedLocation != null) {
      setState(() {
        _selectedLocation = selectedLocation;
      });
    }
  }

  void _saveBoard() async {
    if (_formKey.currentState!.validate()) {
      String? imageUrl;
      if (_image != null) {
        imageUrl = await _uploadImage(_image!);
      }

      final board = {
        'content': _contentController.text,
        'author': currentUser!.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'imageUrl': imageUrl,
        'location': _selectedLocation != null
            ? GeoPoint(
                _selectedLocation!.latitude, _selectedLocation!.longitude)
            : null,
        'author_name': authorName,
      };
      await FirebaseFirestore.instance
          .collection('projects')
          .doc(widget.projectId)
          .collection('board')
          .add(board);

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
                    backgroundImage: AssetImage('assets/avatar.png'),
                    radius: 20,
                  ),
                  SizedBox(width: 10),
                  Text(
                    authorName,
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
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.camera),
                    onPressed: _pickImage,
                  ),
                  IconButton(
                    icon: Icon(Icons.map),
                    onPressed: _pickLocation,
                  ),
                ],
              ),
              if (_image != null) Image.file(_image!),
              if (_selectedLocation != null)
                Text(
                    'Selected location: ${_selectedLocation!.latitude}, ${_selectedLocation!.longitude}'),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'map.dart';
import 'dart:io';

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
  String profileUrl = '';
  String? _selectedAddress;

  @override
  void initState() {
    super.initState();
    if (widget.board != null) {
      _contentController.text = widget.board!['content'];
      _selectedLocation = LatLng(widget.board!['location'].latitude,
          widget.board!['location'].longitude);
      _selectedAddress = widget.board!['address'];
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
          profileUrl = userDoc['profileImageUrl'];
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
      MaterialPageRoute(builder: (context) => MapSample()),
    );

    if (selectedLocation != null) {
      setState(() {
        _selectedLocation = selectedLocation;
        _getAddressFromLatLng(selectedLocation);
      });
    }
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        setState(() {
          _selectedAddress =
              '${placemarks.first.street}, ${placemarks.first.locality}';
          _contentController.text =
              '장소: $_selectedAddress\n${_contentController.text}';
        });
      }
    } catch (e) {
      print(e);
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
        'authorProfileImageUrl': profileUrl,
        'address': _selectedAddress,
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
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Divider(color: Colors.grey),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: profileUrl.isNotEmpty
                          ? NetworkImage(profileUrl)
                          : null,
                      child: profileUrl.isEmpty
                          ? Icon(Icons.person, size: 20)
                          : null,
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
                if (_image != null) ...[
                  SizedBox(height: 20),
                  Center(
                    child: Image.file(
                      _image!,
                      width: 100,
                      height: 100,
                    ),
                  ),
                ],
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

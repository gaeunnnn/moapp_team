import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:io';
import 'map.dart';

class EditBoardPage extends StatefulWidget {
  final Map<String, dynamic> board;
  final String projectId;
  final String boardId;

  EditBoardPage({
    required this.board,
    required this.projectId,
    required this.boardId,
  });

  @override
  _EditBoardPageState createState() => _EditBoardPageState();
}

class _EditBoardPageState extends State<EditBoardPage> {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();
  final User? currentUser = FirebaseAuth.instance.currentUser;
  File? _image;
  LatLng? _selectedLocation;
  final picker = ImagePicker();
  String authorName = '';
  String authorProfileImageUrl = '';
  String? _selectedAddress;
  String? imageUrl;

  @override
  void initState() {
    super.initState();
    _contentController.text = widget.board['content'];
    imageUrl = widget.board['imageUrl'];
    _selectedLocation = widget.board['location'] != null
        ? LatLng(widget.board['location'].latitude,
            widget.board['location'].longitude)
        : null;
    _selectedAddress = widget.board['address'];
    _fetchAuthorName();
  }

  Future<void> _fetchAuthorName() async {
    final authorUID = widget.board['author'];
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(authorUID)
        .get();

    if (userDoc.exists) {
      setState(() {
        authorName = userDoc['name'];
        authorProfileImageUrl = userDoc['profileImageUrl'] ?? '';
      });
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
              _contentController.text.replaceFirst(RegExp(r'장소:.*\n'), '');
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
      } else {
        imageUrl = widget.board['imageUrl'];
      }

      final board = {
        'content': _contentController.text,
        'author': widget.board['author'],
        'createdAt': widget.board['createdAt'],
        'imageUrl': imageUrl,
        'location': _selectedLocation != null
            ? GeoPoint(
                _selectedLocation!.latitude, _selectedLocation!.longitude)
            : widget.board['location'],
        'author_name': authorName,
        'authorProfileImageUrl': authorProfileImageUrl,
        'id': widget.board['id'],
        'address': _selectedAddress ?? widget.board['address'],
      };
      await FirebaseFirestore.instance
          .collection('projects')
          .doc(widget.projectId)
          .collection('board')
          .doc(widget.boardId)
          .update(board);

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
        title: Text('게시글 편집'),
        actions: [
          TextButton(
            onPressed: _saveBoard,
            child: Text(
              '저장하기',
              style: TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
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
                    radius: 20,
                    backgroundImage: authorProfileImageUrl.isNotEmpty
                        ? NetworkImage(authorProfileImageUrl)
                        : null,
                    child: authorProfileImageUrl.isEmpty
                        ? Icon(Icons.person, size: 20)
                        : null,
                  ),
                  SizedBox(width: 10),
                  Text(
                    authorName.isNotEmpty ? authorName : 'Unknown',
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
              if (_image != null)
                Center(
                  child: Image.file(
                    _image!,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                )
              else if (imageUrl != null && imageUrl!.isNotEmpty)
                Center(
                  child: Image.network(
                    imageUrl!,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
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
            ],
          ),
        ),
      ),
    );
  }
}

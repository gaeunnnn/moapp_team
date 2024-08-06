import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? currentUser = FirebaseAuth.instance.currentUser;
  Map<String, dynamic>? _userData;
  File? _image;
  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      _image = File(pickedFile.path);

      String? downloadUrl = await _uploadImage(_image!);
      if (downloadUrl != null) {
        await _firestore
            .collection('users')
            .doc(currentUser!.uid)
            .update({'profileImageUrl': downloadUrl});
        _fetchUserData();
      }
    } else {
      print('No image selected.');
    }
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

  Future<void> _fetchUserData() async {
    if (currentUser != null) {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(currentUser!.uid).get();

      if (userDoc.exists) {
        setState(() {
          _userData = userDoc.data() as Map<String, dynamic>;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        actions: [
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: () async {
              await _auth.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _userData == null
              ? CircularProgressIndicator()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    InkWell(
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: _userData!['profileImageUrl'] != null
                            ? NetworkImage(_userData!['profileImageUrl'])
                            : AssetImage('assets/default_profile.png')
                                as ImageProvider,
                        child: _userData!['profileImageUrl'] == null
                            ? Icon(
                                Icons.person,
                                size: 50,
                              )
                            : null,
                      ),
                      onTap: _pickImage,
                    ),
                    SizedBox(height: 20),
                    Text(
                      _userData!['name'] ?? 'No Name',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 10),
                    Divider(color: Colors.grey),
                    SizedBox(height: 10),
                    _buildInfoRow(
                        '학부', _userData!['department'] ?? 'No Department'),
                    SizedBox(height: 10),
                    _buildInfoRow(
                        '학년', '${_userData!['year'] ?? 'No Year'} 학년'),
                    SizedBox(height: 10),
                    _buildInfoRow('학교', _userData!['faculty'] ?? 'No Faculty'),
                    SizedBox(height: 10),
                    _buildInfoRow('이메일', currentUser!.email ?? 'No Email'),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String title, String content) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$title:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          content,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

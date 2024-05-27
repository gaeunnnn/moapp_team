import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Profile'),
          actions: [
            IconButton(
              icon: Icon(Icons.exit_to_app),
              onPressed: () async {
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.person),
                SizedBox(height: 20),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('GG', style: TextStyle(fontSize: 16)),
                  Divider(),
                  Text(
                    'I promise to take the test honestly before GOD.',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ]),
              ],
            ),
          ),
        ));
  }
}

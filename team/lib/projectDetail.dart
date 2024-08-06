import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

import 'project.dart';

class ProjectDetailPage extends StatefulWidget {
  final String projectId;

  const ProjectDetailPage({Key? key, required this.projectId})
      : super(key: key);

  @override
  _ProjectDetailPageState createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends State<ProjectDetailPage> {
  late Project project;
  bool isLoading = true;
  List<String> teamMemberNames = [];
  List<Map<String, dynamic>> recentActivities = [];
  List<Map<String, dynamic>> recentActivitiesTodo = [];
  int _selectedIndex = 1;

  void _onItemTapped(int index) {
    switch (index) {
      case 0:
        Navigator.pop(context);
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/detail',
            arguments: widget.projectId);
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/calendar',
            arguments: widget.projectId);
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/board',
            arguments: widget.projectId);
        break;
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    fetchProjectDetails();
  }

  Future<void> fetchProjectDetails() async {
    DocumentSnapshot projectDoc = await FirebaseFirestore.instance
        .collection('projects')
        .doc(widget.projectId)
        .get();

    if (projectDoc.exists) {
      project = Project.fromDocumentSnapshot(projectDoc);
      await fetchTeamMemberNames();
      await fetchRecentActivities();
    }
  }

  Future<void> fetchTeamMemberNames() async {
    List<String> names = [];

    for (int i = 1; i <= project.members; i++) {
      String? uid = project.teamMembers['teamMember$i'];
      if (uid != null) {
        DocumentSnapshot userDoc =
            await FirebaseFirestore.instance.collection('users').doc(uid).get();
        if (userDoc.exists) {
          names.add(userDoc['name']);
        }
      }
    }

    setState(() {
      teamMemberNames = names;
      isLoading = false;
    });
  }

  Future<void> fetchRecentActivities() async {
    List<Map<String, dynamic>> activities = [];
    List<Map<String, dynamic>> activitiesTodo = [];

    // Fetch recent board activities
    QuerySnapshot boardSnapshot = await FirebaseFirestore.instance
        .collection('projects')
        .doc(widget.projectId)
        .collection('board')
        .orderBy('createdAt', descending: true)
        .limit(4)
        .get();

    for (var doc in boardSnapshot.docs) {
      activities.add({
        'type': 'board',
        'content': doc['content'],
        'author': doc['author_name'],
        'createdAt': doc['createdAt'],
      });
    }

    // Fetch recent todo activities
    QuerySnapshot todoSnapshot = await FirebaseFirestore.instance
        .collection('projects')
        .doc(widget.projectId)
        .collection('todolists')
        .orderBy('date', descending: true)
        .limit(4)
        .get();

    for (var doc in todoSnapshot.docs) {
      activitiesTodo.add({
        'type': 'todo',
        'content': doc['title'],
        'author': doc['author_name'] ?? "",
        'createdAt': doc['date'],
      });
    }

    setState(() {
      recentActivities = activities;
      recentActivitiesTodo = activitiesTodo;
    });

    print('Recent Activities set in state'); // 디버그 메시지 추가
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          isLoading ? '' : project.title,
          style: TextStyle(
              fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Detail',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.forum),
            label: 'Board',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        onTap: _onItemTapped,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '팀원',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    ...teamMemberNames.map((name) => ListTile(
                          leading: Icon(Icons.person),
                          title: Text(name, style: TextStyle(fontSize: 16)),
                        )),
                    Divider(),
                    SizedBox(height: 10),
                    Text(
                      '설명',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    Text(project.description, style: TextStyle(fontSize: 16)),
                    SizedBox(height: 10),
                    Divider(),
                    SizedBox(height: 10),
                    Text(
                      '진척도',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 20),
                    SizedBox(
                      height: 200,
                      child: PieChart(
                        PieChartData(
                          sections: [
                            PieChartSectionData(
                              color: Color(0xFFF46A6A),
                              value: project.progress * 100,
                              title:
                                  '${(project.progress * 100).toStringAsFixed(1)}%',
                              radius: 50,
                              titleStyle: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            PieChartSectionData(
                              color: Colors.grey[300],
                              value: 100 - (project.progress * 100),
                              title: '',
                              radius: 50,
                            ),
                          ],
                          centerSpaceRadius: 40,
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    Divider(),
                    SizedBox(height: 10),
                    Text(
                      '최근 게시물',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    ...recentActivities.map((activity) {
                      return Card(
                        elevation: 2,
                        margin: EdgeInsets.symmetric(vertical: 5),
                        child: ListTile(
                          leading: Icon(Icons.forum, color: Colors.blueAccent),
                          title: Text(
                            "${activity['author']}님이 새로운 게시글을 추가하셨습니다!",
                            style: TextStyle(fontSize: 16),
                          ),
                          subtitle: Text(activity['content']),
                        ),
                      );
                    }).toList(),
                    Divider(),
                    SizedBox(height: 10),
                    Text(
                      '최근 추가된 할 일',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    ...recentActivitiesTodo.map((activityTodo) {
                      return Card(
                        elevation: 2,
                        margin: EdgeInsets.symmetric(vertical: 5),
                        child: ListTile(
                          leading:
                              Icon(Icons.check_circle, color: Colors.green),
                          title: Text(
                            "${activityTodo['author']}님이 새로운 할 일을 추가하셨습니다!",
                            style: TextStyle(fontSize: 16),
                          ),
                          subtitle: Text(activityTodo['content']),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
    );
  }
}

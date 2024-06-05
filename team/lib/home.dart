import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'project.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final CarouselController _controller = CarouselController();
  int _current = 0;
  bool showCompleted = false;
  bool isCarouselView = true;
  List<Project> projects = [];
  String userName = '';

  @override
  void initState() {
    super.initState();
    fetchUserName();
    fetchProjects();
  }

  Future<void> fetchUserName() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (userDoc.exists) {
        setState(() {
          userName = userDoc['name'];
        });
      }
    }
  }

  void fetchProjects() {
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      FirebaseFirestore.instance
          .collection('projects')
          .snapshots()
          .listen((snapshot) {
        final List<DocumentSnapshot> userProjects = snapshot.docs.where((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          int membersCount = data['members'];
          for (int i = 1; i <= membersCount; i++) {
            String teamMemberField = 'teamMember$i';
            if (data[teamMemberField] == currentUser.uid) {
              return true;
            }
          }
          return false;
        }).toList();

        if (mounted) {
          setState(() {
            projects = userProjects
                .map((doc) => Project.fromDocumentSnapshot(doc))
                .toList();
          });
        }
      });
    } else {
      print('사용자가 로그인하지 않았습니다.');
    }
  }

  Future<bool> joinProjectByCode(String code, BuildContext context) async {
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      DocumentReference projectRef =
          FirebaseFirestore.instance.collection('projects').doc(code);
      DocumentSnapshot projectSnapshot = await projectRef.get();

      if (projectSnapshot.exists) {
        Map<String, dynamic> projectData =
            projectSnapshot.data() as Map<String, dynamic>;
        Map<String, dynamic> updates = {};
        int members = projectData['members'];
        bool isMemberAdded = false;

        for (int i = 1; i <= members; i++) {
          String teamMemberField = 'teamMember$i';
          if (!projectData.containsKey(teamMemberField)) {
            updates[teamMemberField] = currentUser.uid;
            isMemberAdded = true;
            break;
          }
        }

        if (isMemberAdded) {
          await FirebaseFirestore.instance.runTransaction((transaction) async {
            transaction.update(projectRef, updates);

            QuerySnapshot todolistsSnapshot = await projectRef
                .collection('todolists')
                .where('type', isEqualTo: '공동')
                .get();

            for (var doc in todolistsSnapshot.docs) {
              Map<String, dynamic> todoData =
                  doc.data() as Map<String, dynamic>;

              for (int i = 1; i <= members; i++) {
                String teamMemberField = 'teamMember$i';
                if (!todoData.containsKey(teamMemberField)) {
                  todoData[teamMemberField] = currentUser.uid;
                }
              }

              transaction.update(doc.reference, todoData);
            }
          });

          return true;
        } else {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('알림'),
              content: Text('팀 멤버가 모두 채워졌습니다.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('확인'),
                ),
              ],
            ),
          );
        }
      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('알림'),
            content: Text('프로젝트가 존재하지 않습니다.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('확인'),
              ),
            ],
          ),
        );
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final List<Project> filteredProjects = showCompleted
        ? projects
        : projects.where((project) => !project.isCompleted).toList();

    final List<Widget> imageSliders = filteredProjects
        .map(
          (project) => Container(
            height: 400,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 5,
                  blurRadius: 7,
                  blurStyle: BlurStyle.normal,
                  offset: Offset(5, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    PopupMenuButton<int>(
                      iconSize: 20,
                      icon: Icon(Icons.more_vert, color: Colors.grey),
                      color: Colors.white,
                      onSelected: (item) => onSelected(context, item, project),
                      itemBuilder: (context) => [
                        PopupMenuItem<int>(
                          value: 0,
                          child: Center(
                            child: Text(
                              '코드 확인',
                              style: TextStyle(color: Colors.black),
                            ),
                          ),
                        ),
                        PopupMenuItem<int>(
                          value: 1,
                          child: Center(
                            child: Text(
                              '편집',
                              style: TextStyle(color: Colors.black),
                            ),
                          ),
                        ),
                        PopupMenuItem<int>(
                          value: 2,
                          child: Center(
                            child: Text(
                              '삭제',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Text(
                  project.title,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
                ),
                Spacer(),
                Text(
                  project.duration,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                SizedBox(height: 10),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 50),
                  child: Stack(
                    children: [
                      LinearProgressIndicator(
                        value: project.progress,
                        backgroundColor: Colors.grey[350],
                        color: project.isCompleted
                            ? Colors.grey
                            : Color(0xFFF46A6A),
                        minHeight: 20,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      Center(
                        child: Text(
                          '${(project.progress * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 30),
                Container(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed(
                        '/calendar',
                        arguments: project.id,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          project.isCompleted ? Colors.grey : Color(0xFFF46A6A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(10.0),
                          bottomRight: Radius.circular(10.0),
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          project.isCompleted ? "진행완료" : "진행중",
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
        .toList();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.person),
          onPressed: () {
            Navigator.of(context).pushNamed('/profile');
          },
        ),
        title: const Text('TeamSync',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(isCarouselView ? Icons.view_list : Icons.view_carousel),
            onPressed: () {
              setState(() {
                isCarouselView = !isCarouselView;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(height: 50),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("$userName학부생님의"),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "프로젝트 >",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                    Row(
                      children: [
                        Text("완료 항목 보기"),
                        Checkbox(
                          activeColor: Colors.grey,
                          value: showCompleted,
                          onChanged: (bool? value) {
                            setState(() {
                              showCompleted = value!;
                            });
                          },
                        ),
                        PopupMenuButton<int>(
                          icon: Icon(Icons.add),
                          onSelected: (value) {
                            if (value == 0) {
                              Navigator.of(context).pushNamed('/addProject');
                            } else if (value == 1) {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  TextEditingController codeController =
                                      TextEditingController();
                                  return AlertDialog(
                                    title: Text('코드를 입력하세요'),
                                    content: TextField(
                                      controller: codeController,
                                      decoration:
                                          InputDecoration(hintText: "코드 입력"),
                                    ),
                                    actions: [
                                      TextButton(
                                        child: Text('취소'),
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                      TextButton(
                                        child: Text('확인'),
                                        onPressed: () async {
                                          String code =
                                              codeController.text.trim();
                                          if (await joinProjectByCode(
                                              code, context)) {
                                            Navigator.of(context).pop();
                                          }
                                        },
                                      ),
                                    ],
                                  );
                                },
                              );
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem<int>(
                              value: 0,
                              child: Center(
                                child: Text('프로젝트 생성',
                                    style: TextStyle(color: Colors.black)),
                              ),
                            ),
                            PopupMenuItem<int>(
                              value: 1,
                              child: Center(
                                child: Text('코드 입력',
                                    style: TextStyle(color: Colors.black)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: isCarouselView
                ? CarouselSlider(
                    items: imageSliders,
                    carouselController: _controller,
                    options: CarouselOptions(
                      enlargeCenterPage: true,
                      viewportFraction: 0.62,
                      height: 350,
                      onPageChanged: (index, reason) {
                        setState(() {
                          _current = index;
                        });
                      },
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredProjects.length,
                    itemBuilder: (context, index) {
                      final project = filteredProjects[index];
                      return ListTile(
                        title: Text(project.title),
                        subtitle: Text(project.duration),
                        trailing: PopupMenuButton<int>(
                          icon: Icon(Icons.more_vert, color: Colors.grey),
                          onSelected: (item) =>
                              onSelected(context, item, project),
                          itemBuilder: (context) => [
                            PopupMenuItem<int>(
                              value: 0,
                              child: Center(
                                child: Text('코드 확인',
                                    style: TextStyle(color: Colors.black)),
                              ),
                            ),
                            PopupMenuItem<int>(
                              value: 1,
                              child: Center(
                                child: Text('편집',
                                    style: TextStyle(color: Colors.black)),
                              ),
                            ),
                            PopupMenuItem<int>(
                              value: 2,
                              child: Center(
                                child: Text('삭제',
                                    style: TextStyle(color: Colors.red)),
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          // Navigate to project details
                        },
                      );
                    },
                  ),
          ),
          isCarouselView
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: filteredProjects.map((project) {
                    int index = filteredProjects.indexOf(project);
                    return Container(
                      width: 8.0,
                      height: 8.0,
                      margin: const EdgeInsets.symmetric(
                          vertical: 10.0, horizontal: 2.0),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _current == index
                            ? const Color.fromRGBO(0, 0, 0, 0.9)
                            : const Color.fromRGBO(0, 0, 0, 0.4),
                      ),
                    );
                  }).toList(),
                )
              : SizedBox(),
          SizedBox(height: 30),
        ],
      ),
    );
  }

  void onSelected(BuildContext context, int item, Project project) {
    switch (item) {
      case 0:
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('코드 확인'),
            content: Text('프로젝트 코드: ${project.id}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('확인'),
              ),
            ],
          ),
        );
        break;
      case 1:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => EditProjectPage(
              project: project,
              onSave: (editedProject) {
                setState(() {
                  int index = projects.indexOf(project);
                  projects[index] = editedProject;
                });
              },
            ),
          ),
        );
        break;
      case 2:
        // 삭제 로직 추가
        setState(() {
          projects.remove(project);
        });
        break;
    }
  }
}

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
  late TextEditingController titleController;
  late TextEditingController durationController;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.project.title);
    durationController = TextEditingController(text: widget.project.duration);
  }

  @override
  void dispose() {
    titleController.dispose();
    durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Project')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: durationController,
              decoration: InputDecoration(labelText: 'Duration'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Project editedProject = Project(
                  id: widget.project.id,
                  leaderUid: widget.project.leaderUid,
                  title: titleController.text,
                  duration: durationController.text,
                  members: widget.project.members,
                  description: widget.project.description,
                  progress: widget.project.progress,
                  isCompleted: widget.project.isCompleted,
                );
                widget.onSave(editedProject);
                Navigator.of(context).pop();
              },
              child: Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

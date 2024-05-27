import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carousel_slider/carousel_slider.dart';
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

  @override
  void initState() {
    super.initState();
  }

  Stream<List<Project>> fetchProjects() {
    return FirebaseFirestore.instance
        .collection('projects')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Project(
          leaderUid: doc['leaderUid'],
          title: doc['title'],
          duration: '${doc['startDate']} ~ ${doc['endDate']}',
          members: doc['members'],
          description: doc['description'],
          progress: doc['progress'],
          isCompleted: doc['isCompleted'],
        );
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.person),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/profile');
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
      body: StreamBuilder<List<Project>>(
        stream: fetchProjects(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          projects = snapshot.data ?? [];

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
                            onSelected: (item) =>
                                onSelected(context, item, project),
                            itemBuilder: (context) => [
                              PopupMenuItem<int>(
                                value: 0,
                                child: Center(
                                  child: Text(
                                    '편집',
                                    style: TextStyle(color: Colors.black),
                                  ),
                                ),
                              ),
                              PopupMenuItem<int>(
                                value: 1,
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
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 25),
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
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: project.isCompleted
                                ? Colors.grey
                                : Color(0xFFF46A6A),
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
                              Text(project.isCompleted ? "진행완료" : "진행중",
                                  style: TextStyle(
                                      fontSize: 20,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                              IconButton(
                                icon: Icon(Icons.arrow_forward_ios_rounded,
                                    color: Colors.white),
                                onPressed: () {
                                  Navigator.of(context)
                                      .pushReplacementNamed('/calendar');
                                },
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

          return Column(
            children: [
              SizedBox(height: 50),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("000학부생님의"),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "프로젝트 >",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 20),
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
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                Navigator.of(context).pushNamed('/addProject');
                              },
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
                        items: imageSliders.isNotEmpty
                            ? imageSliders
                            : [
                                Center(
                                  child: Text('No projects available.'),
                                )
                              ],
                        carouselController: _controller,
                        options: CarouselOptions(
                            enlargeCenterPage: true,
                            viewportFraction: 0.62,
                            height: 350,
                            onPageChanged: (index, reason) {
                              setState(() {
                                _current = index;
                              });
                            }),
                      )
                    : filteredProjects.isNotEmpty
                        ? ListView.builder(
                            itemCount: filteredProjects.length,
                            itemBuilder: (context, index) {
                              final project = filteredProjects[index];
                              return ListTile(
                                title: Text(project.title),
                                subtitle: Text(project.duration),
                                trailing: PopupMenuButton<int>(
                                  icon:
                                      Icon(Icons.more_vert, color: Colors.grey),
                                  onSelected: (item) =>
                                      onSelected(context, item, project),
                                  itemBuilder: (context) => [
                                    PopupMenuItem<int>(
                                      value: 0,
                                      child: Center(
                                        child: Text('편집',
                                            style:
                                                TextStyle(color: Colors.black)),
                                      ),
                                    ),
                                    PopupMenuItem<int>(
                                      value: 1,
                                      child: Center(
                                        child: Text('삭제',
                                            style:
                                                TextStyle(color: Colors.red)),
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  // Navigate to project details
                                },
                              );
                            },
                          )
                        : Center(
                            child: Text('No projects available.'),
                          ),
              ),
              if (isCarouselView && imageSliders.isNotEmpty)
                Row(
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
                ),
              SizedBox(height: 30),
            ],
          );
        },
      ),
    );
  }

  void onSelected(BuildContext context, int item, Project project) {
    switch (item) {
      case 0:
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
      case 1:
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
  late TextEditingController membersController;
  late TextEditingController descriptionController;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.project.title);
    durationController = TextEditingController(text: widget.project.duration);
    membersController =
        TextEditingController(text: widget.project.members.toString());
    descriptionController =
        TextEditingController(text: widget.project.description);
  }

  @override
  void dispose() {
    titleController.dispose();
    durationController.dispose();
    membersController.dispose();
    descriptionController.dispose();
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
            TextField(
              controller: membersController,
              decoration: InputDecoration(labelText: 'Members'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(labelText: 'Description'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Project editedProject = Project(
                  leaderUid: widget.project.leaderUid,
                  title: titleController.text,
                  duration: durationController.text,
                  members: int.parse(membersController.text),
                  description: descriptionController.text,
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

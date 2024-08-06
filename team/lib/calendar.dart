import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'event.dart';
import 'addTodo.dart';

class CalendarPage extends StatefulWidget {
  final String projectId;

  const CalendarPage({Key? key, required this.projectId}) : super(key: key);

  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Event>> _events = {};
  int _selectedIndex = 2;
  bool _isLoading = true; // 로딩 상태를 위한 변수

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

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

  Future<void> _loadEvents() async {
    try {
      setState(() {
        _isLoading = true; // 로딩 시작
      });

      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('User not logged in');
        return;
      }
      final uid = currentUser.uid;

      // 프로젝트 문서에서 members 필드를 가져오기
      final projectDoc = await FirebaseFirestore.instance
          .collection('projects')
          .doc(widget.projectId)
          .get();

      if (!projectDoc.exists) {
        print('Project document does not exist');
        return;
      }

      final projectData = projectDoc.data() as Map<String, dynamic>;
      final int membersCount = projectData['members'];

      final todoCollectionRef = FirebaseFirestore.instance
          .collection('projects')
          .doc(widget.projectId)
          .collection('todolists');

      final todoSnapshot = await todoCollectionRef.get();
      print('Fetched ${todoSnapshot.docs.length} documents from Firestore');

      final events = <DateTime, List<Event>>{};

      for (final doc in todoSnapshot.docs) {
        final data = doc.data();
        bool isMember = false;

        for (int i = 1; i <= membersCount; i++) {
          String teamMemberField = 'teamMember$i';
          if (data.containsKey(teamMemberField) &&
              data[teamMemberField] == uid) {
            isMember = true;
            break;
          }
        }

        if (isMember && data.containsKey('date')) {
          final date = (data['date'] as Timestamp).toDate();
          final normalizedDate = DateTime(date.year, date.month, date.day);
          final event = Event(
            title: data['title'] ?? 'Untitled',
            date: normalizedDate.toIso8601String(),
            type: data['type'] ?? 'Unknown',
            isDone: data['isDone'] ?? false,
          );
          if (events[normalizedDate] == null) {
            events[normalizedDate] = [event];
          } else {
            events[normalizedDate]!.add(event);
          }
        } else {
          print(
              'Document ${doc.id} is not a member or does not have a valid date');
        }
      }

      setState(() {
        _events = events;
        _isLoading = false; // 로딩 종료
      });
      print('Loaded ${_events.length} event dates');
    } catch (e) {
      print('Error loading events: $e');
      setState(() {
        _isLoading = false; // 로딩 종료
      });
    }
  }

  Future<void> _navigateToAddTodoPage() async {
    if (_selectedDay == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('날짜를 선택하세요')),
      );
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTodoPage(
          projectId: widget.projectId,
          selectedDate: _selectedDay!,
        ),
      ),
    );

    if (result == true) {
      _loadEvents();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('TodoList'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Divider(),
              TableCalendar<Event>(
                focusedDay: _focusedDay,
                firstDay: DateTime(2000),
                lastDay: DateTime(2100),
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) {
                  return isSameDay(_selectedDay, day);
                },
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                onFormatChanged: (format) {
                  if (_calendarFormat != format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  }
                },
                eventLoader: (day) {
                  return _events[DateTime(day.year, day.month, day.day)] ?? [];
                },
                calendarStyle: CalendarStyle(
                  markersAlignment: Alignment.bottomCenter,
                  markerDecoration: BoxDecoration(
                    shape: BoxShape.circle,
                  ),
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, date, events) {
                    if (events.isEmpty) return SizedBox();
                    return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: events.map((event) {
                          return Container(
                            width: 7,
                            height: 7,
                            margin: const EdgeInsets.symmetric(horizontal: 1.5),
                            decoration: BoxDecoration(
                              color: event.type == '개인'
                                  ? Colors.purple
                                  : Colors.green,
                              shape: BoxShape.circle,
                            ),
                          );
                        }).toList());
                  },
                ),
              ),
              Divider(),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Todo-list',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        Container(
                          width: 85,
                          child: Divider(
                            thickness: 2,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    FloatingActionButton(
                      backgroundColor: Colors.white,
                      onPressed: _navigateToAddTodoPage,
                      child: Icon(Icons.add),
                      mini: true,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  children: _getTodoList(),
                ),
              ),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
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
    );
  }

  List<Widget> _getTodoList() {
    final normalizedSelectedDay = _selectedDay != null
        ? DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day)
        : null;
    if (normalizedSelectedDay == null ||
        _events[normalizedSelectedDay] == null) {
      return [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('No Todo Items'),
        )
      ];
    }
    return _events[normalizedSelectedDay]!
        .map((event) => _buildTodoItem(event))
        .toList();
  }

  Widget _buildTodoItem(Event event) {
    return Slidable(
      key: Key(event.title),
      endActionPane: ActionPane(
        motion: ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (context) => _deleteTodoItem(event),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Delete',
          ),
        ],
      ),
      child: ListTile(
        title: Text(event.title),
        subtitle: Text(event.date.split('T')[0]),
        leading: Checkbox(
          value: event.isDone,
          onChanged: (bool? value) {
            setState(() {
              event.isDone = value!;
            });
            _updateTodoStatus(event);
          },
          activeColor: event.type == '개인' ? Colors.purple : Colors.green,
          side: BorderSide(
            color: event.type == '개인' ? Colors.purple : Colors.green,
          ),
        ),
      ),
    );
  }

  Future<void> _updateTodoStatus(Event event) async {
    final todoCollectionRef = FirebaseFirestore.instance
        .collection('projects')
        .doc(widget.projectId)
        .collection('todolists');

    try {
      await todoCollectionRef.doc(event.title).update({'isDone': event.isDone});
      print('Todo status successfully updated in Firestore');
    } catch (e) {
      print('Failed to update todo status: $e');
    }
  }

  Future<void> _deleteTodoItem(Event event) async {
    final todoCollectionRef = FirebaseFirestore.instance
        .collection('projects')
        .doc(widget.projectId)
        .collection('todolists');

    try {
      await todoCollectionRef.doc(event.title).delete();
      print('Todo item successfully deleted from Firestore');
      setState(() {
        _events[DateTime.parse(event.date)]?.remove(event);
      });
    } catch (e) {
      print('Failed to delete todo item: $e');
    }
  }
}

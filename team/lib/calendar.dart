import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({Key? key}) : super(key: key);
  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Event>> _events = {};

  int _selectedIndex = 1;

  void _onItemTapped(int index) {
    switch (index) {
      case 0:
        Navigator.pushNamed(context, '/');
        break;
      case 1:
        Navigator.pushNamed(context, '/calendar');
        break;
      case 2:
        Navigator.pushNamed(context, '/board');
        break;
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('TodoList'),
        centerTitle: true,
      ),
      body: Column(
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
              return _events[day] ?? [];
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
                        color:
                            event.type == '개인' ? Colors.purple : Colors.green,
                        shape: BoxShape.circle,
                      ),
                    );
                  }).toList(),
                );
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
                  onPressed: () => _addTodo(),
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
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bubble_chart),
            label: 'Board',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.black,
        onTap: _onItemTapped,
      ),
    );
  }

  List<Widget> _getTodoList() {
    if (_selectedDay == null || _events[_selectedDay!] == null) {
      return [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('No Todo Items'),
        )
      ];
    }
    return _events[_selectedDay!]!
        .map((event) => _buildTodoItem(event))
        .toList();
  }

  Widget _buildTodoItem(Event event) {
    return ListTile(
      title: Text(event.title),
      subtitle: Text(event.date),
      leading: Checkbox(
        value: event.isDone,
        onChanged: (bool? value) {
          setState(() {
            event.isDone = value!;
          });
        },
        activeColor: event.type == '개인' ? Colors.purple : Colors.green,
        side: BorderSide(
          color: event.type == '개인' ? Colors.purple : Colors.green,
        ),
      ),
    );
  }

  void _addTodo() {
    showDialog(
      context: context,
      builder: (context) => AddTodoDialog(
        onAdd: (event) {
          setState(() {
            if (_selectedDay != null) {
              if (_events[_selectedDay] != null) {
                _events[_selectedDay]!.add(event);
              } else {
                _events[_selectedDay!] = [event];
              }
            }
          });
        },
      ),
    );
  }
}

class AddTodoDialog extends StatefulWidget {
  final Function(Event) onAdd;

  AddTodoDialog({required this.onAdd});

  @override
  _AddTodoDialogState createState() => _AddTodoDialogState();
}

class _AddTodoDialogState extends State<AddTodoDialog> {
  final _controller = TextEditingController();
  String _type = '개인';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white, // 팝업창 배경색 흰색으로 설정
      title: Text('일정 추가'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              labelText: '*일정 이름',
              suffixIcon: IconButton(
                icon: Icon(Icons.clear),
                onPressed: () => _controller.clear(),
              ),
            ),
          ),
          SizedBox(height: 16.0),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '*유형',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(height: 8.0),
          Row(
            children: [
              _buildTypeOption('개인', Colors.purple),
              SizedBox(width: 16.0),
              _buildTypeOption('공동', Colors.green),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('취소'), // 버튼 텍스트를 "취소"로 변경
        ),
        ElevatedButton(
          onPressed: () {
            final event = Event(
              title: _controller.text,
              date: DateTime.now().toIso8601String(),
              isDone: false,
              type: _type,
            );
            widget.onAdd(event);
            Navigator.of(context).pop();
          },
          child: Text('생성'), // 버튼 텍스트를 "생성"으로 변경
        ),
      ],
    );
  }

  Widget _buildTypeOption(String type, Color color) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _type = type;
        });
      },
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.rectangle,
              border: Border.all(
                color: _type == type ? color : Colors.grey,
                width: 2,
              ),
              color:
                  _type == type ? color.withOpacity(0.2) : Colors.transparent,
            ),
            width: 24,
            height: 24,
            child: _type == type
                ? Icon(Icons.check, size: 16.0, color: color)
                : null,
          ),
          SizedBox(width: 8.0),
          Text(
            type,
            style: TextStyle(
              color: _type == type ? color : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

class Event {
  final String title;
  final String date;
  final String type;
  bool isDone;

  Event({
    required this.title,
    required this.date,
    required this.type,
    this.isDone = false,
  });
}

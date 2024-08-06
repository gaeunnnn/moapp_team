import 'package:cloud_firestore/cloud_firestore.dart';

class Project {
  String id;
  String leaderUid;
  String title;
  String duration;
  int members;
  String description;
  double progress;
  bool isCompleted;
  Map<String, String?> teamMembers;

  Project({
    required this.id,
    required this.leaderUid,
    required this.title,
    required this.duration,
    required this.members,
    required this.description,
    required this.progress,
    required this.isCompleted,
    required this.teamMembers,
  });

  factory Project.fromDocumentSnapshot(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    String startDateStr = data['startDate'];
    String endDateStr = data['endDate'];
    DateTime? startDate =
        startDateStr.isNotEmpty ? DateTime.parse(startDateStr) : null;
    DateTime? endDate =
        endDateStr.isNotEmpty ? DateTime.parse(endDateStr) : null;

    double progress = 0.0;
    if (startDate != null && endDate != null && startDate.isBefore(endDate)) {
      DateTime now = DateTime.now();
      int totalDays = endDate.difference(startDate).inDays;
      int elapsedDays = now.difference(startDate).inDays;
      progress = (elapsedDays / totalDays).clamp(0.0, 1.0);
    }

    Map<String, String?> teamMembers = {};
    for (int i = 1; i <= data['members']; i++) {
      String teamMemberField = 'teamMember$i';
      teamMembers[teamMemberField] = data[teamMemberField];
    }

    return Project(
      id: doc.id,
      leaderUid: data['leaderUid'],
      title: data['title'],
      duration: '$startDateStr ~ $endDateStr',
      members: data['members'],
      description: data['description'],
      progress: progress,
      isCompleted: progress != 1.0 ? false : true,
      teamMembers: teamMembers,
    );
  }
}

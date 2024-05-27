class Project {
  String leaderUid; // 방장 uid
  String title; // 프로젝트 제목
  String duration; // 프로젝트 기간
  int members; // 프로젝트 인원
  String description; // 상세설명
  double progress; // 진행 상황
  bool isCompleted; // 완료 여부

  Project({
    required this.leaderUid,
    required this.title,
    required this.duration,
    required this.members,
    required this.description,
    required this.progress,
    required this.isCompleted,
  });
}

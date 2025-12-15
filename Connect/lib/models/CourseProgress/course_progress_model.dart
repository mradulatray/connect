class CourseProgressModel {
  Progress? progress;
  int? totalLessons;
  int? lessonsCompleted;
  int? percentageCompleted;

  CourseProgressModel(
      {this.progress,
      this.totalLessons,
      this.lessonsCompleted,
      this.percentageCompleted});

  CourseProgressModel.fromJson(Map<String, dynamic> json) {
    progress = json['progress'] != null
        ? new Progress.fromJson(json['progress'])
        : null;
    totalLessons = json['totalLessons'];
    lessonsCompleted = json['lessonsCompleted'];
    percentageCompleted = json['percentageCompleted'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.progress != null) {
      data['progress'] = this.progress!.toJson();
    }
    data['totalLessons'] = this.totalLessons;
    data['lessonsCompleted'] = this.lessonsCompleted;
    data['percentageCompleted'] = this.percentageCompleted;
    return data;
  }
}

class Progress {
  String? sId;
  String? userId;
  String? courseId;
  List<CompletedLessons>? completedLessons;
  String? startedAt;
  int? xpEarned;
  bool? isCompleted;
  String? createdAt;
  String? updatedAt;
  int? iV;
  String? completedAt;

  Progress(
      {this.sId,
      this.userId,
      this.courseId,
      this.completedLessons,
      this.startedAt,
      this.xpEarned,
      this.isCompleted,
      this.createdAt,
      this.updatedAt,
      this.iV,
      this.completedAt});

  Progress.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    userId = json['userId'];
    courseId = json['courseId'];
    if (json['completedLessons'] != null) {
      completedLessons = <CompletedLessons>[];
      json['completedLessons'].forEach((v) {
        completedLessons!.add(new CompletedLessons.fromJson(v));
      });
    }
    startedAt = json['startedAt'];
    xpEarned = json['xpEarned'];
    isCompleted = json['isCompleted'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
    completedAt = json['completedAt'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    data['userId'] = this.userId;
    data['courseId'] = this.courseId;
    if (this.completedLessons != null) {
      data['completedLessons'] =
          this.completedLessons!.map((v) => v.toJson()).toList();
    }
    data['startedAt'] = this.startedAt;
    data['xpEarned'] = this.xpEarned;
    data['isCompleted'] = this.isCompleted;
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    data['__v'] = this.iV;
    data['completedAt'] = this.completedAt;
    return data;
  }
}

class CompletedLessons {
  String? lessonId;
  bool? isCompleted;
  int? quizScore;
  String? completedAt;
  String? sId;

  CompletedLessons(
      {this.lessonId,
      this.isCompleted,
      this.quizScore,
      this.completedAt,
      this.sId});

  CompletedLessons.fromJson(Map<String, dynamic> json) {
    lessonId = json['lessonId'];
    isCompleted = json['isCompleted'];
    quizScore = json['quizScore'];
    completedAt = json['completedAt'];
    sId = json['_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['lessonId'] = this.lessonId;
    data['isCompleted'] = this.isCompleted;
    data['quizScore'] = this.quizScore;
    data['completedAt'] = this.completedAt;
    data['_id'] = this.sId;
    return data;
  }
}

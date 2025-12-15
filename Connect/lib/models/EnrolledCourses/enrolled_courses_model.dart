class EnrolledCoursesModel {
  List<EnrolledCourses>? enrolledCourses;
  Pagination? pagination;

  EnrolledCoursesModel({this.enrolledCourses, this.pagination});

  EnrolledCoursesModel.fromJson(Map<String, dynamic> json) {
    if (json['enrolledCourses'] != null) {
      enrolledCourses = <EnrolledCourses>[];
      json['enrolledCourses'].forEach((v) {
        enrolledCourses!.add(new EnrolledCourses.fromJson(v));
      });
    }
    pagination = json['pagination'] != null
        ? new Pagination.fromJson(json['pagination'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.enrolledCourses != null) {
      data['enrolledCourses'] =
          this.enrolledCourses!.map((v) => v.toJson()).toList();
    }
    if (this.pagination != null) {
      data['pagination'] = this.pagination!.toJson();
    }
    return data;
  }
}

class EnrolledCourses {
  String? id;
  String? title;
  String? description;
  String? thumbnail;
  bool? isPaid;
  int? totalLessons;
  int? completedLessons;
  int? percentageCompleted;
  Group? group;
  Ratings? ratings;
  Creator? creator;
  List<Sections>? sections;

  EnrolledCourses(
      {this.id,
      this.title,
      this.description,
      this.thumbnail,
      this.isPaid,
      this.totalLessons,
      this.completedLessons,
      this.percentageCompleted,
      this.group,
      this.ratings,
      this.creator,
      this.sections});

  EnrolledCourses.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    title = json['title'];
    description = json['description'];
    thumbnail = json['thumbnail'];
    isPaid = json['isPaid'];
    totalLessons = json['totalLessons'];
    completedLessons = json['completedLessons'];
    percentageCompleted = json['percentageCompleted'];
    group = json['group'] != null ? new Group.fromJson(json['group']) : null;
    ratings =
        json['ratings'] != null ? new Ratings.fromJson(json['ratings']) : null;
    creator =
        json['creator'] != null ? new Creator.fromJson(json['creator']) : null;
    if (json['sections'] != null) {
      sections = <Sections>[];
      json['sections'].forEach((v) {
        sections!.add(new Sections.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['title'] = this.title;
    data['description'] = this.description;
    data['thumbnail'] = this.thumbnail;
    data['isPaid'] = this.isPaid;
    data['totalLessons'] = this.totalLessons;
    data['completedLessons'] = this.completedLessons;
    data['percentageCompleted'] = this.percentageCompleted;
    if (this.group != null) {
      data['group'] = this.group!.toJson();
    }
    if (this.ratings != null) {
      data['ratings'] = this.ratings!.toJson();
    }
    if (this.creator != null) {
      data['creator'] = this.creator!.toJson();
    }
    if (this.sections != null) {
      data['sections'] = this.sections!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Group {
  String? id;
  String? name;
  String? avatar;
  List<String>? admins;
  int? membersCount;

  Group({this.id, this.name, this.avatar, this.admins, this.membersCount});

  Group.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    avatar = json['avatar'];
    admins = json['admins'].cast<String>();
    membersCount = json['membersCount'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['avatar'] = this.avatar;
    data['admins'] = this.admins;
    data['membersCount'] = this.membersCount;
    return data;
  }
}

class Ratings {
  double? avgRating;
  double? totalReviews; // changed to double

  Ratings({this.avgRating, this.totalReviews});

  Ratings.fromJson(Map<String, dynamic> json) {
    avgRating = (json['avgRating'] as num?)?.toDouble();
    totalReviews = (json['totalReviews'] as num?)?.toDouble();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['avgRating'] = avgRating;
    data['totalReviews'] = totalReviews;
    return data;
  }
}

class Creator {
  String? id;
  String? name;
  String? email;
  String? avatar;

  Creator({this.id, this.name, this.email, this.avatar});

  Creator.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    email = json['email'];
    avatar = json['avatar'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['email'] = this.email;
    data['avatar'] = this.avatar;
    return data;
  }
}

class Sections {
  String? id;
  String? title;
  List<Lesson>? lessons;

  Sections({this.id, this.title, this.lessons});

  Sections.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    title = json['title'];
    if (json['lessons'] != null) {
      lessons = <Lesson>[];
      json['lessons'].forEach((v) {
        lessons!.add(Lesson.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['id'] = id;
    data['title'] = title;
    if (lessons != null) {
      data['lessons'] = lessons!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Lesson {
  String? id;
  String? title;
  String? contentType;
  String? textContent;
  List<Quiz>? quiz;
  bool? isCompleted;
  int? quizScore;
  String? completedAt;
  String? videoUrl;

  Lesson({
    this.id,
    this.title,
    this.contentType,
    this.textContent,
    this.quiz,
    this.isCompleted,
    this.quizScore,
    this.completedAt,
    this.videoUrl,
  });

  Lesson.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    title = json['title'];
    contentType = json['contentType'];
    textContent = json['textContent'];
    if (json['quiz'] != null) {
      quiz = <Quiz>[];
      json['quiz'].forEach((v) {
        quiz!.add(Quiz.fromJson(v));
      });
    }
    isCompleted = json['isCompleted'];
    quizScore = json['quizScore'];
    completedAt = json['completedAt'];
    videoUrl = json['videoUrl'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['id'] = id;
    data['title'] = title;
    data['contentType'] = contentType;
    data['textContent'] = textContent;
    if (quiz != null) {
      data['quiz'] = quiz!.map((v) => v.toJson()).toList();
    }
    data['isCompleted'] = isCompleted;
    data['quizScore'] = quizScore;
    data['completedAt'] = completedAt;
    data['videoUrl'] = videoUrl;
    return data;
  }
}

class Quiz {
  String? question;
  List<String>? options;
  String? correctAnswer;

  Quiz({this.question, this.options, this.correctAnswer});

  Quiz.fromJson(Map<String, dynamic> json) {
    question = json['question'];
    options = json['options'].cast<String>();
    correctAnswer = json['correctAnswer'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['question'] = this.question;
    data['options'] = this.options;
    data['correctAnswer'] = this.correctAnswer;
    return data;
  }
}

class Pagination {
  int? totalCourses;
  int? currentPage;
  int? totalPages;
  int? limit;

  Pagination(
      {this.totalCourses, this.currentPage, this.totalPages, this.limit});

  Pagination.fromJson(Map<String, dynamic> json) {
    totalCourses = json['totalCourses'];
    currentPage = json['currentPage'];
    totalPages = json['totalPages'];
    limit = json['limit'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['totalCourses'] = this.totalCourses;
    data['currentPage'] = this.currentPage;
    data['totalPages'] = this.totalPages;
    data['limit'] = this.limit;
    return data;
  }
}

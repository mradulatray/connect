class GetAllCreatorCourseSectionModel {
  String? sId;
  String? title;
  String? description;
  String? thumbnail;
  List<Sections>? sections;
  int? xpOnStart;
  int? xpOnCompletion;
  int? xpPerPerfectQuiz;
  int? xpOnLessonCompletion;
  CreatedBy? createdBy;
  bool? isPublished;
  int? coins;
  List<String>? tags;
  String? language;
  bool? isPaid;
  String? createdAt;
  String? updatedAt;
  int? iV;
  double? averageRating;
  int? totalReviews;

  GetAllCreatorCourseSectionModel(
      {this.sId,
      this.title,
      this.description,
      this.thumbnail,
      this.sections,
      this.xpOnStart,
      this.xpOnCompletion,
      this.xpPerPerfectQuiz,
      this.xpOnLessonCompletion,
      this.createdBy,
      this.isPublished,
      this.coins,
      this.tags,
      this.language,
      this.isPaid,
      this.createdAt,
      this.updatedAt,
      this.iV,
      this.averageRating,
      this.totalReviews});

  GetAllCreatorCourseSectionModel.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    title = json['title'];
    description = json['description'];
    thumbnail = json['thumbnail'];
    if (json['sections'] != null) {
      sections = <Sections>[];
      json['sections'].forEach((v) {
        sections!.add(Sections.fromJson(v));
      });
    }
    xpOnStart = json['xpOnStart'];
    xpOnCompletion = json['xpOnCompletion'];
    xpPerPerfectQuiz = json['xpPerPerfectQuiz'];
    xpOnLessonCompletion = json['xpOnLessonCompletion'];
    createdBy = json['createdBy'] != null
        ? CreatedBy.fromJson(json['createdBy'])
        : null;
    isPublished = json['isPublished'];
    coins = json['coins'];
    tags = json['tags'].cast<String>();
    language = json['language'];
    isPaid = json['isPaid'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
    averageRating = (json['averageRating'] as num?)?.toDouble();
    totalReviews = json['totalReviews'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['_id'] = this.sId;
    data['title'] = this.title;
    data['description'] = this.description;
    data['thumbnail'] = this.thumbnail;
    if (this.sections != null) {
      data['sections'] = this.sections!.map((v) => v.toJson()).toList();
    }
    data['xpOnStart'] = this.xpOnStart;
    data['xpOnCompletion'] = this.xpOnCompletion;
    data['xpPerPerfectQuiz'] = this.xpPerPerfectQuiz;
    data['xpOnLessonCompletion'] = this.xpOnLessonCompletion;
    if (this.createdBy != null) {
      data['createdBy'] = this.createdBy!.toJson();
    }
    data['isPublished'] = this.isPublished;
    data['coins'] = this.coins;
    data['tags'] = this.tags;
    data['language'] = this.language;
    data['isPaid'] = this.isPaid;
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    data['__v'] = this.iV;
    data['averageRating'] = this.averageRating;
    data['totalReviews'] = this.totalReviews;
    return data;
  }
}

class Sections {
  String? sId;
  String? title;
  List<Lessons>? lessons;
  int? iV;

  Sections({this.sId, this.title, this.lessons, this.iV});

  Sections.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    title = json['title'];
    if (json['lessons'] != null) {
      lessons = <Lessons>[];
      json['lessons'].forEach((v) {
        lessons!.add(Lessons.fromJson(v));
      });
    }
    iV = json['__v'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['_id'] = this.sId;
    data['title'] = this.title;
    if (this.lessons != null) {
      data['lessons'] = this.lessons!.map((v) => v.toJson()).toList();
    }
    data['__v'] = this.iV;
    return data;
  }
}

class Lessons {
  String? sId;
  String? title;
  String? description;
  String? contentType;
  String? textContent;
  List<Quiz>? quiz;
  String? updatedAt;
  int? iV;

  Lessons(
      {this.sId,
      this.title,
      this.description,
      this.contentType,
      this.textContent,
      this.quiz,
      this.updatedAt,
      this.iV});

  Lessons.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    title = json['title'];
    description = json['description'];
    contentType = json['contentType'];
    textContent = json['textContent'];
    if (json['quiz'] != null) {
      quiz = <Quiz>[];
      json['quiz'].forEach((v) {
        quiz!.add(Quiz.fromJson(v));
      });
    }
    updatedAt = json['updatedAt'];
    iV = json['__v'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['_id'] = this.sId;
    data['title'] = this.title;
    data['description'] = this.description;
    data['contentType'] = this.contentType;
    data['textContent'] = this.textContent;
    if (this.quiz != null) {
      data['quiz'] = this.quiz!.map((v) => v.toJson()).toList();
    }
    data['updatedAt'] = this.updatedAt;
    data['__v'] = this.iV;
    return data;
  }
}

class Quiz {
  String? question;
  List<String>? options;
  String? correctAnswer;
  String? sId;

  Quiz({this.question, this.options, this.correctAnswer, this.sId});

  Quiz.fromJson(Map<String, dynamic> json) {
    question = json['question'];
    options = json['options'].cast<String>();
    correctAnswer = json['correctAnswer'];
    sId = json['_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['question'] = this.question;
    data['options'] = this.options;
    data['correctAnswer'] = this.correctAnswer;
    data['_id'] = this.sId;
    return data;
  }
}

class CreatedBy {
  String? sId;
  String? fullName;
  String? email;

  CreatedBy({this.sId, this.fullName, this.email});

  CreatedBy.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    fullName = json['fullName'];
    email = json['email'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['_id'] = this.sId;
    data['fullName'] = this.fullName;
    data['email'] = this.email;
    return data;
  }
}

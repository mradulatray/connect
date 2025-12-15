class SearchCourseModel {
  bool? success;
  List<Data>? data;

  SearchCourseModel({this.success, this.data});

  SearchCourseModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    if (json['data'] != null) {
      data = <Data>[];
      json['data'].forEach((v) {
        data!.add(new Data.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Data {
  String? id;
  String? title;
  String? description;
  String? thumbnail;
  List<String>? tags;
  bool? isPaid;
  int? coins;
  Creator? creator;
  List<Sections>? sections;
  Ratings? ratings;
  bool? isEnrolled;

  Data(
      {this.id,
        this.title,
        this.description,
        this.thumbnail,
        this.tags,
        this.isPaid,
        this.coins,
        this.creator,
        this.sections,
        this.ratings,
        this.isEnrolled});

  Data.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    title = json['title'];
    description = json['description'];
    thumbnail = json['thumbnail'];
    tags = json['tags'].cast<String>();
    isPaid = json['isPaid'];
    coins = json['coins'];
    creator =
    json['creator'] != null ? new Creator.fromJson(json['creator']) : null;
    if (json['sections'] != null) {
      sections = <Sections>[];
      json['sections'].forEach((v) {
        sections!.add(new Sections.fromJson(v));
      });
    }
    ratings =
    json['ratings'] != null ? new Ratings.fromJson(json['ratings']) : null;
    isEnrolled = json['isEnrolled'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['title'] = this.title;
    data['description'] = this.description;
    data['thumbnail'] = this.thumbnail;
    data['tags'] = this.tags;
    data['isPaid'] = this.isPaid;
    data['coins'] = this.coins;
    if (this.creator != null) {
      data['creator'] = this.creator!.toJson();
    }
    if (this.sections != null) {
      data['sections'] = this.sections!.map((v) => v.toJson()).toList();
    }
    if (this.ratings != null) {
      data['ratings'] = this.ratings!.toJson();
    }
    data['isEnrolled'] = this.isEnrolled;
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
  String? sId;
  String? title;
  List<Lessons>? lessons;

  Sections({this.sId, this.title, this.lessons});

  Sections.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    title = json['title'];
    if (json['lessons'] != null) {
      lessons = <Lessons>[];
      json['lessons'].forEach((v) {
        lessons!.add(new Lessons.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    data['title'] = this.title;
    if (this.lessons != null) {
      data['lessons'] = this.lessons!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Lessons {
  String? sId;
  String? title;
  String? description;
  String? contentType;
  List<Quiz>? quiz;
  String? updatedAt;
  int? iV;
  String? textContent;
  String? videoUrl;

  Lessons(
      {this.sId,
        this.title,
        this.description,
        this.contentType,
        this.quiz,
        this.updatedAt,
        this.iV,
        this.textContent,
        this.videoUrl});

  Lessons.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    title = json['title'];
    description = json['description'];
    contentType = json['contentType'];
    if (json['quiz'] != null) {
      quiz = <Quiz>[];
      json['quiz'].forEach((v) {
        quiz!.add(new Quiz.fromJson(v));
      });
    }
    updatedAt = json['updatedAt'];
    iV = json['__v'];
    textContent = json['textContent'];
    videoUrl = json['videoUrl'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    data['title'] = this.title;
    data['description'] = this.description;
    data['contentType'] = this.contentType;
    if (this.quiz != null) {
      data['quiz'] = this.quiz!.map((v) => v.toJson()).toList();
    }
    data['updatedAt'] = this.updatedAt;
    data['__v'] = this.iV;
    data['textContent'] = this.textContent;
    data['videoUrl'] = this.videoUrl;
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
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['question'] = this.question;
    data['options'] = this.options;
    data['correctAnswer'] = this.correctAnswer;
    data['_id'] = this.sId;
    return data;
  }
}

class Ratings {
  double? avgRating;
  int? totalReviews;

  Ratings({this.avgRating, this.totalReviews});

  Ratings.fromJson(Map<String, dynamic> json) {
    final avg = json['avgRating'];
    if (avg is int) {
      avgRating = avg.toDouble();
    } else if (avg is double) {
      avgRating = avg;
    } else if (avg is String) {
      avgRating = double.tryParse(avg);
    } else {
      avgRating = null;
    }

    // totalReviews can safely stay int
    totalReviews = json['totalReviews'] is double
        ? (json['totalReviews'] as double).toInt()
        : json['totalReviews'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['avgRating'] = avgRating;
    data['totalReviews'] = totalReviews;
    return data;
  }
}
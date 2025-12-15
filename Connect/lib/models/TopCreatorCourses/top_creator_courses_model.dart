class TopCreatorCoursesModel {
  bool? success;
  Data? data;

  TopCreatorCoursesModel({this.success, this.data});

  TopCreatorCoursesModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    data = json['data'] != null ? new Data.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class Data {
  String? creatorId;
  int? reviewCount;
  double? avgRating;
  int? courseCount;
  int? totalScore;
  Creator? creator;
  List<Courses>? courses;

  Data(
      {this.creatorId,
        this.reviewCount,
        this.avgRating,
        this.courseCount,
        this.totalScore,
        this.creator,
        this.courses});

  Data.fromJson(Map<String, dynamic> json) {
    creatorId = json['creatorId'];
    reviewCount = json['reviewCount'];
    avgRating = (json['avgRating'] != null)
        ? (json['avgRating'] is int
        ? (json['avgRating'] as int).toDouble()
        : json['avgRating'] as double)
        : null;
    courseCount = json['courseCount'];
    totalScore = json['totalScore'];
    creator =
    json['creator'] != null ? new Creator.fromJson(json['creator']) : null;
    if (json['courses'] != null) {
      courses = <Courses>[];
      json['courses'].forEach((v) {
        courses!.add(new Courses.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['creatorId'] = this.creatorId;
    data['reviewCount'] = this.reviewCount;
    data['avgRating'] = this.avgRating;
    data['courseCount'] = this.courseCount;
    data['totalScore'] = this.totalScore;
    if (this.creator != null) {
      data['creator'] = this.creator!.toJson();
    }
    if (this.courses != null) {
      data['courses'] = this.courses!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Creator {
  String? sId;
  String? fullName;
  String? email;
  Avatar? avatar;
  String? id;

  Creator({this.sId, this.fullName, this.email, this.avatar, this.id});

  Creator.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    fullName = json['fullName'];
    email = json['email'];
    avatar =
    json['avatar'] != null ? new Avatar.fromJson(json['avatar']) : null;
    id = json['id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    data['fullName'] = this.fullName;
    data['email'] = this.email;
    if (this.avatar != null) {
      data['avatar'] = this.avatar!.toJson();
    }
    data['id'] = this.id;
    return data;
  }
}

class Avatar {
  String? sId;
  String? imageUrl;

  Avatar({this.sId, this.imageUrl});

  Avatar.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    imageUrl = json['imageUrl'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    data['imageUrl'] = this.imageUrl;
    return data;
  }
}

class Courses {
  String? sId;
  String? title;
  String? description;
  String? thumbnail;
  bool? isPublished;
  int? coins;
  String? createdAt;
  bool? isEnrolled;

  Courses(
      {this.sId,
        this.title,
        this.description,
        this.thumbnail,
        this.isPublished,
        this.coins,
        this.createdAt,
        this.isEnrolled});

  Courses.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    title = json['title'];
    description = json['description'];
    thumbnail = json['thumbnail'];
    isPublished = json['isPublished'];
    coins = json['coins'];
    createdAt = json['createdAt'];
    isEnrolled = json['isEnrolled'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    data['title'] = this.title;
    data['description'] = this.description;
    data['thumbnail'] = this.thumbnail;
    data['isPublished'] = this.isPublished;
    data['coins'] = this.coins;
    data['createdAt'] = this.createdAt;
    data['isEnrolled'] = this.isEnrolled;
    return data;
  }
}
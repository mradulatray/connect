class PopularCourseModel {
  bool? success;
  List<Data>? data;
  Pagination? pagination;

  PopularCourseModel({this.success, this.data, this.pagination});

  PopularCourseModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    if (json['data'] != null) {
      data = <Data>[];
      json['data'].forEach((v) {
        data!.add(new Data.fromJson(v));
      });
    }
    pagination = json['pagination'] != null
        ? new Pagination.fromJson(json['pagination'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    if (this.pagination != null) {
      data['pagination'] = this.pagination!.toJson();
    }
    return data;
  }
}

class Data {
  String? courseId;
  String? title;
  String? description;
  String? thumbnail;
  int? enrolledCount;
  int? coins;
  Creator? creator;
  Ratings? ratings;
  bool? isEnrolled;

  Data(
      {this.courseId,
      this.title,
      this.description,
      this.thumbnail,
      this.enrolledCount,
      this.coins,
      this.creator,
      this.ratings,
      this.isEnrolled});

  Data.fromJson(Map<String, dynamic> json) {
    courseId = json['courseId'];
    title = json['title'];
    description = json['description'];
    thumbnail = json['thumbnail'];
    enrolledCount = json['enrolledCount'];
    coins = json['coins'];
    creator =
        json['creator'] != null ? new Creator.fromJson(json['creator']) : null;
    ratings =
        json['ratings'] != null ? new Ratings.fromJson(json['ratings']) : null;
    isEnrolled = json['isEnrolled'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['courseId'] = this.courseId;
    data['title'] = this.title;
    data['description'] = this.description;
    data['thumbnail'] = this.thumbnail;
    data['enrolledCount'] = this.enrolledCount;
    data['coins'] = this.coins;
    if (this.creator != null) {
      data['creator'] = this.creator!.toJson();
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

class Ratings {
  double? avgRating;
  int? totalReviews;

  Ratings({this.avgRating, this.totalReviews});

  Ratings.fromJson(Map<String, dynamic> json) {
    avgRating = (json['avgRating'] != null)
        ? (json['avgRating'] as num).toDouble()
        : 0.0;
    totalReviews = json['totalReviews'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['avgRating'] = avgRating;
    data['totalReviews'] = totalReviews;
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

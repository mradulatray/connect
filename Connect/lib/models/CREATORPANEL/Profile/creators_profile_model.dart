class CreatorProfileModel {
  Creator? creator;
  Stats? stats;

  CreatorProfileModel({this.creator, this.stats});

  CreatorProfileModel.fromJson(Map<String, dynamic> json) {
    creator =
        json['creator'] != null ? new Creator.fromJson(json['creator']) : null;
    stats = json['stats'] != null ? new Stats.fromJson(json['stats']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.creator != null) {
      data['creator'] = this.creator!.toJson();
    }
    if (this.stats != null) {
      data['stats'] = this.stats!.toJson();
    }
    return data;
  }
}

class Creator {
  String? sId;
  String? fullName;
  String? username;
  String? email;
  Avatar? avatar;
  int? xp;
  int? level;

  Creator(
      {this.sId,
      this.fullName,
      this.username,
      this.email,
      this.avatar,
      this.xp,
      this.level});

  Creator.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    fullName = json['fullName'];
    username = json['username'];
    email = json['email'];
    avatar =
        json['avatar'] != null ? new Avatar.fromJson(json['avatar']) : null;
    xp = json['xp'];
    level = json['level'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    data['fullName'] = this.fullName;
    data['username'] = this.username;
    data['email'] = this.email;
    if (this.avatar != null) {
      data['avatar'] = this.avatar!.toJson();
    }
    data['xp'] = this.xp;
    data['level'] = this.level;
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

class Stats {
  int? totalCourses;
  int? activeCourses;
  int? totalEnrolledUsers;
  double? averageRating;
  int? totalGroups;
  List<GraphData>? graphData;
  List<RatingsPerCourse>? ratingsPerCourse;

  Stats(
      {this.totalCourses,
      this.activeCourses,
      this.totalEnrolledUsers,
      this.averageRating,
      this.totalGroups,
      this.graphData,
      this.ratingsPerCourse});

  Stats.fromJson(Map<String, dynamic> json) {
    totalCourses = json['totalCourses'];
    activeCourses = json['activeCourses'];
    totalEnrolledUsers = json['totalEnrolledUsers'];
    averageRating = (json['averageRating'] as num?)?.toDouble();
    totalGroups = json['totalGroups'];
    if (json['graphData'] != null) {
      graphData = <GraphData>[];
      json['graphData'].forEach((v) {
        graphData!.add(new GraphData.fromJson(v));
      });
    }
    if (json['ratingsPerCourse'] != null) {
      ratingsPerCourse = <RatingsPerCourse>[];
      json['ratingsPerCourse'].forEach((v) {
        ratingsPerCourse!.add(new RatingsPerCourse.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['totalCourses'] = this.totalCourses;
    data['activeCourses'] = this.activeCourses;
    data['totalEnrolledUsers'] = this.totalEnrolledUsers;
    data['averageRating'] = this.averageRating;
    data['totalGroups'] = this.totalGroups;
    if (this.graphData != null) {
      data['graphData'] = this.graphData!.map((v) => v.toJson()).toList();
    }
    if (this.ratingsPerCourse != null) {
      data['ratingsPerCourse'] =
          this.ratingsPerCourse!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class GraphData {
  String? courseId;
  String? courseTitle;
  int? enrolledUsers;

  GraphData({this.courseId, this.courseTitle, this.enrolledUsers});

  GraphData.fromJson(Map<String, dynamic> json) {
    courseId = json['courseId'];
    courseTitle = json['courseTitle'];
    enrolledUsers = json['enrolledUsers'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['courseId'] = this.courseId;
    data['courseTitle'] = this.courseTitle;
    data['enrolledUsers'] = this.enrolledUsers;
    return data;
  }
}

class RatingsPerCourse {
  String? courseId;
  String? courseTitle;
  double? averageRating;
  int? totalReviews;

  RatingsPerCourse({
    this.courseId,
    this.courseTitle,
    this.averageRating,
    this.totalReviews,
  });

  RatingsPerCourse.fromJson(Map<String, dynamic> json) {
    courseId = json['courseId'];
    courseTitle = json['courseTitle'];
    averageRating =
        (json['averageRating'] as num?)?.toDouble(); // Safely cast to double
    totalReviews = json['totalReviews'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['courseId'] = courseId;
    data['courseTitle'] = courseTitle;
    data['averageRating'] = averageRating;
    data['totalReviews'] = totalReviews;
    return data;
  }
}

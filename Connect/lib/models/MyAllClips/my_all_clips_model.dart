class MyAllClipsModel {
  String? message;
  List<Clips>? clips;

  MyAllClipsModel({this.message, this.clips});

  MyAllClipsModel.fromJson(Map<String, dynamic> json) {
    message = json['message'];
    if (json['clips'] != null) {
      clips = <Clips>[];
      json['clips'].forEach((v) {
        clips!.add(new Clips.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['message'] = this.message;
    if (this.clips != null) {
      data['clips'] = this.clips!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Clips {
  String? sId;
  String? userId;
  String? clipId;
  String? caption;
  List<String>? tags;
  String? status;
  String? createdAt;
  int? iV;
  String? originalFileName;
  String? processedKey;
  String? processedUrl;
  String? thumbnailKey;
  String? thumbnailUrl;
  bool? isPrivate;
  List<Comments>? comments;

  Clips(
      {this.sId,
      this.userId,
      this.clipId,
      this.caption,
      this.tags,
      this.status,
      this.createdAt,
      this.iV,
      this.originalFileName,
      this.processedKey,
      this.processedUrl,
      this.thumbnailKey,
      this.thumbnailUrl,
      this.isPrivate,
      this.comments});

  Clips.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    userId = json['userId'];
    clipId = json['clipId'];
    caption = json['caption'];
    tags = json['tags'].cast<String>();
    status = json['status'];
    createdAt = json['createdAt'];
    iV = json['__v'];
    originalFileName = json['originalFileName'];
    processedKey = json['processedKey'];
    processedUrl = json['processedUrl'];
    thumbnailKey = json['thumbnailKey'];
    thumbnailUrl = json['thumbnailUrl'];
    isPrivate = json['isPrivate'];
    if (json['comments'] != null) {
      comments = <Comments>[];
      json['comments'].forEach((v) {
        comments!.add(new Comments.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    data['userId'] = this.userId;
    data['clipId'] = this.clipId;
    data['caption'] = this.caption;
    data['tags'] = this.tags;
    data['status'] = this.status;
    data['createdAt'] = this.createdAt;
    data['__v'] = this.iV;
    data['originalFileName'] = this.originalFileName;
    data['processedKey'] = this.processedKey;
    data['processedUrl'] = this.processedUrl;
    data['thumbnailKey'] = this.thumbnailKey;
    data['thumbnailUrl'] = this.thumbnailUrl;
    data['isPrivate'] = this.isPrivate;
    if (this.comments != null) {
      data['comments'] = this.comments!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Comments {
  String? sId;
  String? clipId;
  UserId? userId;
  String? content;
  String? parentCommentId; // ✅ Fix here (was Null?)
  List<String>? likes; // ✅ Fix here (was List<Null>?)
  String? createdAt;
  int? iV;
  List<String>? replies; // ✅ Fix here (was List<Null>?)

  Comments({
    this.sId,
    this.clipId,
    this.userId,
    this.content,
    this.parentCommentId,
    this.likes,
    this.createdAt,
    this.iV,
    this.replies,
  });

  Comments.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    clipId = json['clipId'];
    userId = json['userId'] != null ? UserId.fromJson(json['userId']) : null;
    content = json['content'];
    parentCommentId = json['parentCommentId'];
    likes = json['likes'] != null ? List<String>.from(json['likes']) : [];
    createdAt = json['createdAt'];
    iV = json['__v'];
    replies = json['replies'] != null ? List<String>.from(json['replies']) : [];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['_id'] = sId;
    data['clipId'] = clipId;
    if (userId != null) {
      data['userId'] = userId!.toJson();
    }
    data['content'] = content;
    data['parentCommentId'] = parentCommentId;
    data['likes'] = likes;
    data['createdAt'] = createdAt;
    data['__v'] = iV;
    data['replies'] = replies;
    return data;
  }
}

class UserId {
  String? sId;
  String? fullName;
  String? username;
  Avatar? avatar;
  String? id;

  UserId({this.sId, this.fullName, this.username, this.avatar, this.id});

  UserId.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    fullName = json['fullName'];
    username = json['username'];
    avatar =
        json['avatar'] != null ? new Avatar.fromJson(json['avatar']) : null;
    id = json['id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    data['fullName'] = this.fullName;
    data['username'] = this.username;
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

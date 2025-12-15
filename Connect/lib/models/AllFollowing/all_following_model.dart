class AllFollowingModel {
  List<Following>? following;

  AllFollowingModel({this.following});

  AllFollowingModel.fromJson(Map<String, dynamic> json) {
    if (json['following'] != null) {
      following = <Following>[];
      json['following'].forEach((v) {
        following!.add(new Following.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.following != null) {
      data['following'] = this.following!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Following {
  String? sId;
  String? follower;
  Followings? following; // Changed from Following? to Followings?
  String? createdAt;
  String? updatedAt;
  int? iV;

  Following(
      {this.sId,
      this.follower,
      this.following,
      this.createdAt,
      this.updatedAt,
      this.iV});

  Following.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    follower = json['follower'];
    following = json['following'] != null
        ? new Followings.fromJson(
            json['following']) // Changed to Followings.fromJson
        : null;
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    data['follower'] = this.follower;
    if (this.following != null) {
      data['following'] =
          this.following!.toJson(); // Now calls Followings.toJson
    }
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    data['__v'] = this.iV;
    return data;
  }
}

class Followings {
  String? sId;
  String? fullName;
  Avatar? avatar;
  String? username;
  String? id;

  Followings({this.sId, this.fullName, this.avatar, this.username, this.id});

  Followings.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    fullName = json['fullName'];
    avatar =
        json['avatar'] != null ? new Avatar.fromJson(json['avatar']) : null;
    username = json['username'];
    id = json['id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    data['fullName'] = this.fullName;
    if (this.avatar != null) {
      data['avatar'] = this.avatar!.toJson();
    }
    data['username'] = this.username;
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

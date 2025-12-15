class AllSubscriptionPlanModel {
  bool? success;
  int? count;
  List<Data>? data;

  AllSubscriptionPlanModel({this.success, this.count, this.data});

  AllSubscriptionPlanModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    count = json['count'];
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
    data['count'] = this.count;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Data {
  String? sId;
  String? name;
  int? coins;
  String? duration;
  Features? features;
  bool? isPopular;
  bool? isActive;
  String? createdAt;
  String? updatedAt;
  int? iV;
  String? membershipType;

  Data(
      {this.sId,
      this.name,
      this.coins,
      this.duration,
      this.features,
      this.isPopular,
      this.isActive,
      this.createdAt,
      this.updatedAt,
      this.iV,
      this.membershipType});

  Data.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    name = json['name'];
    coins = json['coins'];
    duration = json['duration'];
    features = json['features'] != null
        ? new Features.fromJson(json['features'])
        : null;
    isPopular = json['isPopular'];
    isActive = json['isActive'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
    membershipType = json['membershipType'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    data['name'] = this.name;
    data['coins'] = this.coins;
    data['duration'] = this.duration;
    if (this.features != null) {
      data['features'] = this.features!.toJson();
    }
    data['isPopular'] = this.isPopular;
    data['isActive'] = this.isActive;
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    data['__v'] = this.iV;
    data['membershipType'] = this.membershipType;
    return data;
  }
}

class Features {
  int? reactionEmoji;
  int? stickerPack;
  int? publicGroup;
  bool? animatedAvatar;
  bool? premiumIcon;
  bool? sharedLiveLocation;
  int? fileUploadSize;
  String? premiumIconUrl;
  int? totalCourseCreation;

  Features(
      {this.reactionEmoji,
      this.stickerPack,
      this.publicGroup,
      this.animatedAvatar,
      this.premiumIcon,
      this.sharedLiveLocation,
      this.fileUploadSize,
      this.premiumIconUrl,
      this.totalCourseCreation});

  Features.fromJson(Map<String, dynamic> json) {
    reactionEmoji = json['reaction_emoji'];
    stickerPack = json['sticker_pack'];
    publicGroup = json['public_group'];
    animatedAvatar = json['animated_avatar'];
    premiumIcon = json['premium_icon'];
    sharedLiveLocation = json['shared_live_location'];
    fileUploadSize = json['file_upload_size'];
    premiumIconUrl = json['premiumIconUrl'];
    totalCourseCreation = json['total_course_creation'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['reaction_emoji'] = this.reactionEmoji;
    data['sticker_pack'] = this.stickerPack;
    data['public_group'] = this.publicGroup;
    data['animated_avatar'] = this.animatedAvatar;
    data['premium_icon'] = this.premiumIcon;
    data['shared_live_location'] = this.sharedLiveLocation;
    data['file_upload_size'] = this.fileUploadSize;
    data['premiumIconUrl'] = this.premiumIconUrl;
    data['total_course_creation'] = this.totalCourseCreation;
    return data;
  }
}

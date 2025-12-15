class MarketPlaceAvatarModel {
  String? message;
  Marketplace? marketplace;

  MarketPlaceAvatarModel({this.message, this.marketplace});

  MarketPlaceAvatarModel.fromJson(Map<String, dynamic> json) {
    message = json['message'];
    marketplace = json['marketplace'] != null
        ? new Marketplace.fromJson(json['marketplace'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['message'] = this.message;
    if (this.marketplace != null) {
      data['marketplace'] = this.marketplace!.toJson();
    }
    return data;
  }
}

class Marketplace {
  List<Avatars>? avatars;
  List<Collections>? collections;

  Marketplace({this.avatars, this.collections});

  Marketplace.fromJson(Map<String, dynamic> json) {
    if (json['avatars'] != null) {
      avatars = <Avatars>[];
      json['avatars'].forEach((v) {
        avatars!.add(new Avatars.fromJson(v));
      });
    }
    if (json['collections'] != null) {
      collections = <Collections>[];
      json['collections'].forEach((v) {
        collections!.add(new Collections.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.avatars != null) {
      data['avatars'] = this.avatars!.map((v) => v.toJson()).toList();
    }
    if (this.collections != null) {
      data['collections'] = this.collections!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Avatars {
  String? sId;
  String? name;
  String? description;
  String? avatar3dUrl;
  String? avatar2dUrl;
  int? coins;
  String? status;
  UserId? userId;
  String? createdAt;
  String? updatedAt;
  int? iV;
  bool? isOwnedByCurrentUser;
  int? price;

  Avatars(
      {this.sId,
      this.name,
      this.description,
      this.avatar3dUrl,
      this.avatar2dUrl,
      this.coins,
      this.status,
      this.userId,
      this.createdAt,
      this.updatedAt,
      this.iV,
      this.isOwnedByCurrentUser,
      this.price});

  Avatars.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    name = json['name'];
    description = json['description'];
    avatar3dUrl = json['Avatar3dUrl'];
    avatar2dUrl = json['Avatar2dUrl'];
    coins = json['coins'];
    status = json['status'];
    userId =
        json['userId'] != null ? new UserId.fromJson(json['userId']) : null;
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
    isOwnedByCurrentUser = json['isOwnedByCurrentUser'];
    price = json['price'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    data['name'] = this.name;
    data['description'] = this.description;
    data['Avatar3dUrl'] = this.avatar3dUrl;
    data['Avatar2dUrl'] = this.avatar2dUrl;
    data['coins'] = this.coins;
    data['status'] = this.status;
    if (this.userId != null) {
      data['userId'] = this.userId!.toJson();
    }
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    data['__v'] = this.iV;
    data['isOwnedByCurrentUser'] = this.isOwnedByCurrentUser;
    data['price'] = this.price;
    return data;
  }
}

class UserId {
  String? sId;
  String? fullName;
  String? username;
  Avatar? avatar;
  Subscription? subscription;
  SubscriptionFeatures? subscriptionFeatures;

  UserId(
      {this.sId,
      this.fullName,
      this.username,
      this.avatar,
      this.subscription,
      this.subscriptionFeatures});

  UserId.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    fullName = json['fullName'];
    username = json['username'];
    avatar =
        json['avatar'] != null ? new Avatar.fromJson(json['avatar']) : null;
    subscription = json['subscription'] != null
        ? new Subscription.fromJson(json['subscription'])
        : null;
    subscriptionFeatures = json['subscriptionFeatures'] != null
        ? new SubscriptionFeatures.fromJson(json['subscriptionFeatures'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    data['fullName'] = this.fullName;
    data['username'] = this.username;
    if (this.avatar != null) {
      data['avatar'] = this.avatar!.toJson();
    }
    if (this.subscription != null) {
      data['subscription'] = this.subscription!.toJson();
    }
    if (this.subscriptionFeatures != null) {
      data['subscriptionFeatures'] = this.subscriptionFeatures!.toJson();
    }
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

class Subscription {
  String? status;
  String? planId;
  String? startDate;
  String? endDate;

  Subscription({this.status, this.planId, this.startDate, this.endDate});

  Subscription.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    planId = json['planId'];
    startDate = json['startDate'];
    endDate = json['endDate'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['status'] = this.status;
    data['planId'] = this.planId;
    data['startDate'] = this.startDate;
    data['endDate'] = this.endDate;
    return data;
  }
}

class SubscriptionFeatures {
  String? premiumIconUrl;

  SubscriptionFeatures({this.premiumIconUrl});

  SubscriptionFeatures.fromJson(Map<String, dynamic> json) {
    premiumIconUrl = json['premiumIconUrl'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['premiumIconUrl'] = this.premiumIconUrl;
    return data;
  }
}

class Collections {
  String? sId;
  String? name;
  String? description;
  Creator? creator;
  List<Avatars>? avatars;
  int? coins;
  bool? isPublished;
  String? createdAt;
  String? updatedAt;
  int? iV;

  Collections(
      {this.sId,
      this.name,
      this.description,
      this.creator,
      this.avatars,
      this.coins,
      this.isPublished,
      this.createdAt,
      this.updatedAt,
      this.iV});

  Collections.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    name = json['name'];
    description = json['description'];
    creator =
        json['creator'] != null ? new Creator.fromJson(json['creator']) : null;
    if (json['avatars'] != null) {
      avatars = <Avatars>[];
      json['avatars'].forEach((v) {
        avatars!.add(new Avatars.fromJson(v));
      });
    }
    coins = json['coins'];
    isPublished = json['isPublished'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    data['name'] = this.name;
    data['description'] = this.description;
    if (this.creator != null) {
      data['creator'] = this.creator!.toJson();
    }
    if (this.avatars != null) {
      data['avatars'] = this.avatars!.map((v) => v.toJson()).toList();
    }
    data['coins'] = this.coins;
    data['isPublished'] = this.isPublished;
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    data['__v'] = this.iV;
    return data;
  }
}

class Creator {
  SubscriptionFeatures? subscriptionFeatures;
  String? sId;
  String? fullName;
  String? username;
  Avatar? avatar;
  String? id;

  Creator(
      {this.subscriptionFeatures,
      this.sId,
      this.fullName,
      this.username,
      this.avatar,
      this.id});

  Creator.fromJson(Map<String, dynamic> json) {
    subscriptionFeatures = json['subscriptionFeatures'] != null
        ? new SubscriptionFeatures.fromJson(json['subscriptionFeatures'])
        : null;
    sId = json['_id'];
    fullName = json['fullName'];
    username = json['username'];
    avatar =
        json['avatar'] != null ? new Avatar.fromJson(json['avatar']) : null;
    id = json['id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.subscriptionFeatures != null) {
      data['subscriptionFeatures'] = this.subscriptionFeatures!.toJson();
    }
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

class Avatarss {
  String? sId;
  String? name;
  String? description;
  String? avatar3dUrl;
  String? avatar2dUrl;

  Avatarss(
      {this.sId,
      this.name,
      this.description,
      this.avatar3dUrl,
      this.avatar2dUrl});

  Avatarss.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    name = json['name'];
    description = json['description'];
    avatar3dUrl = json['Avatar3dUrl'];
    avatar2dUrl = json['Avatar2dUrl'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    data['name'] = this.name;
    data['description'] = this.description;
    data['Avatar3dUrl'] = this.avatar3dUrl;
    data['Avatar2dUrl'] = this.avatar2dUrl;
    return data;
  }
}

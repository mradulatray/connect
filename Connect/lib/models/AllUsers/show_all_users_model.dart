class ShowAllUsersModel {
  List<Users>? users;

  ShowAllUsersModel({this.users});

  ShowAllUsersModel.fromJson(Map<String, dynamic> json) {
    if (json['users'] != null) {
      users = <Users>[];
      json['users'].forEach((v) {
        users!.add(new Users.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.users != null) {
      data['users'] = this.users!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Users {
  Wallet? wallet;
  Subscription? subscription;
  SubscriptionFeatures? subscriptionFeatures;
  String? sId;
  String? fullName;
  String? username;
  String? email;
  Avatar? avatar;
  String? role;
  int? xp;
  int? level;
  List<Badges>? badges;
  String? id;

  Users(
      {this.wallet,
      this.subscription,
      this.subscriptionFeatures,
      this.sId,
      this.fullName,
      this.username,
      this.email,
      this.avatar,
      this.role,
      this.xp,
      this.level,
      this.badges,
      this.id});

  Users.fromJson(Map<String, dynamic> json) {
    wallet =
        json['wallet'] != null ? new Wallet.fromJson(json['wallet']) : null;
    subscription = json['subscription'] != null
        ? new Subscription.fromJson(json['subscription'])
        : null;
    subscriptionFeatures = json['subscriptionFeatures'] != null
        ? new SubscriptionFeatures.fromJson(json['subscriptionFeatures'])
        : null;
    sId = json['_id'];
    fullName = json['fullName'];
    username = json['username'];
    email = json['email'];
    avatar =
        json['avatar'] != null ? new Avatar.fromJson(json['avatar']) : null;
    role = json['role'];
    xp = json['xp'];
    level = json['level'];
    if (json['badges'] != null) {
      badges = <Badges>[];
      json['badges'].forEach((v) {
        badges!.add(new Badges.fromJson(v));
      });
    }
    id = json['id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.wallet != null) {
      data['wallet'] = this.wallet!.toJson();
    }
    if (this.subscription != null) {
      data['subscription'] = this.subscription!.toJson();
    }
    if (this.subscriptionFeatures != null) {
      data['subscriptionFeatures'] = this.subscriptionFeatures!.toJson();
    }
    data['_id'] = this.sId;
    data['fullName'] = this.fullName;
    data['username'] = this.username;
    data['email'] = this.email;
    if (this.avatar != null) {
      data['avatar'] = this.avatar!.toJson();
    }
    data['role'] = this.role;
    data['xp'] = this.xp;
    data['level'] = this.level;
    if (this.badges != null) {
      data['badges'] = this.badges!.map((v) => v.toJson()).toList();
    }
    data['id'] = this.id;
    return data;
  }
}

class Wallet {
  int? coins;

  Wallet({this.coins});

  Wallet.fromJson(Map<String, dynamic> json) {
    coins = json['coins'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['coins'] = this.coins;
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

class Badges {
  String? sId;
  String? name;

  Badges({this.sId, this.name});

  Badges.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    name = json['name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    data['name'] = this.name;
    return data;
  }
}

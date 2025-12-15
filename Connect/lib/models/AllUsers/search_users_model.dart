class AllUsersModel {
  List<SearchedUser>? searchedUser;

  AllUsersModel({this.searchedUser});

  AllUsersModel.fromJson(Map<String, dynamic> json) {
    if (json['searchedUser'] != null) {
      searchedUser = <SearchedUser>[];
      json['searchedUser'].forEach((v) {
        searchedUser!.add(new SearchedUser.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.searchedUser != null) {
      data['searchedUser'] = this.searchedUser!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class SearchedUser {
  SocialLinks? socialLinks;
  Wallet? wallet;
  Subscription? subscription;
  SubscriptionFeatures? subscriptionFeatures;
  String? sId;
  String? fullName;
  String? email;
  Avatar? avatar;
  int? xp;
  int? level;
  List<Badges>? badges;
  String? bio;
  String? username;
  List<String>? blockedUsers;
  String? id;

  SearchedUser(
      {this.socialLinks,
      this.wallet,
      this.subscription,
      this.subscriptionFeatures,
      this.sId,
      this.fullName,
      this.email,
      this.avatar,
      this.xp,
      this.level,
      this.badges,
      this.bio,
      this.username,
      this.blockedUsers,
      this.id});

  SearchedUser.fromJson(Map<String, dynamic> json) {
    socialLinks = json['socialLinks'] != null
        ? new SocialLinks.fromJson(json['socialLinks'])
        : null;
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
    email = json['email'];
    avatar =
        json['avatar'] != null ? new Avatar.fromJson(json['avatar']) : null;
    xp = json['xp'];
    level = json['level'];
    if (json['badges'] != null) {
      badges = <Badges>[];
      json['badges'].forEach((v) {
        badges!.add(new Badges.fromJson(v));
      });
    }
    bio = json['bio'];
    username = json['username'];
    blockedUsers = json['blockedUsers'].cast<String>();
    id = json['id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.socialLinks != null) {
      data['socialLinks'] = this.socialLinks!.toJson();
    }
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
    data['email'] = this.email;
    if (this.avatar != null) {
      data['avatar'] = this.avatar!.toJson();
    }
    data['xp'] = this.xp;
    data['level'] = this.level;
    if (this.badges != null) {
      data['badges'] = this.badges!.map((v) => v.toJson()).toList();
    }
    data['bio'] = this.bio;
    data['username'] = this.username;
    data['blockedUsers'] = this.blockedUsers;
    data['id'] = this.id;
    return data;
  }
}

class SocialLinks {
  String? linkedin;
  String? twitter;
  String? instagram;
  String? website;

  SocialLinks({this.linkedin, this.twitter, this.instagram, this.website});

  SocialLinks.fromJson(Map<String, dynamic> json) {
    linkedin = json['linkedin'];
    twitter = json['twitter'];
    instagram = json['instagram'];
    website = json['website'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['linkedin'] = this.linkedin;
    data['twitter'] = this.twitter;
    data['instagram'] = this.instagram;
    data['website'] = this.website;
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
  String? endDate;
  String? planId;
  String? startDate;
  String? status;

  Subscription({this.endDate, this.planId, this.startDate, this.status});

  Subscription.fromJson(Map<String, dynamic> json) {
    endDate = json['endDate'];
    planId = json['planId'];
    startDate = json['startDate'];
    status = json['status'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['endDate'] = this.endDate;
    data['planId'] = this.planId;
    data['startDate'] = this.startDate;
    data['status'] = this.status;
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
  String? iconUrl;

  Badges({this.sId, this.name, this.iconUrl});

  Badges.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    name = json['name'];
    iconUrl = json['iconUrl'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    data['name'] = this.name;
    data['iconUrl'] = this.iconUrl;
    return data;
  }
}

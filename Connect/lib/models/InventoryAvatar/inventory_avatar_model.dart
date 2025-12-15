class InventoryAvatarModel {
  bool? success;
  Inventory? inventory;

  InventoryAvatarModel({this.success, this.inventory});

  InventoryAvatarModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    inventory = json['inventory'] != null
        ? new Inventory.fromJson(json['inventory'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    if (this.inventory != null) {
      data['inventory'] = this.inventory!.toJson();
    }
    return data;
  }
}

class Inventory {
  List<Avatars>? avatars;
  List<Collection>? collection;

  Inventory({this.avatars, this.collection});

  Inventory.fromJson(Map<String, dynamic> json) {
    if (json['avatars'] != null) {
      avatars = <Avatars>[];
      json['avatars'].forEach((v) {
        avatars!.add(new Avatars.fromJson(v));
      });
    }
    if (json['collection'] != null) {
      collection = <Collection>[];
      json['collection'].forEach((v) {
        collection!.add(new Collection.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.avatars != null) {
      data['avatars'] = this.avatars!.map((v) => v.toJson()).toList();
    }
    if (this.collection != null) {
      data['collection'] = this.collection!.map((v) => v.toJson()).toList();
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
  String? userId;
  String? createdAt;
  String? updatedAt;
  int? iV;

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
      this.iV});

  Avatars.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    name = json['name'];
    description = json['description'];
    avatar3dUrl = json['Avatar3dUrl'];
    avatar2dUrl = json['Avatar2dUrl'];
    coins = json['coins'];
    status = json['status'];
    userId = json['userId'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
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
    data['userId'] = this.userId;
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    data['__v'] = this.iV;
    return data;
  }
}

class Collection {
  String? sId;
  String? name;
  String? description;
  String? creator;
  List<Avatars>? avatars;
  int? coins;
  bool? isPublished;
  String? createdAt;
  String? updatedAt;
  int? iV;

  Collection(
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

  Collection.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    name = json['name'];
    description = json['description'];
    creator = json['creator'];
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
    data['creator'] = this.creator;
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

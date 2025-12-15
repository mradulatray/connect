class BuyCoinsModel {
  List<Packages>? packages;

  BuyCoinsModel({this.packages});

  BuyCoinsModel.fromJson(Map<String, dynamic> json) {
    if (json['packages'] != null) {
      packages = <Packages>[];
      json['packages'].forEach((v) {
        packages!.add(new Packages.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.packages != null) {
      data['packages'] = this.packages!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Packages {
  String? sId;
  String? title;
  int? coins;
  double? price;
  bool? isActive;
  String? description;
  String? createdAt;
  int? iV;

  Packages(
      {this.sId,
      this.title,
      this.coins,
      this.price,
      this.isActive,
      this.description,
      this.createdAt,
      this.iV});

  Packages.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    title = json['title'];
    coins = json['coins'];
    // price = json['price'];
    price = (json['price'] != null)
        ? (json['price'] is num ? json['price'].toDouble() : null)
        : null;
    isActive = json['isActive'];
    description = json['description'];
    createdAt = json['createdAt'];
    iV = json['__v'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    data['title'] = this.title;
    data['coins'] = this.coins;
    data['price'] = this.price;
    data['isActive'] = this.isActive;
    data['description'] = this.description;
    data['createdAt'] = this.createdAt;
    data['__v'] = this.iV;
    return data;
  }
}

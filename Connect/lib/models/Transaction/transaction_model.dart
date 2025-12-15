class UserTransactionModel {
  List<Transactions>? transactions;
  int? total;
  int? page;
  int? limit;

  UserTransactionModel({this.transactions, this.total, this.page, this.limit});

  UserTransactionModel.fromJson(Map<String, dynamic> json) {
    if (json['transactions'] != null) {
      transactions = <Transactions>[];
      json['transactions'].forEach((v) {
        transactions!.add(new Transactions.fromJson(v));
      });
    }
    total = json['total'];
    page = json['page'];
    limit = json['limit'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.transactions != null) {
      data['transactions'] = this.transactions!.map((v) => v.toJson()).toList();
    }
    data['total'] = this.total;
    data['page'] = this.page;
    data['limit'] = this.limit;
    return data;
  }
}

class Transactions {
  Meta? meta;
  String? sId;
  String? userId;
  String? role;
  String? type;
  int? coins;
  String? method;
  String? source;
  String? status;
  String? createdAt;
  int? iV;

  Transactions(
      {this.meta,
      this.sId,
      this.userId,
      this.role,
      this.type,
      this.coins,
      this.method,
      this.source,
      this.status,
      this.createdAt,
      this.iV});

  Transactions.fromJson(Map<String, dynamic> json) {
    meta = json['meta'] != null ? new Meta.fromJson(json['meta']) : null;
    sId = json['_id'];
    userId = json['userId'];
    role = json['role'];
    type = json['type'];
    coins = json['coins'];
    method = json['method'];
    source = json['source'];
    status = json['status'];
    createdAt = json['createdAt'];
    iV = json['__v'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.meta != null) {
      data['meta'] = this.meta!.toJson();
    }
    data['_id'] = this.sId;
    data['userId'] = this.userId;
    data['role'] = this.role;
    data['type'] = this.type;
    data['coins'] = this.coins;
    data['method'] = this.method;
    data['source'] = this.source;
    data['status'] = this.status;
    data['createdAt'] = this.createdAt;
    data['__v'] = this.iV;
    return data;
  }
}

class Meta {
  String? referenceId;
  String? description;

  Meta({this.referenceId, this.description});

  Meta.fromJson(Map<String, dynamic> json) {
    referenceId = json['referenceId'];
    description = json['description'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['referenceId'] = this.referenceId;
    data['description'] = this.description;
    return data;
  }
}

class NotificationModel {
  List<Notifications>? notifications;
  int? unreadCount;

  NotificationModel({this.notifications, this.unreadCount});

  NotificationModel.fromJson(Map<String, dynamic> json) {
    if (json['notifications'] != null) {
      notifications = <Notifications>[];
      json['notifications'].forEach((v) {
        notifications!.add(new Notifications.fromJson(v));
      });
    }
    unreadCount = json['unreadCount'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.notifications != null) {
      data['notifications'] =
          this.notifications!.map((v) => v.toJson()).toList();
    }
    data['unreadCount'] = this.unreadCount;
    return data;
  }
}

class Notifications {
  String? sId;
  UserId? userId;
  String? title;
  String? message;
  String? type;
  bool? isRead;
  String? fromUserId;
  String? clipId;
  String? createdAt;
  int? iV;

  Notifications(
      {this.sId,
      this.userId,
      this.title,
      this.message,
      this.type,
      this.isRead,
      this.fromUserId,
      this.clipId,
      this.createdAt,
      this.iV});

  Notifications.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    userId =
        json['userId'] != null ? new UserId.fromJson(json['userId']) : null;
    title = json['title'];
    message = json['message'];
    type = json['type'];
    isRead = json['isRead'];
    fromUserId = json['fromUserId'];
    clipId = json['clipId'];
    createdAt = json['createdAt'];
    iV = json['__v'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    if (this.userId != null) {
      data['userId'] = this.userId!.toJson();
    }
    data['title'] = this.title;
    data['message'] = this.message;
    data['type'] = this.type;
    data['isRead'] = this.isRead;
    data['fromUserId'] = this.fromUserId;
    data['clipId'] = this.clipId;
    data['createdAt'] = this.createdAt;
    data['__v'] = this.iV;
    return data;
  }
}

class UserId {
  String? sId;
  String? fullName;
  String? id;

  UserId({this.sId, this.fullName, this.id});

  UserId.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    fullName = json['fullName'];
    id = json['id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    data['fullName'] = this.fullName;
    data['id'] = this.id;
    return data;
  }
}

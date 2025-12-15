class JoinSpaceModel {
  bool? success;
  String? message;
  String? roomUrl;

  JoinSpaceModel({this.success, this.message, this.roomUrl});

  JoinSpaceModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    roomUrl = json['roomUrl'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    data['message'] = this.message;
    data['roomUrl'] = this.roomUrl;
    return data;
  }
}

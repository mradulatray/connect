class ClipRepostByUser {
  String? message;
  List<Clips>? clips;

  ClipRepostByUser({this.message, this.clips});

  ClipRepostByUser.fromJson(Map<String, dynamic> json) {
    message = json['message'];
    if (json['clips'] != null) {
      clips = <Clips>[];
      json['clips'].forEach((v) {
        clips!.add(new Clips.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['message'] = this.message;
    if (this.clips != null) {
      data['clips'] = this.clips!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Clips {
  String? sId;
  String? caption;
  List<String>? tags;
  String? processedUrl;
  String? thumbnailUrl;

  Clips(
      {this.sId,
      this.caption,
      this.tags,
      this.processedUrl,
      this.thumbnailUrl});

  Clips.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    caption = json['caption'];
    tags = json['tags'].cast<String>();
    processedUrl = json['processedUrl'];
    thumbnailUrl = json['thumbnailUrl'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    data['caption'] = this.caption;
    data['tags'] = this.tags;
    data['processedUrl'] = this.processedUrl;
    data['thumbnailUrl'] = this.thumbnailUrl;
    return data;
  }
}

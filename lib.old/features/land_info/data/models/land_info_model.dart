class LandInfoData {
  final List<LandTopic> topics;

  LandInfoData({required this.topics});

  factory LandInfoData.fromJson(Map<String, dynamic> json) {
    return LandInfoData(
      topics: (json['topics'] as List)
          .map((e) => LandTopic.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class LandTopic {
  final String id;
  final String title;
  final String? description;
  final String? thumbnail;
  final List<ContentBlock> content;

  LandTopic({
    required this.id,
    required this.title,
    this.description,
    this.thumbnail,
    required this.content,
  });

  factory LandTopic.fromJson(Map<String, dynamic> json) {
    return LandTopic(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      thumbnail: json['thumbnail'] as String?,
      content: (json['content'] as List)
          .map((e) => ContentBlock.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ContentBlock {
  final String type;
  final String? text;
  final String? title; // For bullet_point
  final List<String>? items; // For bullet_list
  final String? url; // For image
  final String? source; // For image (asset/network)
  final String? caption; // For image
  final List<String>? headers; // For table
  final List<List<String>>? rows; // For table

  ContentBlock({
    required this.type,
    this.text,
    this.title,
    this.items,
    this.url,
    this.source,
    this.caption,
    this.headers,
    this.rows,
  });

  factory ContentBlock.fromJson(Map<String, dynamic> json) {
    return ContentBlock(
      type: json['type'] as String,
      text: json['text'] as String?,
      title: json['title'] as String?,
      items: (json['items'] as List?)?.map((e) => e as String).toList(),
      url: json['url'] as String?,
      source: json['source'] as String?,
      caption: json['caption'] as String?,
      headers: (json['headers'] as List?)?.map((e) => e as String).toList(),
      rows: (json['rows'] as List?)
          ?.map((e) => (e as List).map((i) => i as String).toList())
          .toList(),
    );
  }
}

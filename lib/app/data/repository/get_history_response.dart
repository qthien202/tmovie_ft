// To parse this JSON data, do
//
//     final getHistoryRespone = getHistoryResponeFromJson(jsonString);

import 'dart:convert';

GetHistoryRespone getHistoryResponeFromJson(String str) =>
    GetHistoryRespone.fromJson(json.decode(str));

String getHistoryResponeToJson(GetHistoryRespone data) =>
    json.encode(data.toJson());

class GetHistoryRespone {
  List<Datum> data;
  int total;

  GetHistoryRespone({
    required this.data,
    required this.total,
  });

  factory GetHistoryRespone.fromJson(Map<String, dynamic> json) =>
      GetHistoryRespone(
        data: List<Datum>.from(json["data"].map((x) => Datum.fromJson(x))),
        total: json["total"],
      );

  Map<String, dynamic> toJson() => {
        "data": List<dynamic>.from(data.map((x) => x.toJson())),
        "total": total,
      };
}

class Datum {
  String id;
  String name;
  String slug;
  String thumbnailUrl;
  String originName;
  String episode;
  String description;
  String userId;

  Datum({
    required this.id,
    required this.name,
    required this.slug,
    required this.thumbnailUrl,
    required this.originName,
    required this.episode,
    required this.description,
    required this.userId,
  });

  factory Datum.fromJson(Map<String, dynamic> json) => Datum(
        id: json["id"],
        name: json["name"],
        slug: json["slug"],
        thumbnailUrl: json["thumbnail_url"],
        originName: json["origin_name"],
        episode: json["episode"],
        description: json["description"],
        userId: json["user_id"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "slug": slug,
        "thumbnail_url": thumbnailUrl,
        "origin_name": originName,
        "episode": episode,
        "description": description,
        "user_id": userId,
      };
}

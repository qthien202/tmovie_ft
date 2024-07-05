// To parse this JSON data, do
//
//     final postAddHistory = postAddHistoryFromJson(jsonString);

import 'dart:convert';

PostAddHistory postAddHistoryFromJson(String str) =>
    PostAddHistory.fromJson(json.decode(str));

String postAddHistoryToJson(PostAddHistory data) => json.encode(data.toJson());

class PostAddHistory {
  String userToken;
  String name;
  String slug;
  String thumbnail;
  String originName;
  String episode;
  String description;

  PostAddHistory({
    required this.userToken,
    required this.name,
    required this.slug,
    required this.thumbnail,
    required this.originName,
    required this.episode,
    required this.description,
  });

  factory PostAddHistory.fromJson(Map<String, dynamic> json) => PostAddHistory(
        userToken: json["user_token"],
        name: json["name"],
        slug: json["slug"],
        thumbnail: json["thumbnail"],
        originName: json["origin_name"],
        episode: json["episode"],
        description: json["description"],
      );

  Map<String, dynamic> toJson() => {
        "user_token": userToken,
        "name": name,
        "slug": slug,
        "thumbnail": thumbnail,
        "origin_name": originName,
        "episode": episode,
        "description": description,
      };
}

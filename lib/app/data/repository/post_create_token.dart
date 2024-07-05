// To parse this JSON data, do
//
//     final postCreateToken = postCreateTokenFromJson(jsonString);

import 'dart:convert';

PostCreateToken postCreateTokenFromJson(String str) =>
    PostCreateToken.fromJson(json.decode(str));

String postCreateTokenToJson(PostCreateToken data) =>
    json.encode(data.toJson());

class PostCreateToken {
  String userToken;

  PostCreateToken({
    required this.userToken,
  });

  factory PostCreateToken.fromJson(Map<String, dynamic> json) =>
      PostCreateToken(
        userToken: json["user_token"],
      );

  Map<String, dynamic> toJson() => {
        "user_token": userToken,
      };
}

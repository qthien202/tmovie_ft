// To parse this JSON data, do
//
//     final postCreateTokenResponse = postCreateTokenResponseFromJson(jsonString);

import 'dart:convert';

PostCreateTokenResponse postCreateTokenResponseFromJson(String str) =>
    PostCreateTokenResponse.fromJson(json.decode(str));

String postCreateTokenResponseToJson(PostCreateTokenResponse data) =>
    json.encode(data.toJson());

class PostCreateTokenResponse {
  int status;
  String message;
  String token;

  PostCreateTokenResponse({
    required this.status,
    required this.message,
    required this.token,
  });

  factory PostCreateTokenResponse.fromJson(Map<String, dynamic> json) =>
      PostCreateTokenResponse(
        status: json["status"],
        message: json["message"],
        token: json["token"],
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "message": message,
        "token": token,
      };
}

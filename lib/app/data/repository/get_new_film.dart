// To parse this JSON data, do
//
//     final getNewFilm = getNewFilmFromJson(jsonString);

import 'dart:convert';

GetNewFilm getNewFilmFromJson(String str) =>
    GetNewFilm.fromJson(json.decode(str));

String getNewFilmToJson(GetNewFilm data) => json.encode(data.toJson());

class GetNewFilm {
  bool status;
  List<Item> items;
  String pathImage;
  Pagination pagination;

  GetNewFilm({
    required this.status,
    required this.items,
    required this.pathImage,
    required this.pagination,
  });

  factory GetNewFilm.fromJson(Map<String, dynamic> json) => GetNewFilm(
        status: json["status"],
        items: List<Item>.from(json["items"].map((x) => Item.fromJson(x))),
        pathImage: json["pathImage"],
        pagination: Pagination.fromJson(json["pagination"]),
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "items": List<dynamic>.from(items.map((x) => x.toJson())),
        "pathImage": pathImage,
        "pagination": pagination.toJson(),
      };
}

class Item {
  Modified modified;
  String id;
  String name;
  String slug;
  String originName;
  String thumbUrl;
  String posterUrl;
  int year;

  Item({
    required this.modified,
    required this.id,
    required this.name,
    required this.slug,
    required this.originName,
    required this.thumbUrl,
    required this.posterUrl,
    required this.year,
  });

  factory Item.fromJson(Map<String, dynamic> json) => Item(
        modified: Modified.fromJson(json["modified"]),
        id: json["_id"],
        name: json["name"],
        slug: json["slug"],
        originName: json["origin_name"],
        thumbUrl: json["thumb_url"],
        posterUrl: json["poster_url"],
        year: json["year"],
      );

  Map<String, dynamic> toJson() => {
        "modified": modified.toJson(),
        "_id": id,
        "name": name,
        "slug": slug,
        "origin_name": originName,
        "thumb_url": thumbUrl,
        "poster_url": posterUrl,
        "year": year,
      };
}

class Modified {
  DateTime time;

  Modified({
    required this.time,
  });

  factory Modified.fromJson(Map<String, dynamic> json) => Modified(
        time: DateTime.parse(json["time"]),
      );

  Map<String, dynamic> toJson() => {
        "time": time.toIso8601String(),
      };
}

class Pagination {
  int totalItems;
  int totalItemsPerPage;
  int currentPage;
  int totalPages;

  Pagination({
    required this.totalItems,
    required this.totalItemsPerPage,
    required this.currentPage,
    required this.totalPages,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) => Pagination(
        totalItems: json["totalItems"],
        totalItemsPerPage: json["totalItemsPerPage"],
        currentPage: json["currentPage"],
        totalPages: json["totalPages"],
      );

  Map<String, dynamic> toJson() => {
        "totalItems": totalItems,
        "totalItemsPerPage": totalItemsPerPage,
        "currentPage": currentPage,
        "totalPages": totalPages,
      };
}

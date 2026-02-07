import 'package:json_annotation/json_annotation.dart';

part 'pagination.g.dart';

@JsonSerializable()
class Pagination {
  final int? totalItems;
  final int? totalItemsPerPage;
  final int? currentPage;
  final int? pageRanges;

  const Pagination({
    this.totalItems,
    this.totalItemsPerPage,
    this.currentPage,
    this.pageRanges,
  });

  int get totalPages {
    if (totalItems == null || totalItemsPerPage == null || totalItemsPerPage == 0) return 0;
    return (totalItems! / totalItemsPerPage!).ceil();
  }

  factory Pagination.fromJson(Map<String, dynamic> json) => _$PaginationFromJson(json);
  Map<String, dynamic> toJson() => _$PaginationToJson(this);
}

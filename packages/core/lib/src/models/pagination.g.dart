// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pagination.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Pagination _$PaginationFromJson(Map<String, dynamic> json) => Pagination(
  totalItems: (json['totalItems'] as num?)?.toInt(),
  totalItemsPerPage: (json['totalItemsPerPage'] as num?)?.toInt(),
  currentPage: (json['currentPage'] as num?)?.toInt(),
  pageRanges: (json['pageRanges'] as num?)?.toInt(),
);

Map<String, dynamic> _$PaginationToJson(Pagination instance) =>
    <String, dynamic>{
      'totalItems': instance.totalItems,
      'totalItemsPerPage': instance.totalItemsPerPage,
      'currentPage': instance.currentPage,
      'pageRanges': instance.pageRanges,
    };

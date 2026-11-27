import '../core/utils/json_helpers.dart';

class PaginationMeta {
  const PaginationMeta({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
    required this.from,
    required this.to,
    required this.hasMorePages,
  });

  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;
  final int? from;
  final int? to;
  final bool hasMorePages;

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      currentPage: asInt(json['current_page'], fallback: 1),
      lastPage: asInt(json['last_page'], fallback: 1),
      perPage: asInt(json['per_page'], fallback: 12),
      total: asInt(json['total']),
      from: asNullableInt(json['from']),
      to: asNullableInt(json['to']),
      hasMorePages: asBool(json['has_more_pages']),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'current_page': currentPage,
        'last_page': lastPage,
        'per_page': perPage,
        'total': total,
        'from': from,
        'to': to,
        'has_more_pages': hasMorePages,
      };
}

class PaginatedResponse<T> {
  const PaginatedResponse({
    required this.data,
    required this.meta,
  });

  final List<T> data;
  final PaginationMeta meta;
}

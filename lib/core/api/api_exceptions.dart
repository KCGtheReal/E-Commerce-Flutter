class ApiException implements Exception {
  const ApiException({
    required this.statusCode,
    required this.message,
    this.code,
    this.errors = const <String, List<String>>{},
  });

  final int statusCode;
  final String message;
  final String? code;
  final Map<String, List<String>> errors;

  bool get isUnauthenticated => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isValidation => statusCode == 422;
  bool get isRateLimited => statusCode == 429;
  bool get isNetworkError => statusCode == 0;

  String? fieldError(String field) {
    final list = errors[field];
    if (list == null || list.isEmpty) {
      return null;
    }
    return list.first;
  }

  String get firstErrorMessage {
    for (final list in errors.values) {
      if (list.isNotEmpty) {
        return list.first;
      }
    }
    return message;
  }

  @override
  String toString() => 'ApiException($statusCode, $code): $message';
}

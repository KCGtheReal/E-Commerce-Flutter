import 'dart:convert';

import 'package:http/http.dart' as http;

http.Response jsonMockResponse(Map<String, dynamic> data, [int status = 200]) {
  return http.Response.bytes(
    utf8.encode(jsonEncode(data)),
    status,
    headers: const <String, String>{
      'content-type': 'application/json; charset=utf-8',
    },
  );
}

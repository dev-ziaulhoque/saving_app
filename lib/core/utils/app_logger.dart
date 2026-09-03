import 'dart:convert';

import 'package:flutter/foundation.dart';

class AppLogger {
  AppLogger._();

  static const _sensitiveKeys = {
    'password',
    'token',
    'fcm_token',
    'access_token',
    'refresh_token',
    'apikey',
    'api_key',
    'authorization',
    'anon_key',
  };

  static void request(String operation, [Object? data]) {
    _write('REQUEST', operation, data);
  }

  static void success(String operation, [Object? data]) {
    _write('SUCCESS', operation, data);
  }

  static void error(String operation, Object error) {
    _write('ERROR', operation, {'error': error.toString()});
  }

  static void _write(String level, String operation, Object? data) {
    if (!kDebugMode) return;
    final safeData = _sanitize(data);
    final encoded = safeData == null ? '' : ' ${jsonEncode(safeData)}';
    debugPrint('[SaveSmart][$level][$operation]$encoded');
  }

  static Object? _sanitize(Object? value, [String? key]) {
    if (key != null && _sensitiveKeys.contains(key.toLowerCase())) {
      return '<redacted>';
    }
    if (value is Map) {
      return value.map(
        (mapKey, mapValue) => MapEntry(
          mapKey.toString(),
          _sanitize(mapValue, mapKey.toString()),
        ),
      );
    }
    if (value is Iterable) {
      return value.map((item) => _sanitize(item)).toList();
    }
    final text = value?.toString();
    if (text != null && text.length > 2000) {
      return '${text.substring(0, 2000)}…';
    }
    return value;
  }
}

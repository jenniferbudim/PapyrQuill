import 'dart:convert';

import 'package:drift/drift.dart';

/// Stores a Map<String, String> as a JSON string.
/// Port of MapTypeConverter.kt.
class StringMapConverter extends TypeConverter<Map<String, String>, String> {
  const StringMapConverter();

  @override
  Map<String, String> fromSql(String fromDb) {
    if (fromDb.isEmpty) return <String, String>{};
    final decoded = jsonDecode(fromDb) as Map<String, dynamic>;
    return decoded.map((key, value) => MapEntry(key, value.toString()));
  }

  @override
  String toSql(Map<String, String> value) => jsonEncode(value);
}

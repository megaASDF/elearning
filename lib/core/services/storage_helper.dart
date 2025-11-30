import 'dart:convert';

class StorageHelper {
  // Convert list to comma-separated string
  static String listToString(List<dynamic> list) {
    return jsonEncode(list);
  }

  // Convert comma-separated string back to list
  static List<dynamic> stringToList(String str) {
    if (str.isEmpty) return [];
    try {
      return jsonDecode(str);
    } catch (e) {
      return [];
    }
  }

  // Convert map to JSON string
  static String mapToString(Map<String, dynamic> map) {
    return jsonEncode(map);
  }

  // Convert JSON string back to map
  static Map<String, dynamic> stringToMap(String str) {
    if (str.isEmpty) return {};
    try {
      return jsonDecode(str);
    } catch (e) {
      return {};
    }
  }

  // Convert boolean to integer for SQLite
  static int boolToInt(bool value) {
    return value ? 1 : 0;
  }

  // Convert integer to boolean from SQLite
  static bool intToBool(int value) {
    return value == 1;
  }
}
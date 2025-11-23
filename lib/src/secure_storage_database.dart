import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ds_easy_db/ds_easy_db.dart';

/// FlutterSecureStorage implementation of [DatabaseRepository].
///
/// Provides encrypted, platform-native secure storage for sensitive data.
/// Uses Keychain on iOS/macOS and KeyStore on Android with AES encryption.
///
/// Features:
/// - Platform-native encryption
/// - Secure storage for tokens, passwords, and API keys
/// - Cross-platform support
/// - Zero configuration
///
/// Perfect for:
/// - Authentication tokens
/// - API keys and secrets
/// - User credentials
/// - Sensitive settings
///
/// Example:
/// ```dart
/// db.configure(
///   secure: SecureStorageDatabase(),
///   // ...
/// );
/// ```
class SecureStorageDatabase implements DatabaseRepository {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  Future<void> init() async {
    // Keine Initialisierung nötig
  }

  String _getKey(String collection, String id) => '$collection:$id';

  @override
  Future<void> set(
      String collection, String id, Map<String, dynamic> data) async {
    final processedData = data.map((key, value) {
      if (value == DatabaseRepository.serverTS) {
        return MapEntry(key, DateTime.now().toIso8601String());
      }
      return MapEntry(key, value);
    });

    final key = _getKey(collection, id);
    await _storage.write(key: key, value: jsonEncode(processedData));
  }

  @override
  Future<void> update(
    String collection,
    String id,
    Map<String, dynamic> data,
  ) async {
    final processedData = data.map((key, value) {
      if (value == DatabaseRepository.serverTS) {
        return MapEntry(key, DateTime.now().toIso8601String());
      }
      return MapEntry(key, value);
    });

    final key = _getKey(collection, id);
    final existing = await get(collection, id) ?? {};
    final updated = {...existing, ...processedData};
    await _storage.write(key: key, value: jsonEncode(updated));
  }

  @override
  Future<Map<String, dynamic>?> get(
    String collection,
    String id, {
    dynamic defaultValue,
  }) async {
    final key = _getKey(collection, id);
    final jsonString = await _storage.read(key: key);
    if (jsonString == null) return defaultValue;
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }

  @override
  Future<bool> exists(String collection, String id) async {
    final key = _getKey(collection, id);
    return await _storage.containsKey(key: key);
  }

  @override
  Future<Map<String, dynamic>?> getAll(String collection) async {
    final prefix = '$collection:';
    final allData = await _storage.readAll();

    if (allData.isEmpty) return null;

    final Map<String, dynamic> result = {};
    for (var entry in allData.entries) {
      if (entry.key.startsWith(prefix)) {
        final id = entry.key.substring(prefix.length);
        final data = jsonDecode(entry.value) as Map<String, dynamic>;
        result[id] = data;
      }
    }
    return result.isEmpty ? null : result;
  }

  @override
  Future<bool> existsWhere(
    String collection, {
    required Map<String, dynamic> where,
  }) async {
    final items = await query(collection);
    for (var item in items) {
      bool matches = true;
      for (var entry in where.entries) {
        if (item[entry.key] != entry.value) {
          matches = false;
          break;
        }
      }
      if (matches) return true;
    }
    return false;
  }

  @override
  Future<void> delete(String collection, String id) async {
    final key = _getKey(collection, id);
    await _storage.delete(key: key);
  }

  @override
  Future<List<Map<String, dynamic>>> query(
    String collection, {
    Map<String, dynamic> where = const {},
  }) async {
    final prefix = '$collection:';
    final allData = await _storage.readAll();

    final items = <Map<String, dynamic>>[];
    for (var entry in allData.entries) {
      if (entry.key.startsWith(prefix)) {
        final item = jsonDecode(entry.value) as Map<String, dynamic>;
        items.add(item);
      }
    }

    if (where.isEmpty) return items;

    return items.where((item) {
      for (var entry in where.entries) {
        if (item[entry.key] != entry.value) return false;
      }
      return true;
    }).toList();
  }
}

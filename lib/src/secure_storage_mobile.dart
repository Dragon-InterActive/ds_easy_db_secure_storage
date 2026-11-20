import 'dart:convert';
import 'package:ds_easy_db/ds_easy_db.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Native implementation of SecureStorage using platform-native secure storage.
///
/// Uses platform-specific secure storage:
/// - iOS/macOS: Keychain
/// - Android: KeyStore (AES encryption)
/// - Windows: Credential Manager
/// - Linux: libsecret (gnome-keyring)
///
/// Documents are stored as JSON under the key `collection:id`. `DateTime`
/// values (including [DatabaseRepository.serverTS]) are stored as ISO-8601
/// strings and come back as strings.
class SecureStorageDatabase implements DatabaseRepository {
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  /// Nothing has to be prepared; the method exists for the shared interface.
  @override
  Future<void> init() async {}

  String _buildKey(String collection, String id) => '$collection:$id';

  Map<String, dynamic> _resolveServerTimestamps(Map<String, dynamic> data) {
    return data.map((key, value) {
      if (value == DatabaseRepository.serverTS) {
        return MapEntry(key, DateTime.now().toIso8601String());
      }
      return MapEntry(key, value);
    });
  }

  String _encode(Map<String, dynamic> data) => jsonEncode(
        data,
        toEncodable: (value) => value is DateTime
            ? value.toIso8601String()
            : throw JsonUnsupportedObjectError(value),
      );

  Map<String, dynamic>? _decode(String? raw) {
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> set(
    String collection,
    String id,
    Map<String, dynamic> data,
  ) async {
    await _storage.write(
      key: _buildKey(collection, id),
      value: _encode(_resolveServerTimestamps(data)),
    );
  }

  @override
  Future<void> update(
    String collection,
    String id,
    Map<String, dynamic> data,
  ) async {
    final existing = await get(collection, id) ?? <String, dynamic>{};
    await _storage.write(
      key: _buildKey(collection, id),
      value: _encode({...existing, ..._resolveServerTimestamps(data)}),
    );
  }

  @override
  Future<Map<String, dynamic>?> get(
    String collection,
    String id, {
    dynamic defaultValue,
  }) async {
    final raw = await _storage.read(key: _buildKey(collection, id));
    return _decode(raw) ?? defaultValue;
  }

  @override
  Future<Map<String, dynamic>?> getAll(String collection) async {
    final allData = await _storage.readAll();
    final prefix = '$collection:';

    final result = <String, dynamic>{};
    for (final entry in allData.entries) {
      if (!entry.key.startsWith(prefix)) continue;
      final document = _decode(entry.value);
      if (document != null) {
        result[entry.key.substring(prefix.length)] = document;
      }
    }
    return result.isEmpty ? null : result;
  }

  @override
  Future<bool> exists(String collection, String id) async {
    return _storage.containsKey(key: _buildKey(collection, id));
  }

  @override
  Future<bool> existsWhere(
    String collection, {
    required Map<String, dynamic> where,
  }) async {
    final items = await query(collection, where: where);
    return items.isNotEmpty;
  }

  @override
  Future<void> delete(String collection, String id) async {
    await _storage.delete(key: _buildKey(collection, id));
  }

  /// Returns the matching documents, each with its document id under `id`.
  ///
  /// A document that carries its own `id` field keeps it.
  @override
  Future<List<Map<String, dynamic>>> query(
    String collection, {
    Map<String, dynamic> where = const {},
  }) async {
    final all = await getAll(collection);
    if (all == null) return [];

    return [
      for (final entry in all.entries)
        if (_matches(entry.value as Map<String, dynamic>, where))
          <String, dynamic>{'id': entry.key, ...entry.value},
    ];
  }

  bool _matches(Map<String, dynamic> document, Map<String, dynamic> where) {
    for (final entry in where.entries) {
      if (document[entry.key] != entry.value) return false;
    }
    return true;
  }
}

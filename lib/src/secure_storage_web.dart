import 'dart:convert';
import 'package:ds_easy_db/ds_easy_db.dart';
import 'package:cryptography/cryptography.dart';

/// Web implementation of SecureStorage using in-memory encryption
///
/// On web platforms, this implementation stores encrypted data in memory
/// with a session-based encryption key. Data is lost when the page reloads.
///
/// **Web Security Limitation**:
/// - Data only persists in memory during the session
/// - No persistent secure storage on web
/// - Data is lost on page reload
/// - For data that has to survive a reload, use
///   `ds_easy_db_secured_shared_preferences` instead
class SecureStorageDatabase implements DatabaseRepository {
  final Map<String, Map<String, String>> _memoryData = {};
  final AesGcm _cipher = AesGcm.with256bits();
  Future<SecretKey>? _sessionKey;

  /// Generates the session key. Called automatically on first use.
  @override
  Future<void> init() async {
    await _key();
  }

  Future<SecretKey> _key() => _sessionKey ??= _cipher.newSecretKey();

  Future<String> _encrypt(String plainText) async {
    final secretBox = await _cipher.encrypt(
      utf8.encode(plainText),
      secretKey: await _key(),
    );

    return base64.encode(<int>[
      ...secretBox.nonce,
      ...secretBox.cipherText,
      ...secretBox.mac.bytes,
    ]);
  }

  Future<String> _decrypt(String encryptedText) async {
    final combined = base64.decode(encryptedText);

    final nonce = combined.sublist(0, 12);
    final mac = Mac(combined.sublist(combined.length - 16));
    final cipherText = combined.sublist(12, combined.length - 16);

    final decryptedBytes = await _cipher.decrypt(
      SecretBox(cipherText, nonce: nonce, mac: mac),
      secretKey: await _key(),
    );

    return utf8.decode(decryptedBytes);
  }

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

  Future<Map<String, dynamic>?> _read(String? encrypted) async {
    if (encrypted == null) return null;
    try {
      final decoded = jsonDecode(await _decrypt(encrypted));
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> set(
    String collection,
    String id,
    Map<String, dynamic> data,
  ) async {
    final encrypted = await _encrypt(_encode(_resolveServerTimestamps(data)));
    _memoryData.putIfAbsent(collection, () => {})[id] = encrypted;
  }

  @override
  Future<void> update(
    String collection,
    String id,
    Map<String, dynamic> data,
  ) async {
    final existing = await get(collection, id) ?? <String, dynamic>{};
    final encrypted = await _encrypt(
      _encode({...existing, ..._resolveServerTimestamps(data)}),
    );
    _memoryData.putIfAbsent(collection, () => {})[id] = encrypted;
  }

  @override
  Future<Map<String, dynamic>?> get(
    String collection,
    String id, {
    dynamic defaultValue,
  }) async {
    return await _read(_memoryData[collection]?[id]) ?? defaultValue;
  }

  @override
  Future<Map<String, dynamic>?> getAll(String collection) async {
    final entries = _memoryData[collection];
    if (entries == null) return null;

    final result = <String, dynamic>{};
    for (final entry in entries.entries) {
      final document = await _read(entry.value);
      if (document != null) result[entry.key] = document;
    }
    return result.isEmpty ? null : result;
  }

  @override
  Future<bool> exists(String collection, String id) async {
    return _memoryData[collection]?.containsKey(id) ?? false;
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
    _memoryData[collection]?.remove(id);
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

  /// Clear all data from memory (useful for logout)
  void clearAll() {
    _memoryData.clear();
  }
}

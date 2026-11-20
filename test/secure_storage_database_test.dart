import 'package:ds_easy_db/ds_easy_db.dart';
import 'package:ds_easy_db_secure_storage/src/secure_storage_mobile.dart'
    as mobile;
import 'package:ds_easy_db_secure_storage/src/secure_storage_web.dart' as web;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  _contract('mobile', () {
    FlutterSecureStorage.setMockInitialValues({});
    return mobile.SecureStorageDatabase();
  });

  // The web implementation is pure Dart, so it runs on the VM as well.
  _contract('web', web.SecureStorageDatabase.new);

  test('mobile: foreign or broken values are skipped, not thrown on', () async {
    FlutterSecureStorage.setMockInitialValues({
      'users:broken': 'not json',
      'users:list': '[1]',
    });
    final db = mobile.SecureStorageDatabase();
    await db.set('users', 'u1', {'a': 1});

    expect((await db.getAll('users'))!.keys, ['u1']);
    expect(await db.get('users', 'broken'), isNull);
  });
}

void _contract(String name, DatabaseRepository Function() create) {
  group(name, () {
    late DatabaseRepository db;

    setUp(() => db = create());

    test('works without an explicit init()', () async {
      await db.set('users', 'u1', {'a': 1});
      expect(await db.get('users', 'u1'), {'a': 1});
    });

    test('DateTime and serverTS are stored as ISO-8601 strings', () async {
      final at = DateTime.utc(2026, 1, 2);
      await db.set('events', 'e1', {
        'at': at,
        'createdAt': DatabaseRepository.serverTS,
      });

      final event = (await db.get('events', 'e1'))!;
      expect(event['at'], at.toIso8601String());
      expect(DateTime.tryParse(event['createdAt'] as String), isNotNull);
    });

    test('query adds the document id, keeping an own "id" field', () async {
      await db.set('users', 'u1', {'age': 30});
      await db.set('users', 'u2', {'id': 'custom', 'age': 40});

      expect(await db.query('users', where: {'age': 30}), [
        {'id': 'u1', 'age': 30},
      ]);
      expect(
          (await db.query('users', where: {'age': 40})).single['id'], 'custom');
    });

    test('update merges', () async {
      await db.set('users', 'u1', {'a': 1});
      await db.update('users', 'u1', {'b': 2});

      expect(await db.get('users', 'u1'), {'a': 1, 'b': 2});
    });

    test('getAll returns null for an empty collection', () async {
      expect(await db.getAll('empty'), isNull);
    });
  });
}

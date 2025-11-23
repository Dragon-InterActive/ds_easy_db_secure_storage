# DSEasyDB Secure Storage Example

```dart
import 'package:ds_easy_db/ds_easy_db.dart';
import 'package:ds_easy_db_secure_storage/ds_easy_db_secure_storage.dart';

void main() async {
  // Configure with SecureStorage
  db.configure(
    prefs: MockDatabase(),
    secure: SecureStorageDatabase(),
    storage: MockDatabase(),
    stream: MockDatabase(),
  );
  
  await db.init();
  
  // Store authentication tokens
  await db.secure.set('auth', 'tokens', {
    'accessToken': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
    'refreshToken': 'dGhpcyBpcyBhIHJlZnJlc2ggdG9rZW4...',
    'expiresAt': DateTime.now().add(Duration(hours: 1)).toIso8601String(),
  });
  
  // Read tokens
  final tokens = await db.secure.get('auth', 'tokens');
  print('Access Token: ${tokens?['accessToken']}');
  
  // Delete on logout
  await db.secure.delete('auth', 'tokens');
  
  // Store API credentials
  await db.secure.set('api', 'credentials', {
    'apiKey': 'sk-1234567890abcdef',
    'apiSecret': 'secret_key_here',
  });
}
```

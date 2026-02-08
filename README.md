# DSEasyDB Secure Storage

Secure storage implementation for [DSEasyDB](https://pub.dev/packages/ds_easy_db) (<https://github.com/Dragon-InterActive/ds_easy_db>). Uses platform-native secure storage on mobile/desktop and in-memory encryption on web.

## Features

- **Platform-Native Security on Mobile/Desktop**:
  - iOS/macOS: Keychain
  - Android: KeyStore with AES encryption
  - Windows: Credential Manager
  - Linux: libsecret (gnome-keyring)
- **Web Support with In-Memory Encryption**: Session-based AES-256-GCM encryption
- **WASM Compatible**: Works with `flutter build web --wasm`
- **Automatic Platform Detection**: Correct implementation loaded at compile time
- **Zero Configuration**: Works out of the box

## Platform Behavior

### Mobile & Desktop ✅ Persistent & Secure

Data is stored using OS-native secure storage:

- **iOS/macOS**: Keychain (protected by device passcode/biometrics)
- **Android**: KeyStore (hardware-backed encryption when available)
- **Windows**: Credential Manager
- **Linux**: libsecret/gnome-keyring

Data **persists** between app restarts and survives app updates.

### Web ⚠️ Session-Only & In-Memory

Data is encrypted with AES-256-GCM and stored in memory:

- **Encryption**: AES-256-GCM with session key
- **Persistence**: ❌ Data lost on page reload
- **Security**: ✅ Encrypted in memory during session
- **Use Case**: Temporary sensitive data (auth tokens during session)

**For persistent web storage**, use [`ds_easy_db_secured_shared_preferences`](https://pub.dev/packages/ds_easy_db_secured_shared_preferences) instead.

## When to Use

### ✅ Perfect for SecureStorage

- Authentication tokens (during session)
- API keys and secrets
- Private keys and certificates
- Password storage
- Sensitive user credentials
- Temporary sensitive session data

### ❌ Consider Alternatives

- **Persistent web data**: Use `ds_easy_db_secured_shared_preferences`
- **Large datasets**: Use encrypted database (SQLite/Isar)
- **Non-sensitive settings**: Use `ds_easy_db_shared_preferences`
- **Shared preferences**: Use `ds_easy_db_shared_preferences`

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  ds_easy_db: ^1.0.2
  ds_easy_db_secure_storage: ^2.0.0
```

### Platform-Specific Setup

#### Android

Set minimum SDK version in `android/app/build.gradle`:

```gradle
android {
    defaultConfig {
        minSdkVersion 18  // Required for secure storage
    }
}
```

#### Linux

Install required dependencies:

```bash
sudo apt-get install libsecret-1-dev
```

#### iOS/macOS

No additional setup required.

#### Web

No additional setup required. Uses in-memory encryption automatically.

## Usage

### Basic Setup

```dart
import 'package:ds_easy_db/ds_easy_db.dart';
import 'package:ds_easy_db_secure_storage/ds_easy_db_secure_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  db.configure(
    prefs: MockDatabase(),
    secure: SecureStorageDatabase(),  // Platform-specific implementation loaded automatically
    storage: MockDatabase(),
    stream: MockStreamDatabase(),
  );
  
  await db.init();
  
  runApp(MyApp());
}
```

### Configuration File

In your `easy_db_config.dart`:

```dart
import 'package:ds_easy_db/ds_easy_db.dart';
import 'package:ds_easy_db_secure_storage/ds_easy_db_secure_storage.dart';

class EasyDBConfig {
  static DatabaseRepository get secure => SecureStorageDatabase();
  // ... other configurations
}
```

## Examples

### Store Authentication Token

```dart
// Store auth token securely
await db.secure.set('auth', 'token', {
  'accessToken': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
  'refreshToken': 'abc123xyz...',
  'expiresAt': DateTime.now().add(Duration(hours: 1)).toIso8601String(),
});

// Retrieve token
final authData = await db.secure.get('auth', 'token');
print('Access Token: ${authData?['accessToken']}');

// Delete on logout
await db.secure.delete('auth', 'token');
```

### Store API Keys

```dart
// Store API credentials
await db.secure.set('api', 'credentials', {
  'apiKey': 'sk_live_abc123...',
  'apiSecret': 'secret_xyz789...',
  'environment': 'production',
});

// Read credentials
final credentials = await db.secure.get('api', 'credentials');
final apiKey = credentials?['apiKey'];
```

### Store User Credentials

```dart
// Store encrypted user credentials
await db.secure.set('user', 'credentials', {
  'email': 'user@example.com',
  'encryptedPassword': 'hashed_password_here',
  'biometricEnabled': true,
});

// Check if credentials exist
if (await db.secure.exists('user', 'credentials')) {
  final creds = await db.secure.get('user', 'credentials');
  print('Email: ${creds?['email']}');
}
```

### Store Private Keys

```dart
// Store cryptographic keys
await db.secure.set('crypto', 'keys', {
  'privateKey': '-----BEGIN PRIVATE KEY-----\n...',
  'publicKey': '-----BEGIN PUBLIC KEY-----\n...',
  'keyPairId': 'keypair_123',
});

// Retrieve for signing
final keys = await db.secure.get('crypto', 'keys');
final privateKey = keys?['privateKey'];
```

### Query Secure Data

```dart
// Store multiple secure items
await db.secure.set('tokens', 'service1', {'token': 'abc', 'service': 'api1'});
await db.secure.set('tokens', 'service2', {'token': 'xyz', 'service': 'api2'});

// Query all tokens
final allTokens = await db.secure.getAll('tokens');
print('Total tokens: ${allTokens?.length}');

// Query specific service
final tokens = await db.secure.query('tokens', 
  where: {'service': 'api1'}
);
```

### Clear All Secure Data (Logout)

```dart
// Delete all sensitive data
await db.secure.delete('auth', 'token');
await db.secure.delete('user', 'credentials');
await db.secure.delete('api', 'credentials');

// Or query and delete all in collection
final allAuth = await db.secure.getAll('auth');
if (allAuth != null) {
  for (var key in allAuth.keys) {
    await db.secure.delete('auth', key);
  }
}
```

## Web-Specific Example

```dart
import 'package:flutter/foundation.dart' show kIsWeb;

Future<void> storeToken(String token) async {
  if (kIsWeb) {
    // Web: In-memory only, lost on reload
    print('Warning: Token will be lost on page reload');
  }
  
  await db.secure.set('auth', 'token', {
    'token': token,
    'savedAt': DateTime.now().toIso8601String(),
  });
  
  if (kIsWeb) {
    print('Token stored in memory (session only)');
  } else {
    print('Token stored in secure storage (persistent)');
  }
}
```

## Platform Comparison

| Feature | Mobile/Desktop | Web |
|---------|----------------|-----|
| Storage Type | OS Keychain/KeyStore | In-Memory |
| Encryption | Platform-native | AES-256-GCM |
| Persistence | ✅ Survives restarts | ❌ Session only |
| Security Level | Very High | High (session) |
| Performance | Fast | Very Fast |
| WASM Support | N/A | ✅ Supported |

## Migration from v1.x to v2.0.0

**Breaking Change**: Web implementation changed from persistent (but insecure) to session-based (secure).

### What Changed?

**v1.x Web:**

- Stored in browser's localStorage (persistent but accessible via DevTools)
- Data survived page reload
- Security risk: Anyone with browser access could read data

**v2.0.0 Web:**

- Stored in memory with encryption (session-based)
- Data lost on page reload
- Secure: Data encrypted in memory, lost on session end

### Migration Strategy

**Option 1: Accept Session-Only Behavior (Recommended)**

```dart
// Data will be lost on reload - re-authenticate on app start
if (kIsWeb) {
  // Force user to re-login on page load
  final token = await db.secure.get('auth', 'token');
  if (token == null) {
    navigateToLogin();
  }
}
```

**Option 2: Use Secured SharedPreferences for Web Persistence**

```dart
// For web: Use secured_shared_preferences (persistent but key in localStorage)
import 'package:ds_easy_db_secured_shared_preferences/ds_easy_db_secured_shared_preferences.dart';

db.configure(
  secure: kIsWeb 
    ? SecuredSharedPreferencesDatabase()  // Persistent on web
    : SecureStorageDatabase(),             // Native secure on mobile
);
```

**Option 3: Server-Side Session Management**

```dart
// Best practice: Don't persist sensitive tokens on web
// Use short-lived tokens and refresh from server
```

## Security Best Practices

### General

1. **Never log secure data**: Avoid `print()` statements with sensitive data
2. **Clear on logout**: Always delete secure data when user logs out
3. **Use short-lived tokens**: Implement token refresh instead of long-lived storage
4. **Validate data**: Always validate data after retrieval

### Mobile/Desktop

1. **Trust platform security**: Keychain/KeyStore are battle-tested
2. **Require device lock**: Consider checking if device has passcode/biometrics
3. **Handle key loss**: Implement re-authentication if secure storage is cleared

### Web

1. **Treat as session-only**: Don't rely on persistence
2. **Re-authenticate on reload**: Implement login flow on page reload
3. **Use HTTPS only**: Ensure encrypted transport
4. **Consider server-side sessions**: For sensitive apps, avoid client-side token storage

## Troubleshooting

### Android: "MissingPluginException"

Ensure you've set `minSdkVersion 18` or higher.

### Linux: Build errors

Install dependencies:

```bash
sudo apt-get install libsecret-1-dev
```

### Web: Data lost on reload

This is expected behavior in v2.0.0. Use `secured_shared_preferences` for persistence.

### iOS: Keychain access denied

Check that your app has proper entitlements. This is usually automatic.

## Performance Notes

- **Mobile/Desktop**: Platform calls are fast (~1-5ms per operation)
- **Web**: In-memory operations are very fast (<1ms)
- **Recommendation**: Batch writes when possible
- **Limitation**: Not suitable for storing large amounts of data (use database instead)

## License

BSD-3-Clause License - see LICENSE file for details.

Copyright (c) 2026, MasterNemo (Dragon Software)

---

Feel free to clone and extend. It's free to use and share.

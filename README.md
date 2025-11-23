# DS-EasyDB Secure Storage

FlutterSecureStorage implementation for [DS-EasyDB](https://pub.dev/packages/ds_easy_db) (<https://github.com/Dragon-InterActive/ds_easy_db>). Provides encrypted, platform-native secure storage for sensitive data.

## Features

- **Platform-Native Security**: Uses Keychain on iOS/macOS, KeyStore on Android, Credential Manager on Windows
- **AES Encryption**: Data is encrypted before storage on Android
- **Cross-Platform**: Works on iOS, Android, macOS, Windows, Linux, and Web
- **Zero Configuration**: Works out of the box with sensible defaults
- **Actively Maintained**: Regular updates and bug fixes

## Security Implementation

- **iOS/macOS**: Keychain (industry standard since iOS 2.0)
- **Android**: KeyStore with AES encryption
- **Windows**: Windows Credential Manager (wincred.h)
- **Linux**: libsecret (requires gnome-keyring or similar)
- **Web**: LocalStorage with optional encryption wrapper

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  ds_easy_db: ^1.0.1
  ds_easy_db_secure_storage: ^1.0.1
```

### Platform-Specific Setup

#### Android

Set minimum SDK version in `android/app/build.gradle`:

```gradle
android {
    defaultConfig {
        minSdkVersion 18  // Required for KeyStore
    }
}
```

#### Linux

Install required libraries:

```bash
sudo apt-get install libsecret-1-dev libjsoncpp-dev
```

#### macOS

Enable Keychain Sharing capability in Xcode for your macOS runner.

## Usage

### Basic Setup

```dart
import 'package:ds_easy_db/ds_easy_db.dart';
import 'package:ds_easy_db_secure_storage/ds_easy_db_secure_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  db.configure(
    secure: SecureStorageDatabase(),
    // ... other configurations
  );
  
  await db.init();
  
  runApp(MyApp());
}
```

### Configuration File

In your `ds_easy_db_config.dart`:

```dart
import 'package:ds_easy_db/ds_easy_db.dart';
import 'package:ds_easy_db_secure_storage/ds_easy_db_secure_storage.dart';

class DS-EasyDBConfig {
  static DatabaseRepository get secure => SecureStorageDatabase();
  // ... other configurations
}
```

## Examples

### Store Authentication Tokens

```dart
// Save auth tokens securely
await db.secure.set('auth', 'tokens', {
  'accessToken': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
  'refreshToken': 'dGhpcyBpcyBhIHJlZnJlc2ggdG9rZW4...',
  'expiresAt': DatabaseRepository.serverTS,
});

// Read tokens
final tokens = await db.secure.get('auth', 'tokens');
print('Access Token: ${tokens?['accessToken']}');

// Check if tokens exist
if (await db.secure.exists('auth', 'tokens')) {
  print('User is authenticated');
}

// Delete tokens on logout
await db.secure.delete('auth', 'tokens');
```

### Store API Keys

```dart
// Store API credentials
await db.secure.set('api', 'credentials', {
  'apiKey': 'sk-1234567890abcdef',
  'apiSecret': 'secret_key_here',
  'environment': 'production',
});

// Retrieve credentials
final creds = await db.secure.get('api', 'credentials');
final apiKey = creds?['apiKey'];
```

### Store User Credentials

```dart
// Store encrypted user credentials
await db.secure.set('user', 'credentials', {
  'email': 'user@example.com',
  'encryptedPassword': 'encrypted_hash_here',
  'biometricEnabled': true,
});

// Update specific fields
await db.secure.update('user', 'credentials', {
  'biometricEnabled': false,
});
```

### Store Sensitive Settings

```dart
// Store sensitive app settings
await db.secure.set('settings', 'privacy', {
  'trackingEnabled': false,
  'analyticsId': 'uuid-1234-5678',
  'consentGiven': true,
  'consentDate': DatabaseRepository.serverTS,
});

// Query sensitive data
final privacySettings = await db.secure.query('settings', 
  where: {'trackingEnabled': false}
);
```

### Biometric Authentication Context

```dart
// Store data that requires biometric authentication
await db.secure.set('secure', 'pin', {
  'pin': '1234',
  'attempts': 0,
  'lockedUntil': null,
});

// Check existence before prompting biometrics
if (await db.secure.exists('secure', 'pin')) {
  // Prompt for biometric authentication
  // Then read the PIN
  final pinData = await db.secure.get('secure', 'pin');
}
```

## What to Store

### ✅ Perfect for Secure Storage

- Authentication tokens (JWT, OAuth)
- API keys and secrets
- Encryption keys
- User credentials
- Biometric data references
- Payment tokens
- Certificate data
- Privacy-sensitive user data

### ❌ Don't Use for

- Large amounts of data (>1KB per item)
- Frequently changing data (use `prefs` instead)
- Non-sensitive configuration (use `prefs` instead)
- Binary data like images (use files instead)
- Data that needs complex queries (use `storage` instead)

## Performance Notes

- **First Read**: Slightly slower due to decryption
- **Subsequent Operations**: Fast with platform-native caching
- **Data Size**: Keep data small (<1KB) for best performance
- **Frequency**: Not optimized for high-frequency writes

## Platform Limitations

### Android

- Minimum SDK 18 (Android 4.3)
- KeyStore available since API 18
- Some devices may have issues with backup/restore

### iOS/macOS

- Keychain has no practical size limits
- Data survives app reinstall
- Accessible after device unlock

### Web

- Uses LocalStorage (not truly secure)
- Optional encryption wrapper available
- 5-10MB storage limit

### Linux

- Requires secret service (gnome-keyring)
- May need user permission on first access

## Migration from Other Storage

```dart
// Migrate from SharedPreferences to SecureStorage
final oldValue = await db.prefs.get('settings', 'apiKey');
if (oldValue != null) {
  await db.secure.set('api', 'key', {'key': oldValue});
  await db.prefs.delete('settings', 'apiKey');
}
```

## Security Best Practices

1. **Never Store Plain Passwords**: Always hash/encrypt before storing
2. **Use for Tokens Only**: Auth tokens should be stored here
3. **Clear on Logout**: Always delete sensitive data on logout
4. **Validate Data**: Always validate data before trusting it
5. **Monitor Access**: Log access to sensitive data
6. **Handle Errors**: Properly handle storage failures

## Common Issues

### Android KeyStore Exceptions

If you encounter KeyStore errors after app updates, you may need to clear and re-save data:

```dart
try {
  await db.secure.get('auth', 'tokens');
} catch (e) {
  // KeyStore error - clear and re-authenticate
  await db.secure.delete('auth', 'tokens');
  // Trigger re-authentication
}
```

### iOS Keychain Access

Data becomes inaccessible when device is locked. Use appropriate accessibility options if needed.

## License

BSD-3-Clause License - see LICENSE file for details.

Copyright (c) 2025, MasterNemo (Dragon Software)

---

Feel free to clone and extend. It's free to use and share.

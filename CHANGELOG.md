## 2.0.0

* **Breaking Change**: Added WASM compatibility with platform-specific implementations
* **Web**: Now uses in-memory encrypted storage (session-based, data lost on reload)
* **Mobile/Desktop**: Still uses platform-native secure storage (Keychain/Keystore)
* Added `cryptography` package for web encryption
* Updated to ds_easy_db ^1.0.2
* Updated to flutter_secure_storage ^10.0.0
* Note: Web implementation does not persist data between sessions

## 1.0.1

* Added dartdoc comments to public API
* Added example documentation

## 1.0.0

* Initial release
* FlutterSecureStorage integration for EasyDB
* Platform-native encrypted storage (Keychain on iOS/macOS, KeyStore on Android)
* AES encryption for sensitive data
* Cross-platform support
* Perfect for tokens, credentials, and sensitive settings

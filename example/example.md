# DSEasyDB Secure Storage Example

```dart
import 'package:ds_easy_db/ds_easy_db.dart';
import 'package:ds_easy_db_secure_storage/ds_easy_db_secure_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

void main() async {
  // Configure with SecureStorage
  db.configure(
    prefs: MockDatabase(),
    secure: SecureStorageDatabase(),  // Auto-detects platform
    storage: MockDatabase(),
    stream: MockStreamDatabase(),
  );
  
  await db.init();
  
  // Platform-specific behavior
  if (kIsWeb) {
    print('Web: Using in-memory encryption (session-only)');
  } else {
    print('Mobile/Desktop: Using platform-native secure storage');
  }
  
  // Store authentication token
  await db.secure.set('auth', 'token', {
    'accessToken': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
    'refreshToken': 'refresh_abc123',
    'expiresAt': DateTime.now().add(Duration(hours: 1)).toIso8601String(),
  });
  
  // Store API credentials
  await db.secure.set('api', 'credentials', {
    'apiKey': 'sk_live_abc123xyz',
    'apiSecret': 'secret_xyz789',
    'environment': 'production',
  });
  
  // Store user credentials
  await db.secure.set('user', 'credentials', {
    'email': 'user@example.com',
    'userId': 'user_12345',
    'biometricEnabled': true,
  });
  
  // Retrieve secure data
  final token = await db.secure.get('auth', 'token');
  print('Access Token: ${token?['accessToken']}');
  
  final credentials = await db.secure.get('api', 'credentials');
  print('API Key: ${credentials?['apiKey']}');
  
  // Check if data exists
  if (await db.secure.exists('user', 'credentials')) {
    print('User credentials found');
  }
  
  // Query secure data
  final allAuth = await db.secure.getAll('auth');
  print('Total auth entries: ${allAuth?.length}');
  
  // Update secure data
  await db.secure.update('auth', 'token', {
    'lastUsed': DateTime.now().toIso8601String(),
  });
  
  // Delete on logout
  await db.secure.delete('auth', 'token');
  await db.secure.delete('user', 'credentials');
  print('Secure data cleared');
}
```

## Platform-Aware Example

```dart
import 'package:flutter/foundation.dart' show kIsWeb;

class SecureTokenManager {
  // Store token with platform-specific handling
  static Future<void> saveToken(String token) async {
    await db.secure.set('auth', 'token', {
      'token': token,
      'savedAt': DateTime.now().toIso8601String(),
      'platform': kIsWeb ? 'web' : 'native',
    });
    
    if (kIsWeb) {
      print('⚠️ Token stored in memory - will be lost on page reload');
    } else {
      print('✅ Token stored in secure storage - persists across restarts');
    }
  }
  
  // Retrieve token with fallback
  static Future<String?> getToken() async {
    final data = await db.secure.get('auth', 'token');
    
    if (data == null) {
      if (kIsWeb) {
        print('Session expired - please login again');
      } else {
        print('No stored token found');
      }
      return null;
    }
    
    return data['token'] as String?;
  }
  
  // Clear all auth data
  static Future<void> logout() async {
    await db.secure.delete('auth', 'token');
    await db.secure.delete('user', 'credentials');
    print('Logged out - all secure data cleared');
  }
}
```

## Web-Specific Warning Example

```dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Show web warning
          if (kIsWeb)
            Container(
              color: Colors.orange.shade100,
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Web version: Your session will end when you close this tab',
                      style: TextStyle(color: Colors.orange.shade900),
                    ),
                  ),
                ],
              ),
            ),
          
          // Login form...
        ],
      ),
    );
  }
}
```

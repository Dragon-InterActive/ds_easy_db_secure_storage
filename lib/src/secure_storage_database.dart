// Export the correct implementation based on platform
export 'secure_storage_mobile.dart'
    if (dart.library.html) 'secure_storage_web.dart'
    if (dart.library.js_interop) 'secure_storage_web.dart';

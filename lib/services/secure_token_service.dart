import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:localstorage/localstorage.dart';

/// Centralized encrypted token storage backed by [FlutterSecureStorage]
/// (Android EncryptedSharedPreferences / Keystore & iOS Keychain) with an
/// in-memory cache for fast synchronous access after initialization.
///
/// Automatically migrates any legacy plaintext tokens out of `LocalStorage('pocketHR')`
/// and removes them from the unencrypted JSON file on disk.
class SecureTokenService {
  SecureTokenService._();

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static final LocalStorage _legacyStorage = LocalStorage('pocketHR');

  static const String _kAccessToken = 'access_token';
  static const String _kRefreshToken = 'refresh_token';
  static const String _kOauthToken = 'token';

  static String? _cachedAccessToken;
  static String? _cachedRefreshToken;
  static String? _cachedOauthToken;
  static bool _initialized = false;

  /// Initializes the in-memory token cache from [FlutterSecureStorage] and
  /// migrates any legacy plaintext tokens from `LocalStorage('pocketHR')`.
  static Future<void> ensureInitialized() async {
    if (_initialized) return;
    try {
      await _legacyStorage.ready;
    } catch (_) {}

    String? secureAccess;
    String? secureRefresh;
    String? secureOauth;
    bool pluginAvailable = true;

    try {
      secureAccess = await _secureStorage.read(key: _kAccessToken);
      secureRefresh = await _secureStorage.read(key: _kRefreshToken);
      secureOauth = await _secureStorage.read(key: _kOauthToken);
    } on MissingPluginException {
      pluginAvailable = false;
    } catch (e) {
      debugPrint('[SecureTokenService] Error reading secure storage: $e');
    }

    // Check legacy plaintext storage for migration
    final legacyAccess = _legacyStorage.getItem(_kAccessToken)?.toString();
    final legacyRefresh = _legacyStorage.getItem(_kRefreshToken)?.toString();
    final legacyOauth = _legacyStorage.getItem(_kOauthToken)?.toString();

    if ((secureAccess == null || secureAccess.isEmpty) &&
        legacyAccess != null &&
        legacyAccess.isNotEmpty) {
      secureAccess = legacyAccess;
      if (pluginAvailable) {
        try {
          await _secureStorage.write(key: _kAccessToken, value: legacyAccess);
        } catch (_) {}
      }
    }

    if ((secureRefresh == null || secureRefresh.isEmpty) &&
        legacyRefresh != null &&
        legacyRefresh.isNotEmpty) {
      secureRefresh = legacyRefresh;
      if (pluginAvailable) {
        try {
          await _secureStorage.write(key: _kRefreshToken, value: legacyRefresh);
        } catch (_) {}
      }
    }

    if ((secureOauth == null || secureOauth.isEmpty) &&
        legacyOauth != null &&
        legacyOauth.isNotEmpty) {
      secureOauth = legacyOauth;
      if (pluginAvailable) {
        try {
          await _secureStorage.write(key: _kOauthToken, value: legacyOauth);
        } catch (_) {}
      }
    }

    // Scrub plaintext tokens from LocalStorage on disk once migrated to SecureStorage
    if (pluginAvailable) {
      try {
        if (legacyAccess != null) await _legacyStorage.deleteItem(_kAccessToken);
        if (legacyRefresh != null) await _legacyStorage.deleteItem(_kRefreshToken);
        if (legacyOauth != null) await _legacyStorage.deleteItem(_kOauthToken);
      } catch (_) {}
    }

    _cachedAccessToken = secureAccess;
    _cachedRefreshToken = secureRefresh;
    _cachedOauthToken = secureOauth;
    _initialized = true;
  }

  /// Synchronous getter for access token (falls back to legacy storage if not yet initialized).
  static String getAccessTokenSync() {
    if (_cachedAccessToken != null && _cachedAccessToken!.isNotEmpty) {
      return _cachedAccessToken!;
    }
    try {
      return _legacyStorage.getItem(_kAccessToken)?.toString() ?? '';
    } catch (_) {
      return '';
    }
  }

  /// Synchronous getter for refresh token.
  static String getRefreshTokenSync() {
    if (_cachedRefreshToken != null && _cachedRefreshToken!.isNotEmpty) {
      return _cachedRefreshToken!;
    }
    try {
      return _legacyStorage.getItem(_kRefreshToken)?.toString() ?? '';
    } catch (_) {
      return '';
    }
  }

  /// Synchronous getter for legacy oauth token.
  static String getOauthTokenSync() {
    if (_cachedOauthToken != null && _cachedOauthToken!.isNotEmpty) {
      return _cachedOauthToken!;
    }
    try {
      return _legacyStorage.getItem(_kOauthToken)?.toString() ?? '';
    } catch (_) {
      return '';
    }
  }

  /// Async getter for access token (ensures initialization first).
  static Future<String> getAccessToken() async {
    await ensureInitialized();
    if (_cachedAccessToken != null && _cachedAccessToken!.isNotEmpty) {
      return _cachedAccessToken!;
    }
    try {
      final s = await _secureStorage.read(key: _kAccessToken);
      if (s != null && s.isNotEmpty) {
        _cachedAccessToken = s;
        return s;
      }
    } catch (_) {}
    return getAccessTokenSync();
  }

  /// Async getter for refresh token.
  static Future<String> getRefreshToken() async {
    await ensureInitialized();
    if (_cachedRefreshToken != null && _cachedRefreshToken!.isNotEmpty) {
      return _cachedRefreshToken!;
    }
    try {
      final s = await _secureStorage.read(key: _kRefreshToken);
      if (s != null && s.isNotEmpty) {
        _cachedRefreshToken = s;
        return s;
      }
    } catch (_) {}
    return getRefreshTokenSync();
  }

  /// Async getter for legacy oauth token.
  static Future<String> getOauthToken() async {
    await ensureInitialized();
    if (_cachedOauthToken != null && _cachedOauthToken!.isNotEmpty) {
      return _cachedOauthToken!;
    }
    try {
      final s = await _secureStorage.read(key: _kOauthToken);
      if (s != null && s.isNotEmpty) {
        _cachedOauthToken = s;
        return s;
      }
    } catch (_) {}
    return getOauthTokenSync();
  }

  /// Saves tokens into encrypted storage and updates the in-memory cache,
  /// scrubbing any plaintext copies from `LocalStorage`.
  static Future<void> saveTokens({
    String? accessToken,
    String? refreshToken,
    String? oauthToken,
  }) async {
    _initialized = true;
    bool pluginAvailable = true;

    if (accessToken != null) {
      _cachedAccessToken = accessToken;
      try {
        if (accessToken.isEmpty) {
          await _secureStorage.delete(key: _kAccessToken);
        } else {
          await _secureStorage.write(key: _kAccessToken, value: accessToken);
        }
      } on MissingPluginException {
        pluginAvailable = false;
      } catch (_) {}
    }

    if (refreshToken != null) {
      _cachedRefreshToken = refreshToken;
      try {
        if (refreshToken.isEmpty) {
          await _secureStorage.delete(key: _kRefreshToken);
        } else {
          await _secureStorage.write(key: _kRefreshToken, value: refreshToken);
        }
      } on MissingPluginException {
        pluginAvailable = false;
      } catch (_) {}
    }

    if (oauthToken != null) {
      _cachedOauthToken = oauthToken;
      try {
        if (oauthToken.isEmpty) {
          await _secureStorage.delete(key: _kOauthToken);
        } else {
          await _secureStorage.write(key: _kOauthToken, value: oauthToken);
        }
      } on MissingPluginException {
        pluginAvailable = false;
      } catch (_) {}
    }

    try {
      await _legacyStorage.ready;
      if (pluginAvailable) {
        if (accessToken != null) await _legacyStorage.deleteItem(_kAccessToken);
        if (refreshToken != null) await _legacyStorage.deleteItem(_kRefreshToken);
        if (oauthToken != null) await _legacyStorage.deleteItem(_kOauthToken);
      } else {
        // Fallback only in headless unit test environments without native plugins
        if (accessToken != null) await _legacyStorage.setItem(_kAccessToken, accessToken);
        if (refreshToken != null) await _legacyStorage.setItem(_kRefreshToken, refreshToken);
        if (oauthToken != null) await _legacyStorage.setItem(_kOauthToken, oauthToken);
      }
    } catch (_) {}
  }

  /// Wipes all tokens from memory, secure storage, and legacy local storage.
  static Future<void> clearTokens() async {
    _cachedAccessToken = null;
    _cachedRefreshToken = null;
    _cachedOauthToken = null;
    try {
      await _secureStorage.delete(key: _kAccessToken);
      await _secureStorage.delete(key: _kRefreshToken);
      await _secureStorage.delete(key: _kOauthToken);
    } catch (_) {}
    try {
      await _legacyStorage.ready;
      await _legacyStorage.deleteItem(_kAccessToken);
      await _legacyStorage.deleteItem(_kRefreshToken);
      await _legacyStorage.deleteItem(_kOauthToken);
    } catch (_) {}
  }
}


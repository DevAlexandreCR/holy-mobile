import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthTokenService {
  AuthTokenService({FlutterSecureStorage? storage, MethodChannel? channel})
    : _storage = storage ?? const FlutterSecureStorage(),
      _channel = channel ?? const MethodChannel('bible_widget/auth');

  static const _tokenKey = 'auth_token';
  final FlutterSecureStorage _storage;
  final MethodChannel _channel;

  /// Initializes native configuration (API URL)
  Future<void> initializeNativeConfig(String apiUrl) async {
    try {
      await _channel.invokeMethod<void>('setApiUrl', apiUrl);
    } catch (e) {
      print('Warning: Failed to set API URL in native storage: $e');
    }
  }

  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
    // Also persist in SharedPreferences/UserDefaults for native usage
    try {
      await _channel.invokeMethod<void>('saveJwtToken', token);
    } catch (e) {
      // Non-critical if it fails because the token is in secure storage
      print('Warning: Failed to save JWT token to native storage: $e');
    }
  }

  Future<String?> readToken() {
    return _storage.read(key: _tokenKey);
  }

  Future<void> clearToken() async {
    await _storage.delete(key: _tokenKey);
    // Also clear from native storage
    try {
      await _channel.invokeMethod<void>('clearJwtToken');
    } catch (e) {
      print('Warning: Failed to clear JWT token from native storage: $e');
    }
  }
}

final authTokenServiceProvider = Provider<AuthTokenService>((ref) {
  return AuthTokenService();
});

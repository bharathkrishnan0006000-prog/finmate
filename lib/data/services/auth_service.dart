import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

/// Handles PIN storage (hashed, never stored in plaintext) and biometric
/// prompts. Nothing here ever leaves the device — flutter_secure_storage
/// uses the Android Keystore under the hood.
class AuthService {
  static const _pinKey = 'finmate_pin_hash';
  final _storage = const FlutterSecureStorage();
  final _localAuth = LocalAuthentication();

  String _hash(String pin) => sha256.convert(utf8.encode(pin)).toString();

  Future<void> setPin(String pin) => _storage.write(key: _pinKey, value: _hash(pin));

  Future<bool> hasPin() async => (await _storage.read(key: _pinKey)) != null;

  Future<bool> verifyPin(String pin) async {
    final stored = await _storage.read(key: _pinKey);
    return stored != null && stored == _hash(pin);
  }

  Future<void> clearPin() => _storage.delete(key: _pinKey);

  Future<bool> isBiometricAvailable() async {
    try {
      final supported = await _localAuth.isDeviceSupported();
      final canCheck = await _localAuth.canCheckBiometrics;
      return supported && canCheck;
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticateWithBiometrics() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Unlock FinMate',
        options: const AuthenticationOptions(biometricOnly: true, stickyAuth: true),
      );
    } catch (_) {
      return false;
    }
  }
}

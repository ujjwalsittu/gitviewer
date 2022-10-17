
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:gitviewer/auth/infrastructure/credentials_storage/credentials_storage.dart';
// ignore: implementation_imports
import 'package:oauth2/src/credentials.dart';

class SecureCredentialsStorage implements CredentialStorage {
  final FlutterSecureStorage _storage;

  SecureCredentialsStorage(this._storage);

  static const _key = 'oauth2_credentials';

  Credentials? _cachedCredentials;
  @override
  Future<Credentials?> read() async {
    if (_cachedCredentials != null) {
      return _cachedCredentials;
    }

    final json = await _storage.read(key: _key);
    if (json == null) {
      return null;
    }
    try {
      return _cachedCredentials = Credentials.fromJson(json);
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> save(Credentials credentials) {
    _cachedCredentials = credentials;
    return _storage.write(key: _key, value: credentials.toJson());
  }

  @override
  Future<void> clear() {
    _cachedCredentials = null;
    return _storage.delete(key: _key);
  }
}

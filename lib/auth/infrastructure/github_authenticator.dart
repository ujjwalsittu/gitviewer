import 'package:flutter/services.dart';
import 'package:gitviewer/auth/infrastructure/credentials_storage/credentials_storage.dart';
import 'package:oauth2/oauth2.dart';

class GithubAuthenticator {
  final CredentialStorage _credentialStorage;

  GithubAuthenticator(this._credentialStorage);

  static final authorizationEndpoint =
      Uri.parse('https://github.com/login/oauth/authorize');
  //TODO: Pass Your Callback Url Here
  static final redirectEndpoint = Uri.parse('pass_your_call_back_url_here');
  //TODO: Pass Scopes Here As Per Your Requirement
  static final scope = ['read:user', 'repo'];
  static final tokenEndpoint =
      Uri.parse('https://github.com/login/oauth/access_token');
  //TODO: Pass Your Client Id Here
  static const clientId = 'pass_your_client_id_here';
  //TODO: Pass Your Client Secret Here
  static const clientSecret = 'pass_your_client_secret_here';

  Future<Credentials?> getSignedInCredentials() async {
    try {
      final storedCredentials = await _credentialStorage.read();
      return storedCredentials;
    } on PlatformException {
      return null;
    }
  }

  Future<bool> isSignedIn() =>
      getSignedInCredentials().then((value) => value != null);

  AuthorizationCodeGrant createGrant() {
    return AuthorizationCodeGrant(
      clientId,
      authorizationEndpoint,
      tokenEndpoint,
      secret: clientSecret,
    );
  }

  Uri getAuthorizationUrl(AuthorizationCodeGrant grant) {
    return grant.getAuthorizationUrl(redirectEndpoint, scopes: scope);
  }
}

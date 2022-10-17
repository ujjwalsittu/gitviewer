import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gitviewer/auth/domain/auth_failure.dart';
import 'package:gitviewer/auth/infrastructure/credentials_storage/credentials_storage.dart';
import 'package:gitviewer/core/shared/encoders.dart';
import 'package:oauth2/oauth2.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;

class GithubOAuthHttpClient extends http.BaseClient {
  final httpClient = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Accept'] = 'application/json';
    return httpClient.send(request);
  }
}

class GithubAuthenticator {
  final CredentialStorage _credentialStorage;

  GithubAuthenticator(this._credentialStorage);
  final dio = Dio();

  static final authorizationEndpoint =
      Uri.parse(dotenv.env['GITHUB_AUTHORIZATION_ENDPOINT']!);
  static final redirectEndpoint =
      Uri.parse(dotenv.env['GITHUB_REDIRECT_ENDPOINT']!);
  static final scope = ['read:user', 'repo'];
  static final tokenEndpoint = Uri.parse(dotenv.env['GITHUB_TOKEN_ENDPOINT']!);
  static final clientId = dotenv.env['GITHUB_CLIENT_ID']!;
  static final clientSecret = dotenv.env['GITHUB_CLIENT_SECRET']!;
  static final revocationEndpoint =
      Uri.parse(dotenv.env['GITHUB_REVOCATION_ENDPOINT']!);

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
      httpClient: GithubOAuthHttpClient(),
    );
  }

  Uri getAuthorizationUrl(AuthorizationCodeGrant grant) {
    return grant.getAuthorizationUrl(redirectEndpoint, scopes: scope);
  }

  Future<Either<AuthFailure, Unit>> handleAuthorizationResponse(
      AuthorizationCodeGrant grant, Map<String, String> queryParams) async {
    try {
      final httpClient = await grant.handleAuthorizationResponse(queryParams);
      await _credentialStorage.save(httpClient.credentials);

      return right(unit);
    } on FormatException {
      return left(const AuthFailure.server());
    } on AuthorizationException catch (e) {
      return left(AuthFailure.server('${e.error}: ${e.description}'));
    } on PlatformException {
      return left(const AuthFailure.storage());
    }
  }

  Future<Either<AuthFailure, Unit>> signOut() async {
    final accessToken =
        await _credentialStorage.read().then((value) => value?.accessToken);

    final auth64 = stringToBase64.encode('$clientId:$clientSecret');
    try {
      dio.delete(revocationEndpoint.toString(),
          data: {
            'access_token': accessToken,
          },
          options: Options(
            headers: {
              'Authorization': 'basic $auth64',
            },
          ));
      await _credentialStorage.clear();
      return right(unit);
    } on PlatformException {
      return left(const AuthFailure.storage());
    }
  }
}

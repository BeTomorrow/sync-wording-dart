import 'dart:convert';
import 'dart:io';

import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:sync_wording_dart/config/wording_config.dart';

const _scopes = [
  "https://www.googleapis.com/auth/drive",
  "https://www.googleapis.com/auth/drive.file",
  "https://www.googleapis.com/auth/spreadsheets",
];

class GoogleAuth {
  Future<AutoRefreshingAuthClient> authenticate(CredentialsConfig config, http.Client httpClient) async {
    final storedCredentials = await _readCredentials(config);
    if (storedCredentials != null) {
      return autoRefreshingClient(ClientId(config.clientId, config.clientSecret), storedCredentials, httpClient);
    }
    return await _requestUserConsentedClient(config, httpClient);
  }

  Future<AutoRefreshingAuthClient> _requestUserConsentedClient(CredentialsConfig config, http.Client httpClient) async {
    try {
      final client = await clientViaUserConsent(ClientId(config.clientId, config.clientSecret), _scopes, (url) {
        print('Please go to the following URL and grant access:');
        print('  => $url');
        print('');
      }, baseClient: httpClient);
      await _writeCredentials(config, client.credentials);
      return client;
    } catch (e) {
      print("Get AccessCredentials error : $e");
      rethrow;
    }
  }

  Future<AccessCredentials?> _readCredentials(CredentialsConfig config) async {
    final file = File(config.credentialsFile);
    if (await file.exists()) {
      try {
        final jsonStr = await file.readAsString();
        return AccessCredentials.fromJson(jsonDecode(jsonStr));
      } catch (e) {
        print("Error reading '${config.credentialsFile}' => delete file");
        await file.delete();
      }
    }
    return null;
  }

  Future<void> _writeCredentials(CredentialsConfig config, AccessCredentials credentials) async {
    final file = File(config.credentialsFile);
    try {
      await file.writeAsString(jsonEncode(credentials.toJson()));
      print("Token stored to '${config.credentialsFile}'");
    } catch (e) {
      print("Error writing '${config.credentialsFile}' file : $e");
    }
  }
}

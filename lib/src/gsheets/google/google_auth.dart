import 'dart:convert';
import 'dart:io';

import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:sync_wording/src/config/wording_config.dart';

/// Google scopes needed to access the spreadsheet
const _scopes = [
  "https://www.googleapis.com/auth/drive",
  "https://www.googleapis.com/auth/drive.file",
  "https://www.googleapis.com/auth/spreadsheets",
];

/// This class manages the Google authentication
class GoogleAuth {
  ///
  Future<AutoRefreshingAuthClient> authenticate(
      CredentialsConfig config, http.Client httpClient) async {
    final storedCredentials = await _readCredentials(config);
    if (storedCredentials != null) {
      return autoRefreshingClient(
          ClientId(config.clientId, config.clientSecret),
          storedCredentials,
          httpClient);
    }
    return await _requestUserConsentedClient(config, httpClient);
  }

  /// Create a client that will ask the user to consent the access
  /// to the Google API
  Future<AutoRefreshingAuthClient> _requestUserConsentedClient(
      CredentialsConfig config, http.Client httpClient) async {
    try {
      final client = await clientViaUserConsent(
          ClientId(config.clientId, config.clientSecret), _scopes, (url) {
        stdout.writeln('Please go to the following URL and grant access:');
        stdout.writeln('  => $url');
        stdout.writeln('');
      }, baseClient: httpClient);
      await _writeCredentials(config, client.credentials);
      return client;
    } catch (e) {
      stderr.write("Get AccessCredentials error : $e");
      rethrow;
    }
  }

  /// Retrieve the previously requested credentials from a file
  Future<AccessCredentials?> _readCredentials(CredentialsConfig config) async {
    final file = File(config.credentialsFile);
    if (await file.exists()) {
      try {
        final jsonStr = await file.readAsString();
        return AccessCredentials.fromJson(jsonDecode(jsonStr));
      } catch (e) {
        stdout.writeln(
            "Error reading '${config.credentialsFile}' => delete file");
        await file.delete();
      }
    }
    return null;
  }

  /// Write a file that will contain the consented credentials
  Future<void> _writeCredentials(
      CredentialsConfig config, AccessCredentials credentials) async {
    final file = File(config.credentialsFile);
    try {
      await file.writeAsString(jsonEncode(credentials.toJson()));
      stdout.writeln("Token stored to '${config.credentialsFile}'");
    } catch (e) {
      stderr.writeln("Error writing '${config.credentialsFile}' file : $e");
    }
  }
}

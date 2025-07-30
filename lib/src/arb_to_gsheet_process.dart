import 'package:http/http.dart' as http;
import 'package:sync_wording/src/arb/importer/arb_wording_importer.dart';
import 'package:sync_wording/src/config/wording_config.dart';
import 'package:sync_wording/src/gsheets/google/google_auth.dart';
import 'package:sync_wording/src/gsheets/google/xlsx_drive.dart';
import 'package:sync_wording/src/logger/logger.dart';
import 'package:sync_wording/src/wording/wording.dart';

class ArbToGsheetProcess {
  final Logger logger;
  final WordingConfig config;
  final http.Client httpClient;

  ArbToGsheetProcess(this.config, this.httpClient, this.logger);

  Future<void> run() async {
    logger.log("Starting upload to Google Sheets...");

    final localWordings = await _loadArbWordings(config);

    // Upload to Google Sheets
    await _uploadWordingsToGSheets(localWordings, config, httpClient, logger);
    logger.log("✅ Upload completed successfully!");
  }

  Future<void> _uploadWordingsToGSheets(
    Wordings wordings,
    WordingConfig config,
    http.Client httpClient,
    Logger logger,
  ) async {
    final client =
        await GoogleAuth().authenticate(config.credentials, httpClient);
    await XLSXDrive(client, logger).uploadWordings(config, wordings);
  }

  /// Analyze and log the differences between the existing wordings and the GSheets wordings
  Future<Wordings> _loadArbWordings(WordingConfig config) async {
    final importer = ARBWordingImporter();
    final localeFiles = {
      for (final language in config.languages)
        "${language.locale}": "${config.outputDir}/intl_${language.locale}.arb",
    };
    return await importer.import(localeFiles);
  }
}

import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:sync_wording/src/arb/exporter/arb_wording_exporter.dart';
import 'package:sync_wording/src/arb/importer/arb_wording_importer.dart';
import 'package:sync_wording/src/config/wording_config.dart';
import 'package:sync_wording/src/gsheets/google/google_auth.dart';
import 'package:sync_wording/src/gsheets/google/xlsx_drive.dart';
import 'package:sync_wording/src/logger/logger.dart';
import 'package:sync_wording/src/wording/diff/wording_diff.dart';
import 'package:sync_wording/src/wording/diff/wording_diff_logger.dart';
import 'package:sync_wording/src/wording/processor/wording_processor_manager.dart';
import 'package:sync_wording/src/wording/wording.dart';

class GsheetToArbProcess {
  final Logger logger;
  final WordingConfig config;
  final http.Client httpClient;

  GsheetToArbProcess(this.config, this.httpClient, this.logger);

  Future<void> run() async {
    final wordings = await _loadGSheetsWordings(config, httpClient, logger);

    final existingWordings = await _loadArbWordings(config);
    await _detectAndLogDifferences(existingWordings, wordings, logger);

    await _exportARBs(wordings, config.outputDir, logger);

    if (config.genL10n.autoCall) {
      await _callGenL10n(config.genL10n.withFvm, logger);
    } else {
      logger.log("✅ Localization files generated successfully");
    }
  }

  Future<Wordings> _loadGSheetsWordings(
    WordingConfig config,
    http.Client httpClient,
    Logger logger,
  ) async {
    /// Authenticate to Google and retrieve specified spreadsheet
    final client =
        await GoogleAuth().authenticate(config.credentials, httpClient);
    final wordings = await XLSXDrive(client, logger).downloadWordings(config);

    /// Detect warnings and fix errors if possible
    final wordingProcessorManager = WordingProcessorManager(
      wordings,
      logger,
      config.fallback,
    );
    wordingProcessorManager.process();

    return wordings;
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

  Future<void> _detectAndLogDifferences(
    Wordings oldWordings,
    Wordings newWordings,
    Logger logger,
  ) async {
    final (addedKeys, modifiedKeys, removedKeys) =
        WordingDiff(oldWordings, newWordings).getDifferences();
    WordingDiffLogger(logger).log(addedKeys, modifiedKeys, removedKeys);
  }

  /// Export ARB files containing the translations
  Future<void> _exportARBs(
    Wordings wordings,
    String outputDir,
    Logger logger,
  ) async {
    final exporter = ARBWordingExporter();
    for (final locale in wordings.keys) {
      await exporter.export(
        locale,
        wordings[locale]!,
        "$outputDir/intl_$locale.arb",
      );
    }
  }

  /// Generate AppLocalization files
  Future<void> _callGenL10n(bool withFvm, Logger logger) async {
    try {
      logger.log("Generating localization Dart files...");

      final result = withFvm
          ? await Process.run("fvm", ["flutter", "gen-l10n"])
          : await Process.run("flutter", ["gen-l10n"]);

      if (result.exitCode == 0) {
        logger.log("✅ Localization Dart files generated successfully");
      } else {
        logger.log("❌ Failed to generate localization Dart files");
        logger.log("Error: ${result.stderr}");
        logger.log("Exit code: ${result.exitCode}");
      }
    } catch (e) {
      logger.log("❌ Error executing gen-l10n command: $e");
    }
  }
}

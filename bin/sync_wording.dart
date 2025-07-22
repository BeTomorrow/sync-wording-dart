import 'dart:io';

import 'package:args/args.dart';
import 'package:http/http.dart' as http;
import 'package:sync_wording/config/wording_config_loader.dart';
import 'package:sync_wording/exporter/arb/arb_wording_exporter.dart';
import 'package:sync_wording/google/google_auth.dart';
import 'package:sync_wording/google/xlsx_drive.dart';
import 'package:sync_wording/importer/arb/arb_wording_importer.dart';
import 'package:sync_wording/logger/logger.dart';
import 'package:sync_wording/spreadsheet_converter/xlsx_converter/xlsx_converter.dart';
import 'package:sync_wording/wording_diff/wording_diff.dart';
import 'package:sync_wording/wording_diff/wording_diff_logger.dart';
import 'package:sync_wording/wording_processor/wording_processor_manager.dart';

Future<void> main(List<String> arguments) async {
  late final http.Client httpClient;

  final logger = ConsoleLogger();

  try {
    httpClient = http.Client();

    final parser = ArgParser()
      ..addOption(
        "config",
        abbr: "c",
        defaultsTo: "wording_config.yaml",
        help: "Path to config file",
      )
      ..addFlag(
        'help',
        abbr: 'h',
        help: 'Provide usage instruction',
        negatable: false,
      );

    ArgResults argResults = parser.parse(arguments);

    if (argResults.wasParsed('help')) {
      logger.log(parser.usage);
      exit(0);
    }

    /// Build the configuration to apply to this program
    final config =
        await WordingConfigLoader().loadConfiguration(argResults["config"]);

    /// Authenticate to Google and retrieve specified spreadsheet
    final client =
        await GoogleAuth().authenticate(config.credentials, httpClient);
    final spreadsheet = await XLSXDrive(client).getSpreadsheet(config.sheetId);

    /// Convert the spreadsheet to the internal model
    final wordings = await XLSXConverter().convert(spreadsheet, config);
    httpClient.close();

    /// Detect warnings
    final wordingProcessorManager =
        WordingProcessorManager(wordings, logger, config.fallback);
    wordingProcessorManager.process();

    /// Verify differences between the existing wordings and the GSheets wordings
    final importer = ARBWordingImporter();
    final existingWordings = await importer.import({
      "en": "${config.outputDir}/intl_en.arb",
      "fr": "${config.outputDir}/intl_fr.arb",
    });

    /// Detect differences between the existing wordings and the GSheets wordings
    final (addedKeys, modifiedKeys, removedKeys) =
        WordingDiff(existingWordings, wordings).diff();
    WordingDiffLogger(logger).log(addedKeys, modifiedKeys, removedKeys);

    /// Export ARB files containing the translations
    final exporter = ARBWordingExporter();
    for (final locale in wordings.keys) {
      await exporter.export(
          locale, wordings[locale]!, "${config.outputDir}/intl_$locale.arb");
    }

    /// Generate AppLocalization files
    if (config.genL10n.autoCall) {
      try {
        logger.log("Generating localization Dart files...");

        final result = config.genL10n.withFvm
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
  } catch (e) {
    logger.log("SyncWording failed with error : $e");
    httpClient.close();
    exit(1);
  }
  exit(0);
}

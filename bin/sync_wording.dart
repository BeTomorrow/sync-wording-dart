import 'dart:io';

import 'package:args/args.dart';
import 'package:http/http.dart' as http;
import 'package:sync_wording/config/wording_config.dart';
import 'package:sync_wording/config/wording_config_loader.dart';
import 'package:sync_wording/exporter/arb/arb_wording_exporter.dart';
import 'package:sync_wording/google/google_auth.dart';
import 'package:sync_wording/google/xlsx_drive.dart';
import 'package:sync_wording/importer/arb/arb_wording_importer.dart';
import 'package:sync_wording/logger/logger.dart';
import 'package:sync_wording/spreadsheet_converter/xlsx_converter/xlsx_converter.dart';
import 'package:sync_wording/wording.dart';
import 'package:sync_wording/wording_diff/wording_diff.dart';
import 'package:sync_wording/wording_diff/wording_diff_logger.dart';
import 'package:sync_wording/wording_processor/wording_processor_manager.dart';

Future<void> main(List<String> arguments) async {
  final logger = ConsoleLogger();

  final httpClient = http.Client();

  try {
    final parser = _buildArgsParser();
    ArgResults argResults = parser.parse(arguments);

    if (argResults.wasParsed('help')) {
      logger.log(parser.usage);
      exit(0);
    }

    final config =
        await WordingConfigLoader().loadConfiguration(argResults["config"]);

    final wordings = await _loadGSheetsWordings(config, httpClient, logger);

    final existingWordings = await _loadArbWordings(config);
    await _detectAndLogDifferences(existingWordings, wordings, logger);

    await _exportARBs(wordings, config.outputDir, logger);

    if (config.genL10n.autoCall) {
      await _callGenL10n(config.genL10n.withFvm, logger);
    }
  } catch (e) {
    logger.log("SyncWording failed with error : $e");
    httpClient.close();
    exit(1);
  }
  exit(0);
}

ArgParser _buildArgsParser() => ArgParser()
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

Future<Wordings> _loadGSheetsWordings(
    WordingConfig config, http.Client httpClient, Logger logger) async {
  /// Authenticate to Google and retrieve specified spreadsheet
  final client =
      await GoogleAuth().authenticate(config.credentials, httpClient);
  final spreadsheet = await XLSXDrive(client).getSpreadsheet(config.sheetId);

  /// Convert the spreadsheet to the internal model
  final wordings = await XLSXConverter().convert(spreadsheet, config);
  httpClient.close();

  /// Detect warnings and fix errors if possible
  final wordingProcessorManager =
      WordingProcessorManager(wordings, logger, config.fallback);
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
        locale, wordings[locale]!, "$outputDir/intl_$locale.arb");
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

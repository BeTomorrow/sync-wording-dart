import 'dart:io';

import 'package:args/args.dart';
import 'package:http/http.dart' as http;
import 'package:sync_wording/arb/exporter/arb_wording_exporter.dart';
import 'package:sync_wording/arb/importer/arb_wording_importer.dart';
import 'package:sync_wording/config/wording_config.dart';
import 'package:sync_wording/config/wording_config_loader.dart';
import 'package:sync_wording/gsheets/google/google_auth.dart';
import 'package:sync_wording/gsheets/google/xlsx_drive.dart';
import 'package:sync_wording/gsheets/spreadsheet_converter/xlsx_converter/xlsx_converter.dart';
import 'package:sync_wording/logger/logger.dart';
import 'package:sync_wording/wording/diff/wording_diff.dart';
import 'package:sync_wording/wording/diff/wording_diff_logger.dart';
import 'package:sync_wording/wording/processor/wording_processor_manager.dart';
import 'package:sync_wording/wording/wording.dart';

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

    if (argResults.wasParsed('upload')) {
      await _uploadToGSheets(config, httpClient, logger);
    } else {
      await _downloadFromGSheets(config, httpClient, logger);
    }
  } catch (e) {
    logger.log("❌ SyncWording failed with error : $e");
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
  )
  ..addFlag(
    'upload',
    abbr: 'u',
    help: 'Upload local ARB files to Google Sheets (reverse sync)',
    negatable: false,
  );

Future<void> _downloadFromGSheets(
    WordingConfig config, http.Client httpClient, Logger logger) async {
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

Future<void> _uploadToGSheets(
  WordingConfig config,
  http.Client httpClient,
  Logger logger,
) async {
  logger.log("Starting upload to Google Sheets...");

  final localWordings = await _loadArbWordings(config);

  final gsheetsWordings =
      await _loadGSheetsWordings(config, httpClient, logger);

  final (addedKeys, modifiedKeys, removedKeys) =
      WordingDiff(gsheetsWordings, localWordings).getDifferences();
  WordingDiffLogger(logger).log(addedKeys, modifiedKeys, removedKeys);

  // Check for destructive changes
  if (removedKeys.isNotEmpty || modifiedKeys.isNotEmpty) {
    logger.log(
        "\n⚠️  WARNING: This operation will modify or remove existing data in Google Sheets!");
    logger.log("📝 Keys to be modified: ${modifiedKeys.join(', ')}");
    logger.log("🗑️  Keys to be removed: ${removedKeys.join(', ')}");

    final confirmed = await _askForConfirmation(logger);
    if (!confirmed) {
      logger.log("❌ Upload cancelled by user");
      return;
    }
  }

  // Upload to Google Sheets
  await _uploadWordingsToGSheets(localWordings, config, httpClient, logger);
  logger.log("✅ Upload completed successfully!");
}

Future<bool> _askForConfirmation(Logger logger) async {
  logger.log("\nDo you want to continue? (y/N): ");

  final input = stdin.readLineSync()?.toLowerCase().trim();
  return input == 'y' || input == 'yes';
}

Future<void> _uploadWordingsToGSheets(
  Wordings wordings,
  WordingConfig config,
  http.Client httpClient,
  Logger logger,
) async {
  logger.log("📤 Uploading to Google Sheets...");

  // TODO: Implement the actual upload logic
  // This would require implementing a method to convert Wordings back to spreadsheet format
  // and upload it to Google Sheets

  logger.log("⚠️  Upload functionality not yet implemented");
  logger.log(
      "This would convert the local wordings back to spreadsheet format and upload to Google Sheets");
}

Future<Wordings> _loadGSheetsWordings(
  WordingConfig config,
  http.Client httpClient,
  Logger logger,
) async {
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

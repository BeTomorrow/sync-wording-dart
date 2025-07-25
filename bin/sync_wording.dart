import 'dart:io';

import 'package:args/args.dart';
import 'package:http/http.dart' as http;
import 'package:sync_wording/src/arb_to_gsheet_process.dart';
import 'package:sync_wording/src/config/wording_config_loader.dart';
import 'package:sync_wording/src/gsheet_to_arb_process.dart';
import 'package:sync_wording/src/logger/logger.dart';

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
      final arbToGsheetProcess = ArbToGsheetProcess(config, httpClient, logger);
      await arbToGsheetProcess.run();
    } else {
      final gsheetToArbProcess = GsheetToArbProcess(config, httpClient, logger);
      await gsheetToArbProcess.run();
    }
  } catch (e) {
    logger.log("❌ SyncWording failed with error : $e");
    httpClient.close();
    exit(1);
  }
  httpClient.close();
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

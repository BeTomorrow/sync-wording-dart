import 'dart:io';

import 'package:args/args.dart';
import 'package:http/http.dart' as http;
import 'package:sync_wording/config/wording_config_loader.dart';
import 'package:sync_wording/exporter/arb/arb_wording_exporter.dart';
import 'package:sync_wording/google/google_auth.dart';
import 'package:sync_wording/google/xlsx_drive.dart';
import 'package:sync_wording/spreadsheet_converter/xlsx_converter/xlsx_converter.dart';

Future<void> main(List<String> arguments) async {
  late final http.Client httpClient;

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
      print(parser.usage);
      exit(0);
    }

    final config =
        await WordingConfigLoader().loadConfiguration(argResults["config"]);

    final client =
        await GoogleAuth().authenticate(config.credentials, httpClient);
    final spreadsheet = await XLSXDrive(client).getSpreadsheet(config.sheetId);

    final result = await XLSXConverter().convert(spreadsheet, config);
    httpClient.close();

    final exporter = ARBWordingExporter();
    for (final locale in result.keys) {
      await exporter.export(
          locale, result[locale]!, "${config.outputDir}/intl_$locale.arb");
    }

    if (config.genL10n.autoCall) {
      if (config.genL10n.withFvm) {
        await Process.run("fvm", ["flutter", "gen-l10n"]);
      } else {
        await Process.run("flutter", ["gen-l10n"]);
      }
    }
  } catch (e) {
    print("SyncWording failed with error : $e");
    httpClient.close();
    exit(1);
  }
}

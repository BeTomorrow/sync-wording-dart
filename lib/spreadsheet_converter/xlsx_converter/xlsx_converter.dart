import 'dart:io';

import 'package:gsheets/gsheets.dart';
import 'package:sync_wording/config/wording_config.dart';
import 'package:sync_wording/spreadsheet_converter/validator/validator.dart';
import 'package:sync_wording/spreadsheet_converter/wording_parser.dart';
import 'package:sync_wording/wording.dart';

class XLSXConverter {
  final _parser = WordingParser();

  Future<WordingResult> convert(Spreadsheet spreadsheet, WordingConfig config) async {
    final sheetNames = config.sheetNames;

    WordingResult result = {};
    for (final l in config.languages) {
      result[l.locale] = {};
    }

    for (final worksheet in spreadsheet.sheets) {
      if (sheetNames.isEmpty || sheetNames.contains(worksheet.title)) {
        WordingResult worksheetResult = await _convertWorksheet(worksheet, config);

        for (final l in worksheetResult.keys) {
          result[l]!.addAll(worksheetResult[l]!);
        }
      }
    }
    return result;
  }

  Future<WordingResult> _convertWorksheet(Worksheet worksheet, WordingConfig config) async {
    final languages = config.languages;
    final validator = Validator.get(config.validation);

    WordingResult result = {};
    if (worksheet.rowCount < 2) {
      stdout.writeln("Not enough data in worksheet '${worksheet.title}' !");
      return result;
    }

    for (final languageConfig in languages) {
      final languageResult = <String, WordingEntry>{};
      result[languageConfig.locale] = languageResult;

      final values = worksheet.values;
      final allRows = await values.allRows(fromRow: 2);

      for (final row in allRows) {
        _addWording(languageResult, row, config.keyColumn, languageConfig.column, validator);
      }
    }

    return result;
  }

  void _addWording(
    Map<String, WordingEntry> result,
    List<String> row,
    int keyColumn,
    int valueColumn,
    Validator validator,
  ) {
    if (validator.isValid(row)) {
      final key = row[keyColumn - 1];
      final value = row[valueColumn - 1];
      result[key] = _parser.parse(value);
    }
  }
}

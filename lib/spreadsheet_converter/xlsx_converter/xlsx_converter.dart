import 'dart:io';

import 'package:gsheets/gsheets.dart';
import 'package:sync_wording/config/wording_config.dart';
import 'package:sync_wording/spreadsheet_converter/validator/validator.dart';
import 'package:sync_wording/spreadsheet_converter/wording_parser.dart';
import 'package:sync_wording/wording.dart';

class XLSXConverter {
  final _parser = WordingParser();

  /// Convert the data set in the spreadsheet in Objects defined by the model
  Future<Wordings> convert(Spreadsheet spreadsheet, WordingConfig config) async {
    final sheetNames = config.sheetNames;

    Wordings wordings = {};
    for (final l in config.languages) {
      wordings[l.locale] = {};
    }

    for (final worksheet in spreadsheet.sheets) {
      if (sheetNames.isEmpty || sheetNames.contains(worksheet.title)) {
        Wordings worksheetResult = await _convertWorksheet(worksheet, config);

        for (final l in worksheetResult.keys) {
          wordings[l]!.addAll(worksheetResult[l]!);
        }
      }
    }
    return wordings;
  }

  /// Convert the data set in the worksheet in Objects defined by the model
  Future<Wordings> _convertWorksheet(Worksheet worksheet, WordingConfig config) async {
    final languages = config.languages;
    final validator = Validator.get(config.validation);

    Wordings wordings = {};
    if (worksheet.rowCount < 2) {
      stdout.writeln("Not enough data in worksheet '${worksheet.title}' !");
      return wordings;
    }

    for (final languageConfig in languages) {
      final LanguageWordings languageWordings = {};
      wordings[languageConfig.locale] = languageWordings;

      final values = worksheet.values;
      final allRows = await values.allRows(fromRow: 2);

      for (final row in allRows) {
        _addWording(languageWordings, row, config.keyColumn, languageConfig.column, validator);
      }
    }

    return wordings;
  }

  /// Convert the data set in the row a WordingEntry if the row is valid
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

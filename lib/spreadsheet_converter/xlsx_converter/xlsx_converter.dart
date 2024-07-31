import 'package:gsheets/gsheets.dart';
import 'package:sync_wording_dart/config/wording_config.dart';
import 'package:sync_wording_dart/spreadsheet_converter/validator/validator.dart';
import 'package:sync_wording_dart/spreadsheet_converter/wording_parser.dart';
import 'package:sync_wording_dart/wording.dart';

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
      print("Not enough data in worksheet '${worksheet.title}' !");
      return result;
    }

    for (final languageConfig in languages) {
      final languageResult = <String, WordingEntry>{};
      result[languageConfig.locale] = languageResult;

      final values = worksheet.values;
      final allRows = await values.allRows(fromRow: 2);
      final filledRows = allRows.takeWhile((row) => row[0].isNotEmpty);

      for (final row in filledRows) {
        _addWording(languageResult, row, languageConfig.column, validator);
      }
    }

    return result;
  }

  void _addWording(Map<String, WordingEntry> result, List<String> row, int valueColumn, Validator validator) {
    if (validator.isValid(row)) {
      final key = row[0];
      final value = row[valueColumn - 1];
      result[key] = _parser.parse(value);
    }
  }
}

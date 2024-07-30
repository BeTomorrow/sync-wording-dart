import 'package:gsheets/gsheets.dart';
import 'package:sync_wording_dart/config/wording_config.dart';
import 'package:sync_wording_dart/spreadsheet_converter/wording_parser.dart';
import 'package:sync_wording_dart/wording.dart';

class XLSXConverter {
  final _parser = WordingParser();

  Future<WordingResult> convert(
    Spreadsheet spreadsheet,
    List<String> sheetNames,
    List<LanguageConfig> languages,
  ) async {
    WordingResult result = {};
    for (final l in languages) {
      result[l.locale] = {};
    }

    for (final worksheet in spreadsheet.sheets) {
      if (sheetNames.isEmpty || sheetNames.contains(worksheet.title)) {
        WordingResult worksheetResult = await _convertWorksheet(worksheet, languages);

        for (final l in worksheetResult.keys) {
          result[l]!.addAll(worksheetResult[l]!);
        }
      }
    }
    return result;
  }

  Future<WordingResult> _convertWorksheet(Worksheet worksheet, List<LanguageConfig> languages) async {
    WordingResult result = {};
    for (final l in languages) {
      result[l.locale] = {};
    }

    if (worksheet.rowCount < 2) {
      print("Not enough data in worksheet '${worksheet.title}' !");
      return result;
    }

    for (final languageConfig in languages) {
      final locale = languageConfig.locale;
      final column = languageConfig.column;

      final values = worksheet.values;

      final allRows = await values.allRows(fromRow: 2);
      for (final row in allRows) {
        final key = row[0];
        if (key.isEmpty) {
          break;
        }
        final value = row[column - 1];
        result[locale]![key] = _parser.parse(value);
      }
    }

    return result;
  }
}

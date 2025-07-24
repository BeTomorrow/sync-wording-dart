import 'package:googleapis/sheets/v4.dart';
import 'package:sync_wording/src/config/wording_config.dart';
import 'package:sync_wording/src/gsheets/spreadsheet/converter/spreadsheet_parser.dart';
import 'package:sync_wording/src/gsheets/spreadsheet/converter/validator.dart';
import 'package:sync_wording/src/wording/wording.dart';

class SpreadsheetConverter {
  final _parser = SpreadsheetParser();

  /// Convert the data set in the spreadsheet in Objects defined by the model
  Future<Wordings> convertToWordings(
    Spreadsheet spreadsheet,
    WordingConfig config,
  ) async {
    Wordings wordings = {};
    for (final l in config.languages) {
      wordings[l.locale] = {};
    }

    final sheets = spreadsheet.sheets ?? [];
    for (final sheet in sheets) {
      if (config.isSheetNameValid(sheet.properties?.title)) {
        Wordings worksheetResult = await _convertSheetToWordings(sheet, config);

        for (final l in worksheetResult.keys) {
          wordings[l]!.addAll(worksheetResult[l]!);
        }
      }
    }

    return wordings;
  }

  /// Convert the data set in the worksheet in Objects defined by the model
  Future<Wordings> _convertSheetToWordings(
      Sheet sheet, WordingConfig config) async {
    final languages = config.languages;
    final validator = Validator.get(config.validation);

    Wordings wordings = {};

    for (final languageConfig in languages) {
      final LanguageWordings languageWordings = {};
      wordings[languageConfig.locale] = languageWordings;
    }

    final sheetData = sheet.data;
    if (sheetData != null) {
      final List<RowData> allRowData = sheetData
          .expand<RowData>((gridData) => gridData.rowData ?? [])
          .skip(config.sheetStartIndex - 1)
          .toList();

      for (final rowData in allRowData) {
        final rowValues =
            rowData.values?.map((v) => v.formattedValue).toList() ?? [];

        for (final languageConfig in languages) {
          _addWording(
            wordings[languageConfig.locale]!,
            rowValues,
            config.keyColumn,
            languageConfig.column,
            validator,
          );
        }
      }
    }

    return wordings;
  }

  /// Convert the data set in the row a WordingEntry if the row is valid
  void _addWording(
    Map<String, WordingEntry> result,
    List<String?> row,
    int keyColumn,
    int valueColumn,
    Validator validator,
  ) {
    if (validator.isValid(row)) {
      final key = row[keyColumn - 1];
      if (key != null) {
        final value = row[valueColumn - 1];
        result[key] = _parser.parse(value ?? '');
      }
    }
  }
}

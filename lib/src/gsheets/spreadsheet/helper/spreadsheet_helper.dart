import 'package:collection/collection.dart';
import 'package:googleapis/sheets/v4.dart';
import 'package:sync_wording/src/config/wording_config.dart';
import 'package:sync_wording/src/gsheets/spreadsheet/converter/validator.dart';

class SpreadsheetKeyLocation {
  final int? sheetIndex;
  final int? rowIndex;

  SpreadsheetKeyLocation._({required this.sheetIndex, required this.rowIndex});

  factory SpreadsheetKeyLocation.located(int sheetIndex, int rowIndex) =>
      SpreadsheetKeyLocation._(sheetIndex: sheetIndex, rowIndex: rowIndex);

  factory SpreadsheetKeyLocation.notFound() =>
      SpreadsheetKeyLocation._(sheetIndex: null, rowIndex: null);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpreadsheetKeyLocation &&
          sheetIndex == other.sheetIndex &&
          rowIndex == other.rowIndex;

  @override
  int get hashCode => sheetIndex.hashCode ^ rowIndex.hashCode;

  @override
  String toString() =>
      "SpreadsheetKeyLocation(sheetIndex: $sheetIndex, rowIndex: $rowIndex)";
}

extension SpreadsheetExtension on Spreadsheet {
  Sheet? firstValidSheet(WordingConfig config) => sheets!.firstWhereOrNull(
      (sheet) => config.isSheetNameValid(sheet.properties?.title));
}

SpreadsheetKeyLocation findKeyLocation(
  Spreadsheet spreadsheet,
  String key,
  WordingConfig config,
) {
  if (spreadsheet.sheets == null) {
    throw Exception('Spreadsheet has no sheets');
  }

  final validator = Validator.get(config.validation);

  for (int sheetIndex = 0;
      sheetIndex < spreadsheet.sheets!.length;
      sheetIndex++) {
    final sheet = spreadsheet.sheets![sheetIndex];

    if (!config.isSheetNameValid(sheet.properties?.title)) {
      continue;
    }

    final sheetData = sheet.data;
    if (sheetData == null) {
      continue;
    }

    final rows = sheetData
        .expand<RowData>((gridData) => gridData.rowData ?? [])
        .toList();

    for (int rowIndex = config.sheetStartIndex;
        rowIndex < rows.length;
        rowIndex++) {
      final row = rows[rowIndex];
      final rowValues = row.values?.map((v) => v.formattedValue).toList() ?? [];

      if (rowValues[config.keyColumn - 1] == key &&
          validator.isValid(rowValues)) {
        return SpreadsheetKeyLocation.located(sheetIndex, rowIndex);
      }
    }
  }

  return SpreadsheetKeyLocation.notFound();
}

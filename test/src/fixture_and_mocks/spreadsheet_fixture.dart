import 'package:collection/collection.dart';
import 'package:googleapis/sheets/v4.dart';

/// Fixture class for creating test spreadsheets with predefined data
class SpreadsheetFixture {
  /// Creates a spreadsheet from a map of sheet names to their row data
  ///
  /// Example:
  /// ```dart
  /// final spreadsheet = SpreadsheetFixture.fromSheetWithRows({
  ///   'Sheet1': [
  ///     ['Key', 'English', 'French'],
  ///     ['welcome', 'Welcome', 'Bienvenue'],
  ///   ],
  /// });
  /// ```
  static Spreadsheet fromSheetWithRows(
      Map<String, List<List<String>>?> sheets) {
    return Spreadsheet(
      sheets: sheets.entries.mapIndexed((sheetIndex, entry) {
        return Sheet(
          properties: SheetProperties(
            title: entry.key,
            sheetId: sheetIndex,
          ),
          data: [gridDataFromRows(entry.value)],
        );
      }).toList(),
    );
  }

  /// Creates a simple spreadsheet with a single sheet and basic data
  ///
  /// Example:
  /// ```dart
  /// final spreadsheet = SpreadsheetFixture.simple([
  ///   ['Key', 'English', 'French'],
  ///   ['welcome', 'Welcome', 'Bienvenue'],
  /// ]);
  /// ```
  static Spreadsheet simple(List<List<String>> rows) {
    return fromSheetWithRows({'Sheet1': rows});
  }

  /// Creates an empty spreadsheet with a single sheet
  static Spreadsheet empty() {
    return fromSheetWithRows({'Sheet1': []});
  }

  /// Creates a spreadsheet with no data (null rows)
  static Spreadsheet withNoData() {
    return fromSheetWithRows({'Sheet1': null});
  }

  /// Creates GridData from a list of rows
  static GridData gridDataFromRows(List<List<String>>? rows) {
    return GridData(
      rowData: rows
              ?.map((row) => RowData(
                    values: row
                        .map((cell) => CellData(formattedValue: cell))
                        .toList(),
                  ))
              .toList() ??
          [],
    );
  }
}

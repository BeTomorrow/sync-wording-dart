import 'package:googleapis/sheets/v4.dart';
import 'package:sync_wording/src/config/wording_config.dart';
import 'package:sync_wording/src/gsheets/spreadsheet/helper/spreadsheet_helper.dart';
import 'package:sync_wording/src/logger/logger.dart';
import 'package:sync_wording/src/wording/wording.dart';

class SpreadsheetRequestFactory {
  final Logger _logger;

  SpreadsheetRequestFactory(this._logger);

  Request? add(
    Spreadsheet spreadsheet,
    Iterable<String> keysToAdd,
    Wordings wordings,
    WordingConfig config,
  ) {
    if (keysToAdd.isEmpty) {
      return null;
    }

    for (final addedKey in keysToAdd) {
      _logger.log("[ADD   ] $addedKey", color: LogColor.green);
    }

    final sheet = spreadsheet.sheets!.firstWhere(
        (sheet) => config.isSheetNameValid(sheet.properties?.title));

    final addRequestRowIndex = sheet.data!
        .expand<RowData>((gridData) => gridData.rowData ?? [])
        .length;

    return Request(
      updateCells: UpdateCellsRequest(
        fields: '*',
        start: GridCoordinate(
          sheetId: sheet.properties!.sheetId!,
          rowIndex: addRequestRowIndex,
          columnIndex: 0,
        ),
        rows: keysToAdd
            .map((addedKey) => RowData(values: [
                  CellData(
                      userEnteredValue: ExtendedValue(stringValue: addedKey)),
                  for (final language in config.languages)
                    CellData(
                        userEnteredValue: ExtendedValue(
                            stringValue:
                                wordings[language.locale]![addedKey]!.value)),
                  CellData(
                      userEnteredValue: ExtendedValue(
                          stringValue: config.validation.expected))
                ]))
            .toList(),
      ),
    );
  }

  Request? update(
    Spreadsheet spreadsheet,
    String keyToUpdate,
    Wordings wordings,
    WordingConfig config,
  ) {
    final keyLocation = findKeyLocation(spreadsheet, keyToUpdate, config);

    if (keyLocation.sheetIndex != null && keyLocation.rowIndex != null) {
      final sheetId =
          spreadsheet.sheets![keyLocation.sheetIndex!].properties!.sheetId!;

      _logger.log("[UPDATE] $keyToUpdate", color: LogColor.orange);

      return Request(
        updateCells: UpdateCellsRequest(
          fields: '*',
          start: GridCoordinate(
            sheetId: sheetId,
            rowIndex: keyLocation.rowIndex!,
            columnIndex: 0,
          ),
          rows: [
            RowData(values: [
              CellData(
                  userEnteredValue: ExtendedValue(stringValue: keyToUpdate)),
              for (final language in config.languages)
                CellData(
                    userEnteredValue: ExtendedValue(
                        stringValue:
                            wordings[language.locale]![keyToUpdate]!.value)),
              CellData(
                  userEnteredValue:
                      ExtendedValue(stringValue: config.validation.expected))
            ])
          ],
        ),
      );
    }

    return null;
  }

  Request? delete(
    Spreadsheet spreadsheet,
    String keyToDelete,
    WordingConfig config,
  ) {
    final keyLocation = findKeyLocation(spreadsheet, keyToDelete, config);

    if (keyLocation.sheetIndex != null && keyLocation.rowIndex != null) {
      final sheetId =
          spreadsheet.sheets![keyLocation.sheetIndex!].properties!.sheetId!;

      _logger.log("[DELETE] $keyToDelete", color: LogColor.red);

      return Request(
          deleteDimension: DeleteDimensionRequest(
        range: DimensionRange(
          sheetId: sheetId,
          dimension: 'ROWS',
          startIndex: keyLocation.rowIndex!,
          endIndex: keyLocation.rowIndex! + 1,
        ),
      ));
    }

    return null;
  }
}

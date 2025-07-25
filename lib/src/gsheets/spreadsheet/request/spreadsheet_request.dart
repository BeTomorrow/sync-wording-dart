import 'dart:math';

import 'package:collection/collection.dart';
import 'package:googleapis/sheets/v4.dart';
import 'package:sync_wording/src/config/wording_config.dart';
import 'package:sync_wording/src/gsheets/spreadsheet/converter/cell_converter.dart';
import 'package:sync_wording/src/gsheets/spreadsheet/helper/spreadsheet_helper.dart';
import 'package:sync_wording/src/logger/logger.dart';
import 'package:sync_wording/src/wording/wording.dart';

class SpreadsheetRequestFactory {
  final Logger _logger;
  final CellConverter _converter = CellConverter();

  SpreadsheetRequestFactory(this._logger);

  Request? add(
    Spreadsheet spreadsheet,
    Iterable<String> keysToAdd,
    Wordings wordings,
    WordingConfig config,
  ) {
    if (keysToAdd.isEmpty) return null;

    final sheet = spreadsheet.firstValidSheet(config);
    if (sheet == null) return null;

    for (final addedKey in keysToAdd) {
      _logger.log("[ADD   ] $addedKey", color: LogColor.green);
    }

    final addRequestRowIndex = sheet.firstFreeRowIndex;

    return Request(
      updateCells: UpdateCellsRequest(
        fields: '*',
        start: GridCoordinate(
          sheetId: sheet.properties!.sheetId!,
          rowIndex: addRequestRowIndex,
          columnIndex: 0,
        ),
        rows: keysToAdd
            .map((addedKey) => _rowData(addedKey, wordings, config))
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
          rows: [_rowData(keyToUpdate, wordings, config)],
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

  RowData _rowData(
    String key,
    Wordings wordings,
    WordingConfig config,
  ) {
    final numberOfColumns = [
      ...config.languages.map((l) => l.column),
      config.keyColumn,
      config.validation.column ?? 0,
    ].reduce(max);

    final rowDataValues =
        List<CellData>.generate(numberOfColumns, (cellDataIndex) {
      if (cellDataIndex == config.keyColumn - 1) {
        return _cellData(key);
      }

      if (config.validation.column != null &&
          cellDataIndex == config.validation.column! - 1) {
        return _cellData(config.validation.expected ?? '');
      }

      final language = config.languages
          .firstWhereOrNull((l) => l.column == cellDataIndex + 1);
      if (language != null) {
        final entry = wordings[language.locale]?[key];
        if (entry != null) {
          return _cellData(_converter.fromWordingEntry(entry));
        }
      }

      return _cellData('');
    });

    return RowData(values: rowDataValues);
  }

  CellData _cellData(String value) =>
      CellData(userEnteredValue: ExtendedValue(stringValue: value));
}

import 'dart:io';

import 'package:googleapis/sheets/v4.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:sync_wording/src/config/wording_config.dart';
import 'package:sync_wording/src/gsheets/spreadsheet/converter/spreadsheet_extractor.dart';
import 'package:sync_wording/src/gsheets/spreadsheet/request/spreadsheet_request.dart';
import 'package:sync_wording/src/logger/logger.dart';
import 'package:sync_wording/src/wording/diff/wording_diff.dart';
import 'package:sync_wording/src/wording/wording.dart';

class XLSXDrive {
  final SheetsApi _sheetsApi;
  final SpreadsheetExtractor _converter = SpreadsheetExtractor();
  final Logger _logger;

  XLSXDrive(AutoRefreshingAuthClient client, Logger logger)
      : _sheetsApi = SheetsApi(client),
        _logger = logger;

  /// Retrieve the spreadsheet document
  Future<Spreadsheet> _getSpreadsheet(WordingConfig config) async {
    try {
      final spreadsheet = await _sheetsApi.spreadsheets
          .get(config.sheetId, includeGridData: true);
      return spreadsheet;
    } catch (e) {
      stderr.writeln("XLSXDrive error : $e");
      rethrow;
    }
  }

  /// Download the wordings from the spreadsheet
  Future<Wordings> downloadWordings(WordingConfig config) async {
    final spreadsheet = await _getSpreadsheet(config);
    return await _converter.toWordings(spreadsheet, config);
  }

  /// Upload the wordings to the spreadsheet
  Future<void> upload(WordingConfig config, Wordings wordings) async {
    final existingSpreadsheet = await _getSpreadsheet(config);
    final existingsWordings =
        await _converter.toWordings(existingSpreadsheet, config);

    // Detect differences between existing and new wordings
    final (addedKeys, modifiedKeys, removedKeys) =
        WordingDiff(existingsWordings, wordings).getDifferences();

    if (addedKeys.isEmpty && modifiedKeys.isEmpty && removedKeys.isEmpty) {
      _logger.log("No changes to upload", color: LogColor.blue);
      return;
    }

    final requests = <Request>[];
    final requestFactory = SpreadsheetRequestFactory(_logger);

    // First : add new keys
    final addRequest = requestFactory.add(
      existingSpreadsheet,
      addedKeys,
      wordings,
      config,
    );
    if (addRequest != null) {
      requests.add(addRequest);
    }

    // Second : update modified keys
    for (final modifiedKey in modifiedKeys) {
      final updateRequest = requestFactory.update(
        existingSpreadsheet,
        modifiedKey,
        wordings,
        config,
      );
      if (updateRequest != null) {
        requests.add(updateRequest);
      }
    }

    // Third : delete removed keys
    for (final removedKey in removedKeys) {
      final deleteRequest = requestFactory.delete(
        existingSpreadsheet,
        removedKey,
        config,
      );
      if (deleteRequest != null) {
        requests.add(deleteRequest);
      }
    }

    // Finally : execute the requests
    if (requests.isNotEmpty) {
      try {
        await _sheetsApi.spreadsheets.batchUpdate(
          BatchUpdateSpreadsheetRequest(requests: requests),
          config.sheetId,
        );
        _logger.log("✅ Wordings uploaded successfully");
      } catch (e) {
        _logger.log("❌ Wordings upload failed: $e");
      }
    }
  }
}

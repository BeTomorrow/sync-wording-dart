import 'dart:io';

import 'package:googleapis/sheets/v4.dart';
import 'package:googleapis_auth/auth_io.dart';

class XLSXDrive {
  final SheetsApi _sheetsApi;

  XLSXDrive(AutoRefreshingAuthClient client) : _sheetsApi = SheetsApi(client);

  /// Retrieve the spreadsheet document
  Future<Spreadsheet> getSpreadsheet(String spreadsheetId) async {
    try {
      final spreadsheet = await _sheetsApi.spreadsheets
          .get(spreadsheetId, includeGridData: true);
      return spreadsheet;
    } catch (e) {
      stderr.writeln("XLSXDrive error : $e");
      rethrow;
    }
  }
}

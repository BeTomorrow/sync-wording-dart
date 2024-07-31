import 'dart:io';

import 'package:googleapis_auth/auth_io.dart';
import 'package:gsheets/gsheets.dart';

class XLSXDrive {
  final GSheets _gsheets;

  XLSXDrive(AutoRefreshingAuthClient client)
      : _gsheets = GSheets.withClient(client);

  Future<Spreadsheet> getSpreadsheet(String spreadsheetId) async {
    try {
      final spreadsheet = await _gsheets.spreadsheet(spreadsheetId);
      return spreadsheet;
    } catch (e) {
      stderr.writeln("XLSXDrive error : $e");
      rethrow;
    }
  }
}

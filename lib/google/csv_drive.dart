import 'package:http/http.dart' as http;

class CSVDrive {
  final http.Client _client;

  CSVDrive(this._client);

  Future<String> readSpreadsheet(String spreadSheetId) async {
    final uri = _buildCSVSpreadsheetUrl(spreadSheetId);
    final request = await _client.get(uri);
    return request.body;
  }

  Uri _buildCSVSpreadsheetUrl(String spreadSheetId) {
    return Uri.parse("https://docs.google.com/spreadsheets/d/$spreadSheetId/gviz/tq?tqx=out:csv");
  }
}

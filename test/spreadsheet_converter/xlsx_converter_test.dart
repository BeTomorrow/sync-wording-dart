import 'package:googleapis/sheets/v4.dart';
import 'package:sync_wording/config/wording_config.dart';
import 'package:sync_wording/spreadsheet_converter/xlsx_converter/xlsx_converter.dart';
import 'package:test/test.dart';

void main() {
  group('XLSXConverter', () {
    late XLSXConverter converter;

    setUp(() {
      converter = XLSXConverter();
    });

    group('convert', () {
      test('should convert spreadsheet with multiple sheets', () async {
        final spreadsheet = SpreadsheetFixture.fromSheetWithRows({
          'Sheet1': [
            ['Key', 'English', 'French'],
            ['welcome', 'Hello', 'Bonjour'],
            ['goodbye', 'Goodbye', 'Au revoir'],
          ],
          'Sheet2': [
            ['Key', 'English', 'French'],
            ['thanks', 'Thank you', 'Merci'],
          ],
        });

        final result =
            await converter.convert(spreadsheet, testWordingConfig());

        expect(result.length, 2);
        expect(result['en']!.length, 3);
        expect(result['fr']!.length, 3);
        expect(result['en']!['welcome']!.value, 'Hello');
        expect(result['fr']!['welcome']!.value, 'Bonjour');
        expect(result['en']!['goodbye']!.value, 'Goodbye');
        expect(result['fr']!['goodbye']!.value, 'Au revoir');
        expect(result['en']!['thanks']!.value, 'Thank you');
        expect(result['fr']!['thanks']!.value, 'Merci');
      });

      test('should filter sheets by sheetNames when specified', () async {
        final configWithSheetNames = testWordingConfig(sheetNames: ['Sheet1']);

        final spreadsheet = SpreadsheetFixture.fromSheetWithRows({
          'Sheet1': [
            ['Key', 'English', 'French'],
            ['welcome', 'Hello', 'Bonjour'],
          ],
          'Sheet2': [
            ['Key', 'English', 'French'],
            ['ignored', 'Ignored', 'Ignoré'],
          ],
        });

        final result =
            await converter.convert(spreadsheet, configWithSheetNames);

        expect(result['en']!.length, 1);
        expect(result['en']!['welcome']!.value, 'Hello');
        expect(result['en']!.containsKey('ignored'), false);
      });

      test('should process all sheets when sheetNames is empty', () async {
        final configWithEmptySheetNames = testWordingConfig(sheetNames: []);

        final spreadsheet = SpreadsheetFixture.fromSheetWithRows({
          'Sheet1': [
            ['Key', 'English', 'French'],
            ['welcome', 'Hello', 'Bonjour'],
          ],
          'Sheet2': [
            ['Key', 'English', 'French'],
            ['goodbye', 'Goodbye', 'Au revoir'],
          ],
        });

        final result =
            await converter.convert(spreadsheet, configWithEmptySheetNames);

        expect(result['en']!.length, 2);
        expect(result['en']!['welcome']!.value, 'Hello');
        expect(result['en']!['goodbye']!.value, 'Goodbye');
      });

      test('should handle empty spreadsheet', () async {
        final spreadsheet = SpreadsheetFixture.fromSheetWithRows({});

        final result =
            await converter.convert(spreadsheet, testWordingConfig());

        expect(result.length, 2);
        expect(result['en']!.isEmpty, true);
        expect(result['fr']!.isEmpty, true);
      });

      test('should ignore rows not validated by Validator', () async {
        final configWithValidation = testWordingConfig(
          validation: ValidationConfig.withExpected(4, 'OK'),
        );

        final spreadsheet = SpreadsheetFixture.fromSheetWithRows({
          'TestSheet': [
            ['Key', 'English', 'French', 'Status'],
            ['welcome', 'Hello', 'Bonjour', 'OK'],
            ['goodbye', 'Goodbye', 'Au revoir', 'PENDING'],
            ['thanks', 'Thank you', 'Merci', 'OK'],
            ['invalid', 'Invalid', 'Invalide', 'ERROR'],
          ],
        });

        final result =
            await converter.convert(spreadsheet, configWithValidation);

        // Only rows with 'OK' in column 4 should be included
        expect(result['en']!.length, 2);
        expect(result['fr']!.length, 2);

        expect(result['en']!['welcome']!.value, 'Hello');
        expect(result['fr']!['welcome']!.value, 'Bonjour');
        expect(result['en']!['thanks']!.value, 'Thank you');
        expect(result['fr']!['thanks']!.value, 'Merci');

        // Invalid rows should be ignored
        expect(result['en']!.containsKey('goodbye'), false);
        expect(result['en']!.containsKey('invalid'), false);
        expect(result['fr']!.containsKey('goodbye'), false);
        expect(result['fr']!.containsKey('invalid'), false);
      });

      test('should include all rows when using ValidationConfig.always',
          () async {
        // Use ValidationConfig.always to accept all rows
        final configWithAlwaysValidation = testWordingConfig(
          validation: ValidationConfig.always(),
        );

        final spreadsheet = SpreadsheetFixture.fromSheetWithRows({
          'TestSheet': [
            ['Key', 'English', 'French', 'Status'],
            ['welcome', 'Hello', 'Bonjour', 'OK'],
            ['goodbye', 'Goodbye', 'Au revoir', 'PENDING'],
            ['thanks', 'Thank you', 'Merci', 'ERROR'],
          ],
        });

        final result =
            await converter.convert(spreadsheet, configWithAlwaysValidation);

        expect(result['en']!.length, 3);
        expect(result['fr']!.length, 3);
        expect(result['en']!['welcome']!.value, 'Hello');
        expect(result['en']!['goodbye']!.value, 'Goodbye');
        expect(result['en']!['thanks']!.value, 'Thank you');
        expect(result['fr']!['welcome']!.value, 'Bonjour');
        expect(result['fr']!['goodbye']!.value, 'Au revoir');
        expect(result['fr']!['thanks']!.value, 'Merci');
      });
    });

    group('worksheet conversion', () {
      test('should convert worksheet with valid data', () async {
        final spreadsheet = SpreadsheetFixture.fromSheetWithRows({
          'TestSheet': [
            ['Key', 'English', 'French'],
            ['welcome', 'Hello', 'Bonjour'],
            ['goodbye', 'Goodbye', 'Au revoir'],
          ],
        });

        final result =
            await converter.convert(spreadsheet, testWordingConfig());

        expect(result['en']!.length, 2);
        expect(result['fr']!.length, 2);
        expect(result['en']!['welcome']!.value, 'Hello');
        expect(result['fr']!['welcome']!.value, 'Bonjour');
      });

      test('should skip header row based on sheetStartIndex', () async {
        final configWithStartIndex = testWordingConfig(sheetStartIndex: 3);

        final spreadsheet = SpreadsheetFixture.fromSheetWithRows({
          'TestSheet': [
            ['Header1', 'Header2', 'Header3'],
            ['Key', 'English', 'French'],
            ['welcome', 'Hello', 'Bonjour'],
          ],
        });

        final result =
            await converter.convert(spreadsheet, configWithStartIndex);

        expect(result['en']!.length, 1);
        expect(result['en']!['welcome']!.value, 'Hello');
      });

      test('should handle worksheet with insufficient data', () async {
        final spreadsheet = SpreadsheetFixture.fromSheetWithRows({
          'TestSheet': [
            ['Key', 'English', 'French'],
          ],
        });

        final result =
            await converter.convert(spreadsheet, testWordingConfig());

        expect(result['en']!.isEmpty, true);
        expect(result['fr']!.isEmpty, true);
      });

      test('should handle worksheet with null data', () async {
        final spreadsheet = SpreadsheetFixture.fromSheetWithRows({
          'TestSheet': null,
        });

        final result =
            await converter.convert(spreadsheet, testWordingConfig());

        expect(result['en']!.isEmpty, true);
        expect(result['fr']!.isEmpty, true);
      });

      test('should handle worksheet with empty data', () async {
        final spreadsheet = SpreadsheetFixture.fromSheetWithRows({
          'TestSheet': [],
        });

        final result =
            await converter.convert(spreadsheet, testWordingConfig());

        expect(result['en']!.isEmpty, true);
        expect(result['fr']!.isEmpty, true);
      });
    });
  });
}

class SpreadsheetFixture {
  static Spreadsheet fromSheetWithRows(
      Map<String, List<List<String>>?> sheets) {
    return Spreadsheet(
      sheets: sheets.entries
          .map((sheet) => Sheet(
                properties: SheetProperties(title: sheet.key),
                data: [gridDataFromRows(sheet.value)],
              ))
          .toList(),
    );
  }

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

WordingConfig testWordingConfig({
  String? sheetId,
  List<String>? sheetNames,
  String? outputDir,
  int? sheetStartIndex,
  int? keyColumn,
  List<LanguageConfig>? languages,
  FallbackConfig? fallback,
  ValidationConfig? validation,
  GenL10nConfig? genL10n,
}) {
  return WordingConfig(
    CredentialsConfig('clientId', 'clientSecret', 'credentials.json'),
    sheetId ?? 'test-sheet-id',
    sheetNames ?? [],
    outputDir ?? 'outputs',
    sheetStartIndex ?? 2,
    keyColumn ?? 1,
    languages ?? [LanguageConfig('en', 2), LanguageConfig('fr', 3)],
    fallback ?? FallbackConfig.disabled(),
    validation ?? ValidationConfig.always(),
    genL10n ?? GenL10nConfig(false),
  );
}

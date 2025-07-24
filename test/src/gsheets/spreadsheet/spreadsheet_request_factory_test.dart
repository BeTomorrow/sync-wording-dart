import 'package:googleapis/sheets/v4.dart';
import 'package:sync_wording/src/config/wording_config.dart';
import 'package:sync_wording/src/gsheets/spreadsheet/request/spreadsheet_request.dart';
import 'package:sync_wording/src/wording/wording.dart';
import 'package:test/test.dart';

import '../../fixture_and_mocks/mock_logger.dart';
import '../../fixture_and_mocks/spreadsheet_fixture.dart';
import '../../fixture_and_mocks/wording_config_fixture.dart';

void main() {
  group('SpreadsheetRequestFactory', () {
    late SpreadsheetRequestFactory factory;
    late MockLogger mockLogger;
    late WordingConfig config;
    late Wordings wordings;
    late Spreadsheet spreadsheet;

    setUp(() {
      mockLogger = MockLogger();
      factory = SpreadsheetRequestFactory(mockLogger);

      config = WordingConfigFixture.forTest(
        sheetNames: ['Sheet1'],
        sheetStartIndex: 1,
        keyColumn: 1,
        languages: [LanguageConfig('en', 2), LanguageConfig('fr', 3)],
      );

      wordings = {
        'en': {
          'welcome': WordingEntry('Welcome', null),
          'goodbye': WordingEntry('Goodbye', null),
          'existing_key': WordingEntry('Welcome', null),
        },
        'fr': {
          'welcome': WordingEntry('Bienvenue', null),
          'goodbye': WordingEntry('Au revoir', null),
          'existing_key': WordingEntry('Bienvenue', null),
        },
      };

      // Use SpreadsheetFixture to create the spreadsheet
      spreadsheet = SpreadsheetFixture.simple([
        ['Key', 'English', 'French'],
        ['existing_key', 'Existing Value', 'Valeur Existante'],
      ]);
    });

    group('add', () {
      test('should return null when keysToAdd is empty', () {
        final result = factory.add(spreadsheet, [], wordings, config);
        expect(result, isNull);
      });

      test('should return null when no valid sheet found', () {
        final invalidConfig = WordingConfigFixture.forTest(
          sheetNames: ['InvalidSheet'],
          languages: [LanguageConfig('en', 2)],
        );

        final result =
            factory.add(spreadsheet, ['welcome'], wordings, invalidConfig);
        expect(result, isNull);
      });

      test('should create add request for valid keys', () {
        final result =
            factory.add(spreadsheet, ['welcome', 'goodbye'], wordings, config);

        expect(result, isNotNull);
        expect(result!.updateCells, isNotNull);

        expect(
          result.updateCells!.start!.rowIndex,
          equals(2), // After existing row
        );
        expect(result.updateCells!.start!.columnIndex, equals(0));
        expect(result.updateCells!.start!.sheetId, equals(0));

        expect(result.updateCells!.rows, hasLength(2));
        expect(
          result.updateCells!.rows![0].values![0].userEnteredValue!.stringValue,
          equals('welcome'),
        );
        expect(
          result.updateCells!.rows![1].values![0].userEnteredValue!.stringValue,
          equals('goodbye'),
        );
      });

      test('should create correct row data for added keys', () {
        final result = factory.add(spreadsheet, ['welcome'], wordings, config);
        final rowData = result!.updateCells!.rows!.first;

        expect(rowData.values, hasLength(3)); // key, en, fr columns
        expect(rowData.values![0].userEnteredValue!.stringValue,
            equals('welcome'));
        expect(rowData.values![1].userEnteredValue!.stringValue,
            equals('Welcome'));
        expect(rowData.values![2].userEnteredValue!.stringValue,
            equals('Bienvenue'));
      });
    });

    group('update', () {
      test('should return null when key not found', () {
        final result =
            factory.update(spreadsheet, 'non_existent_key', wordings, config);
        expect(result, isNull);
      });

      test('should create update request for existing key', () {
        final result =
            factory.update(spreadsheet, 'existing_key', wordings, config);

        expect(result, isNotNull);
        expect(result!.updateCells, isNotNull);
        expect(result.updateCells!.rows, hasLength(1));
        expect(
          result.updateCells!.start!.rowIndex,
          equals(1),
        ); // Row index of existing key
        expect(result.updateCells!.start!.columnIndex, equals(0));
        expect(result.updateCells!.start!.sheetId, equals(0));

        final rows = result.updateCells!.rows;
        expect(rows, isNotNull);
        expect(rows, hasLength(1));
        expect(rows![0].values![0].userEnteredValue!.stringValue,
            equals('existing_key'));
        expect(rows[0].values![1].userEnteredValue!.stringValue,
            equals('Welcome'));
        expect(rows[0].values![2].userEnteredValue!.stringValue,
            equals('Bienvenue'));
      });
    });

    group('delete', () {
      test('should return null when key not found', () {
        final result = factory.delete(spreadsheet, 'non_existent_key', config);
        expect(result, isNull);
      });

      test('should create delete request for existing key', () {
        final result = factory.delete(spreadsheet, 'existing_key', config);

        expect(result, isNotNull);
        expect(result!.deleteDimension, isNotNull);
        expect(result.deleteDimension!.range!.sheetId, equals(0));
        expect(result.deleteDimension!.range!.dimension, equals('ROWS'));
        expect(result.deleteDimension!.range!.startIndex, equals(1));
        expect(result.deleteDimension!.range!.endIndex, equals(2));

        // Verify logged message
        expect(mockLogger.messages, contains('[DELETE] existing_key'));
      });
    });

    group('row data creation', () {
      test('should handle validation column when configured', () {
        final configWithValidation = WordingConfigFixture.forTest(
          sheetNames: ['Sheet1'],
          sheetStartIndex: 1,
          keyColumn: 1,
          languages: [LanguageConfig('en', 2)],
          validation: ValidationConfig.withExpected(3, 'valid'),
        );

        // Create wordings with the test_key
        final testWordings = <String, LanguageWordings>{
          'en': {'test_key': WordingEntry('Welcome', null)},
          'fr': {'test_key': WordingEntry('Bienvenue', null)},
        };

        final result = factory.add(
            spreadsheet, ['test_key'], testWordings, configWithValidation);
        final rowData = result!.updateCells!.rows!.first;

        expect(rowData.values, hasLength(3)); // key, en, validation columns
        expect(
          rowData.values![0].userEnteredValue!.stringValue,
          equals('test_key'),
        );
        expect(
          rowData.values![1].userEnteredValue!.stringValue,
          equals('Welcome'),
        );
        expect(
          rowData.values![2].userEnteredValue!.stringValue,
          equals('valid'),
        );
      });

      test('should handle complex column configuration', () {
        // Create spreadsheet with 5 columns: Key, <nothing>, English, Validation, French
        final complexConfig = WordingConfigFixture.forTest(
          sheetNames: ['Sheet1'],
          sheetStartIndex: 1,
          keyColumn: 1,
          languages: [
            LanguageConfig('en', 3), // Skip column 2
            LanguageConfig('fr', 5), // Skip column 4
          ],
          validation: ValidationConfig.withExpected(4, 'valid'),
        );

        // Create wordings with the test_key
        final testWordings = <String, LanguageWordings>{
          'en': {'test_key': WordingEntry('Welcome', null)},
          'fr': {'test_key': WordingEntry('Bienvenue', null)},
        };

        final result =
            factory.add(spreadsheet, ['test_key'], testWordings, complexConfig);
        final rowData = result!.updateCells!.rows!.first;

        expect(
          rowData.values,
          hasLength(5), // key, <empty>, en, validation, fr columns
        );
        expect(rowData.values![0].userEnteredValue!.stringValue,
            equals('test_key'));
        expect(rowData.values![1].userEnteredValue!.stringValue, equals(''));
        expect(rowData.values![2].userEnteredValue!.stringValue,
            equals('Welcome'));
        expect(
            rowData.values![3].userEnteredValue!.stringValue, equals('valid'));
        expect(rowData.values![4].userEnteredValue!.stringValue,
            equals('Bienvenue'));
      });
    });

    group('edge cases', () {
      test('should handle spreadsheet with no data', () {
        final emptySpreadsheet = SpreadsheetFixture.withNoData();

        final result =
            factory.add(emptySpreadsheet, ['welcome'], wordings, config);
        expect(result, isNotNull);
        expect(result!.updateCells!.start!.rowIndex, equals(0));
      });

      test('should handle spreadsheet with null data', () {
        final nullDataSpreadsheet = SpreadsheetFixture.empty();

        final result =
            factory.add(nullDataSpreadsheet, ['welcome'], wordings, config);
        expect(result, isNotNull);
        expect(result!.updateCells!.start!.rowIndex, equals(0));
      });
    });
  });
}

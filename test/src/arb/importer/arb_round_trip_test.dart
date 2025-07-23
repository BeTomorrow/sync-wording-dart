import 'dart:io';

import 'package:sync_wording/src/arb/exporter/arb_wording_exporter.dart';
import 'package:sync_wording/src/arb/importer/arb_wording_importer.dart';
import 'package:sync_wording/src/wording/wording.dart';
import 'package:test/test.dart';

void main() {
  group('ARB Round Trip', () {
    late ARBWordingImporter importer;
    late ARBWordingExporter exporter;
    late Directory tempDir;

    setUp(() {
      importer = ARBWordingImporter();
      exporter = ARBWordingExporter();
      tempDir = Directory.systemTemp.createTempSync('arb_round_trip_test');
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('should maintain data integrity through import/export cycle',
        () async {
      final originalWordings = <String, LanguageWordings>{
        'en': {
          'welcome': WordingEntry(
            'Hello {user}',
            [PlaceholderCharac('user', 'String', null)],
          ),
          'today': WordingEntry(
            'It\'s {date}',
            [
              PlaceholderCharac(
                  'date', 'DateTime', 'dd/MM/yyyy:hh\'h\'mm\'m\'ss')
            ],
          ),
          'simple': WordingEntry('No placeholders', null),
        },
        'fr': {
          'welcome': WordingEntry(
            'Bonjour {user}',
            [PlaceholderCharac('user', 'String', null)],
          ),
          'today': WordingEntry(
            'C\'est {date}',
            [
              PlaceholderCharac(
                  'date', 'DateTime', 'dd/MM/yyyy:hh\'h\'mm\'m\'ss')
            ],
          ),
        },
      };

      final exportedFiles = <String, String>{};

      for (final locale in originalWordings.keys) {
        final outputFile = '${tempDir.path}/$locale.arb';
        await exporter.export(locale, originalWordings[locale]!, outputFile);
        exportedFiles[locale] = outputFile;
      }

      final importedWordings = await importer.import(exportedFiles);

      expect(importedWordings.length, equals(originalWordings.length));

      for (final locale in originalWordings.keys) {
        final original = originalWordings[locale]!;
        final imported = importedWordings[locale]!;

        expect(imported.length, equals(original.length));

        for (final key in original.keys) {
          final originalEntry = original[key]!;
          final importedEntry = imported[key]!;

          expect(importedEntry.value, equals(originalEntry.value));

          if (originalEntry.placeholderCharacs != null) {
            expect(importedEntry.placeholderCharacs, isNotNull);
            expect(importedEntry.placeholderCharacs!.length,
                equals(originalEntry.placeholderCharacs!.length));

            for (int i = 0; i < originalEntry.placeholderCharacs!.length; i++) {
              final originalCharac = originalEntry.placeholderCharacs![i];
              final importedCharac = importedEntry.placeholderCharacs![i];

              expect(importedCharac.placeholder,
                  equals(originalCharac.placeholder));
              expect(importedCharac.type, equals(originalCharac.type));
              expect(importedCharac.format, equals(originalCharac.format));
            }
          } else {
            expect(importedEntry.placeholderCharacs, isNull);
          }
        }
      }
    });
  });
}

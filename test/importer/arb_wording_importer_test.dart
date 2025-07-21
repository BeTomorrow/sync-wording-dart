import 'dart:io';

import 'package:sync_wording/importer/arb/arb_wording_importer.dart';
import 'package:sync_wording/wording.dart';
import 'package:test/test.dart';

void main() {
  group('ARBWordingImporter', () {
    late ARBWordingImporter importer;
    late Directory tempDir;

    setUp(() {
      importer = ARBWordingImporter();
      tempDir = Directory.systemTemp.createTempSync('arb_test');
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    Future<String> createArbFile(String filename, String content) async {
      final file = File('${tempDir.path}/$filename');
      await file.writeAsString(content);
      return file.path;
    }

    test('should import ARB file with placeholders', () async {
      final arbContent = '''
{
  "@@locale": "en",
  "welcome": "Hello {user}",
  "@welcome": {
    "placeholders": {
      "user": {
        "type": "String"
      }
    }
  },
  "today": "It's {date}",
  "@today": {
    "placeholders": {
      "date": {
        "type": "DateTime",
        "format": "dd/MM/yyyy:hh'h'mm'm'ss",
        "isCustomDateFormat": "true"
      }
    }
  },
  "simple": "No placeholders"
}
''';

      final filePath = await createArbFile('en.arb', arbContent);
      final result = await importer.import({'en': filePath});

      expect(result, isA<Map<String, LanguageWordings>>());
      expect(result['en'], isNotNull);

      final enWordings = result['en']!;
      expect(enWordings.length, equals(3));

      final welcomeEntry = enWordings['welcome']!;
      expect(welcomeEntry.value, equals('Hello {user}'));
      expect(welcomeEntry.placeholderCharacs, isNotNull);
      expect(welcomeEntry.placeholderCharacs!.length, equals(1));
      expect(welcomeEntry.placeholderCharacs![0].placeholder, equals('user'));
      expect(welcomeEntry.placeholderCharacs![0].type, equals('String'));
      expect(welcomeEntry.placeholderCharacs![0].format, isNull);

      final todayEntry = enWordings['today']!;
      expect(todayEntry.value, equals('It\'s {date}'));
      expect(todayEntry.placeholderCharacs, isNotNull);
      expect(todayEntry.placeholderCharacs!.length, equals(1));
      expect(todayEntry.placeholderCharacs![0].placeholder, equals('date'));
      expect(todayEntry.placeholderCharacs![0].type, equals('DateTime'));
      expect(todayEntry.placeholderCharacs![0].format,
          equals('dd/MM/yyyy:hh\'h\'mm\'m\'ss'));

      final simpleEntry = enWordings['simple']!;
      expect(simpleEntry.value, equals('No placeholders'));
      expect(simpleEntry.placeholderCharacs, isNull);
    });

    test('should handle multiple locales', () async {
      final enArb = '''
{
  "@@locale": "en",
  "hello": "Hello {name}",
  "@hello": {
    "placeholders": {
      "name": {
        "type": "String"
      }
    }
  }
}
''';

      final frArb = '''
{
  "@@locale": "fr",
  "hello": "Bonjour {name}",
  "@hello": {
    "placeholders": {
      "name": {
        "type": "String"
      }
    }
  }
}
''';

      final enPath = await createArbFile('en.arb', enArb);
      final frPath = await createArbFile('fr.arb', frArb);

      final result = await importer.import({
        'en': enPath,
        'fr': frPath,
      });

      expect(result.length, equals(2));
      expect(result['en'], isNotNull);
      expect(result['fr'], isNotNull);

      expect(result['en']!['hello']!.value, equals('Hello {name}'));
      expect(result['fr']!['hello']!.value, equals('Bonjour {name}'));
    });

    test('should handle non-existent files with empty wordings', () async {
      final result = await importer.import({'en': '/non/existent/file.arb'});

      expect(result['en'], isNotNull);
      expect(result['en']!.isEmpty, isTrue);
    });

    test('should handle mix of existing and non-existent files', () async {
      final enArb = '''
{
  "@@locale": "en",
  "hello": "Hello {name}",
  "@hello": {
    "placeholders": {
      "name": {
        "type": "String"
      }
    }
  }
}
''';

      final enPath = await createArbFile('en.arb', enArb);

      final result = await importer.import({
        'en': enPath,
        'fr': '/non/existent/fr.arb',
        'de': '/non/existent/de.arb',
      });

      expect(result.length, equals(3));
      expect(result['en'], isNotNull);
      expect(result['fr'], isNotNull);
      expect(result['de'], isNotNull);

      expect(result['en']!.length, equals(1));
      expect(result['en']!['hello']!.value, equals('Hello {name}'));

      expect(result['fr']!.isEmpty, isTrue);
      expect(result['de']!.isEmpty, isTrue);
    });
  });
}

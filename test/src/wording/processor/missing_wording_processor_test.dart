import 'package:sync_wording/src/config/wording_config.dart';
import 'package:sync_wording/src/wording/processor/missing_wording_processor.dart';
import 'package:sync_wording/src/wording/wording.dart';
import 'package:test/test.dart';

import '../../mocks/mock_logger.dart';

void main() {
  group('MissingWordingProcessor', () {
    late MockLogger mockLogger;
    late MissingWordingProcessor processor;

    setUp(() {
      mockLogger = MockLogger();
      processor =
          MissingWordingProcessor(mockLogger, FallbackConfig.disabled());
    });

    test('should detect missing wording entries', () {
      final wordings = <String, LanguageWordings>{
        'en': {
          'key1': WordingEntry('Hello', null),
          'key2': WordingEntry('', null), // Empty value
          'key3': WordingEntry('World', null),
        },
        'fr': {
          'key1': WordingEntry('Bonjour', null),
          'key2': WordingEntry('', null), // Empty value
          'key3': WordingEntry('Monde', null),
        },
      };

      processor.process(wordings);

      expect(mockLogger.messages.length, 2);
      expect(mockLogger.messages[0],
          contains("⚠️ Missing wording for 'key2' in 'en'"));
      expect(mockLogger.messages[1],
          contains("⚠️ Missing wording for 'key2' in 'fr'"));
    });

    test('should detect null wording entries', () {
      final wordings = <String, LanguageWordings>{
        'en': {
          'key1': WordingEntry('Hello', null),
          'key2': WordingEntry('World', null),
        },
        'fr': {
          'key1': WordingEntry('Bonjour', null),
          // key2 is missing in French
        },
      };

      processor.process(wordings);

      expect(mockLogger.messages.length, 0); // No missing entries in this case
    });

    test('should handle empty wordings', () {
      final wordings = <String, LanguageWordings>{};

      processor.process(wordings);

      expect(mockLogger.messages.length, 0);
    });

    test('should handle wordings with only empty values', () {
      final wordings = <String, LanguageWordings>{
        'en': {
          'key1': WordingEntry('', null),
          'key2': WordingEntry('', null),
        },
        'fr': {
          'key1': WordingEntry('', null),
          'key2': WordingEntry('', null),
        },
      };

      processor.process(wordings);

      expect(mockLogger.messages.length, 4);
      expect(mockLogger.messages[0],
          contains("⚠️ Missing wording for 'key1' in 'en'"));
      expect(mockLogger.messages[1],
          contains("⚠️ Missing wording for 'key2' in 'en'"));
      expect(mockLogger.messages[2],
          contains("⚠️ Missing wording for 'key1' in 'fr'"));
      expect(mockLogger.messages[3],
          contains("⚠️ Missing wording for 'key2' in 'fr'"));
    });

    test('should not report valid wordings', () {
      final wordings = <String, LanguageWordings>{
        'en': {
          'key1': WordingEntry('Hello', null),
          'key2': WordingEntry('World', null),
        },
        'fr': {
          'key1': WordingEntry('Bonjour', null),
          'key2': WordingEntry('Monde', null),
        },
      };

      processor.process(wordings);

      expect(mockLogger.messages.length, 0);
    });
  });

  group('MissingWordingProcessor with fallback', () {
    late MockLogger mockLogger;
    late MissingWordingProcessor processor;

    setUp(() {
      mockLogger = MockLogger();
      processor =
          MissingWordingProcessor(mockLogger, FallbackConfig.enabled('en'));
    });

    test('should apply fallback translations when missing', () {
      final wordings = <String, LanguageWordings>{
        'en': {
          'key1': WordingEntry('Hello', null),
          'key2': WordingEntry('World', null),
        },
        'fr': {
          'key1': WordingEntry('Bonjour', null),
          'key2': WordingEntry('', null), // Missing in French
        },
      };

      processor.process(wordings);

      expect(mockLogger.messages.length, 1);
      expect(
          mockLogger.messages[0],
          contains(
              "ℹ️ Applied fallback translation for 'key2' in 'fr' from 'en'"));

      // Verify that the fallback was actually applied
      expect(wordings['fr']!['key2']!.value, equals('World'));
    });

    test('should warn when both languages are missing', () {
      final wordings = <String, LanguageWordings>{
        'en': {
          'key1': WordingEntry('Hello', null),
          'key2': WordingEntry('', null), // Missing in English too
        },
        'fr': {
          'key1': WordingEntry('Bonjour', null),
          'key2': WordingEntry('', null), // Missing in French
        },
      };

      processor.process(wordings);

      expect(mockLogger.messages.length, 1);
      expect(mockLogger.messages[0],
          contains("⚠️ Missing wording for 'key2' in 'fr' and 'en'"));
    });

    test('should warn when default language is not found', () {
      final wordings = <String, LanguageWordings>{
        'fr': {
          'key1': WordingEntry('Bonjour', null),
        },
        'es': {
          'key1': WordingEntry('Hola', null),
        },
      };

      processor.process(wordings);

      expect(mockLogger.messages.length, 1);
      expect(mockLogger.messages[0],
          contains("⚠️ Default language 'en' not found in wordings"));
    });

    test('should not apply fallback to default language', () {
      final wordings = <String, LanguageWordings>{
        'en': {
          'key1': WordingEntry('Hello', null),
          'key2': WordingEntry('', null), // Missing in English
        },
        'fr': {
          'key1': WordingEntry('Bonjour', null),
          'key2': WordingEntry('Monde', null),
        },
      };

      processor.process(wordings);

      // Should not apply fallback from French to English
      expect(mockLogger.messages.length, 0);
      expect(wordings['en']!['key2']!.value, equals(''));
    });
  });
}

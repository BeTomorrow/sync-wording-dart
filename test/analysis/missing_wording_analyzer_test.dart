import 'package:sync_wording/analysis/missing_wording_analyzer.dart';
import 'package:sync_wording/logger/logger.dart';
import 'package:sync_wording/wording.dart';
import 'package:test/test.dart';

class MockLogger implements Logger {
  final List<String> messages = [];

  @override
  void log(String message) {
    messages.add(message);
  }
}

void main() {
  group('MissingWordingAnalyzer', () {
    late MockLogger mockLogger;
    late MissingWordingAnalyzer analyzer;

    setUp(() {
      mockLogger = MockLogger();
      analyzer = MissingWordingAnalyzer(mockLogger);
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

      analyzer.analyze(wordings);

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

      analyzer.analyze(wordings);

      expect(mockLogger.messages.length, 0); // No missing entries in this case
    });

    test('should handle empty wordings', () {
      final wordings = <String, LanguageWordings>{};

      analyzer.analyze(wordings);

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

      analyzer.analyze(wordings);

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

      analyzer.analyze(wordings);

      expect(mockLogger.messages.length, 0);
    });
  });
}

import 'package:sync_wording/analysis/placeholder_mismatch_analyzer.dart';
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
  group('PlaceholderMismatchAnalyzer', () {
    late MockLogger mockLogger;
    late PlaceholderMismatchAnalyzer analyzer;

    setUp(() {
      mockLogger = MockLogger();
      analyzer = PlaceholderMismatchAnalyzer(mockLogger);
    });

    test('should not analyze with less than 2 languages', () {
      final wordings = <String, LanguageWordings>{
        'en': {
          'key1': WordingEntry('Hello {user}', [
            PlaceholderCharac('user', null, null),
          ]),
        },
      };

      analyzer.analyze(wordings);

      expect(mockLogger.messages.length, 0);
    });

    test('should detect placeholder count mismatch', () {
      final wordings = <String, LanguageWordings>{
        'en': {
          'key1': WordingEntry('Hello {user} {name}', [
            PlaceholderCharac('user', null, null),
            PlaceholderCharac('name', null, null),
          ]),
        },
        'fr': {
          'key1': WordingEntry('Bonjour {user}', [
            PlaceholderCharac('user', null, null),
          ]),
        },
      };

      analyzer.analyze(wordings);

      expect(mockLogger.messages.length, 1);
      expect(mockLogger.messages[0],
          contains("⚠️ Placeholder mismatch for 'key1'"));
    });

    test('should detect placeholder name mismatch', () {
      final wordings = <String, LanguageWordings>{
        'en': {
          'key1': WordingEntry('Hello {user}', [
            PlaceholderCharac('user', null, null),
          ]),
        },
        'fr': {
          'key1': WordingEntry('Bonjour {utilisateur}', [
            PlaceholderCharac('utilisateur', null, null),
          ]),
        },
      };

      analyzer.analyze(wordings);

      expect(mockLogger.messages.length, 1);
      expect(mockLogger.messages[0],
          contains("⚠️ Placeholder mismatch for 'key1'"));
    });

    test('should detect placeholder type mismatch', () {
      final wordings = <String, LanguageWordings>{
        'en': {
          'key1': WordingEntry('Hello {user|String}', [
            PlaceholderCharac('user', 'String', null),
          ]),
        },
        'fr': {
          'key1': WordingEntry('Bonjour {user|int}', [
            PlaceholderCharac('user', 'int', null),
          ]),
        },
      };

      analyzer.analyze(wordings);

      expect(mockLogger.messages.length, 1);
      expect(mockLogger.messages[0],
          contains("⚠️ Placeholder mismatch for 'key1'"));
    });

    test('should not detect placeholder format mismatch', () {
      final wordings = <String, LanguageWordings>{
        'en': {
          'key1': WordingEntry('Date: {date|DateTime|dd/MM/yyyy}', [
            PlaceholderCharac('date', 'DateTime', 'dd/MM/yyyy'),
          ]),
        },
        'fr': {
          'key1': WordingEntry('Date: {date|DateTime|MM/dd/yyyy}', [
            PlaceholderCharac('date', 'DateTime', 'MM/dd/yyyy'),
          ]),
        },
      };

      analyzer.analyze(wordings);

      expect(mockLogger.messages.length, 0);
    });

    test('should handle simple placeholders without type', () {
      final wordings = <String, LanguageWordings>{
        'en': {
          'key1': WordingEntry('Hello {user}', [
            PlaceholderCharac('user', null, null),
          ]),
        },
        'fr': {
          'key1': WordingEntry('Bonjour {user}', [
            PlaceholderCharac('user', null, null),
          ]),
        },
      };

      analyzer.analyze(wordings);

      expect(mockLogger.messages.length, 0);
    });

    test('should handle typed placeholders correctly', () {
      final wordings = <String, LanguageWordings>{
        'en': {
          'key1': WordingEntry('Hello {user|String}', [
            PlaceholderCharac('user', 'String', null),
          ]),
        },
        'fr': {
          'key1': WordingEntry('Bonjour {user|String}', [
            PlaceholderCharac('user', 'String', null),
          ]),
        },
      };

      analyzer.analyze(wordings);

      expect(mockLogger.messages.length, 0);
    });

    test('should handle mixed simple and typed placeholders', () {
      final wordings = <String, LanguageWordings>{
        'en': {
          'key1': WordingEntry('Hello {user}, you have {count|int} messages', [
            PlaceholderCharac('user', null, null),
            PlaceholderCharac('count', 'int', null),
          ]),
        },
        'fr': {
          'key1':
              WordingEntry('Bonjour {user}, vous avez {count|int} messages', [
            PlaceholderCharac('user', null, null),
            PlaceholderCharac('count', 'int', null),
          ]),
        },
      };

      analyzer.analyze(wordings);

      expect(mockLogger.messages.length, 0);
    });

    test('should handle entries without placeholders', () {
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

    test('should handle missing keys in some languages', () {
      final wordings = <String, LanguageWordings>{
        'en': {
          'key1': WordingEntry('Hello {user}', [
            PlaceholderCharac('user', null, null),
          ]),
          'key2': WordingEntry('World', null),
        },
        'fr': {
          'key1': WordingEntry('Bonjour {user}', [
            PlaceholderCharac('user', null, null),
          ]),
          // key2 is missing in French
        },
      };

      analyzer.analyze(wordings);

      expect(mockLogger.messages.length, 0); // Should not report missing keys
    });

    test('should handle empty wordings', () {
      final wordings = <String, LanguageWordings>{};

      analyzer.analyze(wordings);

      expect(mockLogger.messages.length, 0);
    });
  });
}

import 'package:sync_wording/wording.dart';
import 'package:sync_wording/wording_diff/wording_diff.dart';
import 'package:test/test.dart';

void main() {
  group('WordingDiff', () {
    test('should detect added keys', () {
      final oldWordings = <String, LanguageWordings>{
        'en': {
          'hello': WordingEntry('Hello', null),
        },
      };

      final newWordings = <String, LanguageWordings>{
        'en': {
          'hello': WordingEntry('Hello', null),
          'welcome': WordingEntry('Welcome', null),
          'goodbye': WordingEntry('Goodbye', null),
        },
      };

      final diff = WordingDiff(oldWordings, newWordings);
      final (addedKeys, modifiedKeys, removedKeys) = diff.diff();

      expect(addedKeys, equals({'welcome', 'goodbye'}));
      expect(modifiedKeys, isEmpty);
      expect(removedKeys, isEmpty);
    });

    test('should detect removed keys', () {
      final oldWordings = <String, LanguageWordings>{
        'en': {
          'hello': WordingEntry('Hello', null),
          'welcome': WordingEntry('Welcome', null),
          'goodbye': WordingEntry('Goodbye', null),
        },
      };

      final newWordings = <String, LanguageWordings>{
        'en': {
          'hello': WordingEntry('Hello', null),
        },
      };

      final diff = WordingDiff(oldWordings, newWordings);
      final (addedKeys, modifiedKeys, removedKeys) = diff.diff();

      expect(addedKeys, isEmpty);
      expect(modifiedKeys, isEmpty);
      expect(removedKeys, equals({'welcome', 'goodbye'}));
    });

    test('should detect modified keys', () {
      final oldWordings = <String, LanguageWordings>{
        'en': {
          'hello': WordingEntry('Hello', null),
          'welcome': WordingEntry('Welcome', null),
        },
      };

      final newWordings = <String, LanguageWordings>{
        'en': {
          'hello': WordingEntry('Hello there', null),
          'welcome': WordingEntry('Welcome', null),
        },
      };

      final diff = WordingDiff(oldWordings, newWordings);
      final (addedKeys, modifiedKeys, removedKeys) = diff.diff();

      expect(addedKeys, isEmpty);
      expect(modifiedKeys, equals({'hello'}));
      expect(removedKeys, isEmpty);
    });

    test('should detect modified placeholders', () {
      final oldWordings = <String, LanguageWordings>{
        'en': {
          'welcome': WordingEntry(
            'Hello {user}',
            [PlaceholderCharac('user', 'String', null)],
          ),
        },
      };

      final newWordings = <String, LanguageWordings>{
        'en': {
          'welcome': WordingEntry(
            'Hello {user}',
            [PlaceholderCharac('user', 'String', 'uppercase')],
          ),
        },
      };

      final diff = WordingDiff(oldWordings, newWordings);
      final (addedKeys, modifiedKeys, removedKeys) = diff.diff();

      expect(addedKeys, isEmpty);
      expect(modifiedKeys, equals({'welcome'}));
      expect(removedKeys, isEmpty);
    });

    test('should detect no changes', () {
      final oldWordings = <String, LanguageWordings>{
        'en': {
          'hello': WordingEntry('Hello', null),
          'welcome': WordingEntry('Welcome', null),
        },
      };

      final newWordings = <String, LanguageWordings>{
        'en': {
          'hello': WordingEntry('Hello', null),
          'welcome': WordingEntry('Welcome', null),
        },
      };

      final diff = WordingDiff(oldWordings, newWordings);
      final (addedKeys, modifiedKeys, removedKeys) = diff.diff();

      expect(addedKeys, isEmpty);
      expect(modifiedKeys, isEmpty);
      expect(removedKeys, isEmpty);
    });

    test('should handle multiple locales', () {
      final oldWordings = <String, LanguageWordings>{
        'en': {
          'hello': WordingEntry('Hello', null),
        },
        'fr': {
          'hello': WordingEntry('Bonjour', null),
        },
      };

      final newWordings = <String, LanguageWordings>{
        'en': {
          'hello': WordingEntry('Hello', null),
          'welcome': WordingEntry('Welcome', null),
        },
        'fr': {
          'hello': WordingEntry('Bonjour', null),
          'welcome': WordingEntry('Bienvenue', null),
        },
      };

      final diff = WordingDiff(oldWordings, newWordings);
      final (addedKeys, modifiedKeys, removedKeys) = diff.diff();

      expect(addedKeys, equals({'welcome'}));
      expect(modifiedKeys, isEmpty);
      expect(removedKeys, isEmpty);
    });

    test('should handle locale changes', () {
      final oldWordings = <String, LanguageWordings>{
        'en': {
          'hello': WordingEntry('Hello', null),
        },
      };

      final newWordings = <String, LanguageWordings>{
        'fr': {
          'hello': WordingEntry('Bonjour', null),
        },
      };

      final diff = WordingDiff(oldWordings, newWordings);
      final (addedKeys, modifiedKeys, removedKeys) = diff.diff();

      expect(addedKeys, isEmpty);
      expect(modifiedKeys, isEmpty);
      expect(removedKeys, isEmpty);
    });

    test('should handle mixed changes', () {
      final oldWordings = <String, LanguageWordings>{
        'en': {
          'hello': WordingEntry('Hello', null),
          'welcome': WordingEntry('Welcome', null),
          'goodbye': WordingEntry('Goodbye', null),
        },
      };

      final newWordings = <String, LanguageWordings>{
        'en': {
          'hello': WordingEntry('Hello there', null), // Modified
          'welcome': WordingEntry('Welcome', null), // Unchanged
          'thanks': WordingEntry('Thank you', null), // Added
          // 'goodbye' removed
        },
      };

      final diff = WordingDiff(oldWordings, newWordings);
      final (addedKeys, modifiedKeys, removedKeys) = diff.diff();

      expect(addedKeys, equals({'thanks'}));
      expect(modifiedKeys, equals({'hello'}));
      expect(removedKeys, equals({'goodbye'}));
    });

    test('should handle placeholder changes', () {
      final oldWordings = <String, LanguageWordings>{
        'en': {
          'welcome': WordingEntry(
            'Hello {user}',
            [PlaceholderCharac('user', 'String', null)],
          ),
          'date': WordingEntry(
            'Today is {date}',
            [PlaceholderCharac('date', 'DateTime', 'dd/MM/yyyy')],
          ),
        },
      };

      final newWordings = <String, LanguageWordings>{
        'en': {
          'welcome': WordingEntry(
            'Hello {user}',
            [
              PlaceholderCharac('user', 'String', 'uppercase')
            ], // Modified format
          ),
          'date': WordingEntry(
            'Today is {date}',
            [PlaceholderCharac('date', 'DateTime', 'dd/MM/yyyy')], // Unchanged
          ),
        },
      };

      final diff = WordingDiff(oldWordings, newWordings);
      final (addedKeys, modifiedKeys, removedKeys) = diff.diff();

      expect(addedKeys, isEmpty);
      expect(modifiedKeys, equals({'welcome'}));
      expect(removedKeys, isEmpty);
    });
  });
}

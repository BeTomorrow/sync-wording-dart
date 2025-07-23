import 'package:sync_wording/src/gsheets/spreadsheet_converter/wording_parser.dart';
import 'package:sync_wording/src/wording/wording.dart';
import 'package:test/test.dart';

void main() {
  group("WordingParser", () {
    /// VALID CASES

    test("no placeholder", () {
      final parser = WordingParser();

      final WordingEntry result = parser.parse("Hello everybody");

      expect(result.value, "Hello everybody");
      expect(result.placeholderCharacs, null);
    });

    test("simple placeholder", () {
      final parser = WordingParser();

      final WordingEntry result = parser.parse("Hello {user}");

      expect(result.value, "Hello {user}");
      expect(result.placeholderCharacs, isNotNull);
      expect(result.placeholderCharacs!.length, 1);
      expect(result.placeholderCharacs![0].placeholder, "user");
      expect(result.placeholderCharacs![0].type, null);
      expect(result.placeholderCharacs![0].format, null);
    });

    test("type placeholder", () {
      final parser = WordingParser();

      final WordingEntry result = parser.parse("Hello {user|String}");

      expect(result.value, "Hello {user}");
      expect(result.placeholderCharacs, isNotNull);
      expect(result.placeholderCharacs!.length, 1);
      expect(result.placeholderCharacs![0].placeholder, "user");
      expect(result.placeholderCharacs![0].type, "String");
      expect(result.placeholderCharacs![0].format, null);
    });

    test("type alphanumeric placeholder", () {
      final parser = WordingParser();

      final WordingEntry result = parser.parse("Hello {user1|String}");

      expect(result.value, "Hello {user1}");
      expect(result.placeholderCharacs, isNotNull);
      expect(result.placeholderCharacs!.length, 1);
      expect(result.placeholderCharacs![0].placeholder, "user1");
      expect(result.placeholderCharacs![0].type, "String");
      expect(result.placeholderCharacs![0].format, null);
    });

    test("type and format placeholder", () {
      final parser = WordingParser();

      final WordingEntry result =
          parser.parse("It's {date|DateTime|dd/MM/yyyy:hh'h'mm'm'ss}");

      expect(result.value, "It's {date}");
      expect(result.placeholderCharacs, isNotNull);
      expect(result.placeholderCharacs!.length, 1);
      expect(result.placeholderCharacs![0].placeholder, "date");
      expect(result.placeholderCharacs![0].type, "DateTime");
      expect(result.placeholderCharacs![0].format, "dd/MM/yyyy:hh'h'mm'm'ss");
    });

    test("pipes allowed in format", () {
      final parser = WordingParser();

      final WordingEntry result =
          parser.parse("It's {date|DateTime|dd/MM/yyyy hh|mm|ss}");

      expect(result.value, "It's {date}");
      expect(result.placeholderCharacs, isNotNull);
      expect(result.placeholderCharacs!.length, 1);
      expect(result.placeholderCharacs![0].placeholder, "date");
      expect(result.placeholderCharacs![0].type, "DateTime");
      expect(result.placeholderCharacs![0].format, "dd/MM/yyyy hh|mm|ss");
    });

    test("multiple placeholders", () {
      final parser = WordingParser();

      final WordingEntry result = parser.parse(
          "Hello {user}. It's {meteo|String} at {date|DateTime|dd/MM/yyyy : hh'h'mm'm'ss}");

      expect(result.value, "Hello {user}. It's {meteo} at {date}");
      expect(result.placeholderCharacs, isNotNull);
      expect(result.placeholderCharacs!.length, 3);
      expect(result.placeholderCharacs![0].placeholder, "user");
      expect(result.placeholderCharacs![0].type, null);
      expect(result.placeholderCharacs![0].format, null);
      expect(result.placeholderCharacs![1].placeholder, "meteo");
      expect(result.placeholderCharacs![1].type, "String");
      expect(result.placeholderCharacs![1].format, null);
      expect(result.placeholderCharacs![2].placeholder, "date");
      expect(result.placeholderCharacs![2].type, "DateTime");
      expect(result.placeholderCharacs![2].format, "dd/MM/yyyy : hh'h'mm'm'ss");
    });

    test("simple plural", () {
      final parser = WordingParser();

      final WordingEntry result =
          parser.parse("{days, plural, zero{} one{1 day} other{many days}}");

      expect(
          result.value, "{days, plural, zero{} one{1 day} other{many days}}");
      expect(result.placeholderCharacs, null);
    });

    test("placeholder in plural", () {
      final parser = WordingParser();

      final WordingEntry result = parser
          .parse("{days, plural, zero{} one{1 day} other{{days|int} days}}");

      expect(
          result.value, "{days, plural, zero{} one{1 day} other{{days} days}}");
      expect(result.placeholderCharacs, isNotNull);
      expect(result.placeholderCharacs!.length, 1);
      expect(result.placeholderCharacs![0].placeholder, "days");
      expect(result.placeholderCharacs![0].type, "int");
      expect(result.placeholderCharacs![0].format, null);
    });

    /// INVALID CASES

    test("placeholder with space", () {
      final parser = WordingParser();

      final WordingEntry result = parser.parse("Hello {us er}");

      expect(result.value, "Hello {us er}");
      expect(result.placeholderCharacs, null);
    });

    test("no placeholder", () {
      final parser = WordingParser();

      final WordingEntry result = parser.parse("Hello {|int}");

      expect(result.value, "Hello {|int}");
      expect(result.placeholderCharacs, null);
    });

    test("no type info", () {
      final parser = WordingParser();

      final WordingEntry result = parser.parse("Hello {user|}");

      expect(result.value, "Hello {user|}");
      expect(result.placeholderCharacs, null);
    });

    test("type info with space", () {
      final parser = WordingParser();

      final WordingEntry result = parser.parse("Hello {user|Str ing}");

      expect(result.value, "Hello {user|Str ing}");
      expect(result.placeholderCharacs, null);
    });

    test("no format info", () {
      final parser = WordingParser();

      final WordingEntry result = parser.parse("Hello {user|String|}");

      expect(result.value, "Hello {user|String|}");
      expect(result.placeholderCharacs, null);
    });

    test("no type and no format info", () {
      final parser = WordingParser();

      final WordingEntry result = parser.parse("Hello {user||}");

      expect(result.value, "Hello {user||}");
      expect(result.placeholderCharacs, null);
    });
  });
}

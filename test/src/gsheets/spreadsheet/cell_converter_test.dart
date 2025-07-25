import 'package:sync_wording/src/gsheets/spreadsheet/converter/cell_converter.dart';
import 'package:sync_wording/src/wording/wording.dart';
import 'package:test/test.dart';

void main() {
  final converter = CellConverter();

  group("CellConverter", () {
    test("toWordingEntry: no placeholder", () {
      final WordingEntry result = converter.toWordingEntry("Hello everybody");

      expect(result.value, "Hello everybody");
      expect(result.placeholderCharacs, null);
    });

    test("toWordingEntry: simple placeholder", () {
      final WordingEntry result = converter.toWordingEntry("Hello {user}");

      expect(result.value, "Hello {user}");
      expect(result.placeholderCharacs, isNotNull);
      expect(result.placeholderCharacs!.length, 1);
      expect(result.placeholderCharacs![0].placeholder, "user");
      expect(result.placeholderCharacs![0].type, null);
      expect(result.placeholderCharacs![0].format, null);
    });

    test("toWordingEntry: type placeholder", () {
      final WordingEntry result =
          converter.toWordingEntry("Hello {user|String}");

      expect(result.value, "Hello {user}");
      expect(result.placeholderCharacs, isNotNull);
      expect(result.placeholderCharacs!.length, 1);
      expect(result.placeholderCharacs![0].placeholder, "user");
      expect(result.placeholderCharacs![0].type, "String");
      expect(result.placeholderCharacs![0].format, null);
    });

    test("toWordingEntry: type alphanumeric placeholder", () {
      final WordingEntry result =
          converter.toWordingEntry("Hello {user1|String}");

      expect(result.value, "Hello {user1}");
      expect(result.placeholderCharacs, isNotNull);
      expect(result.placeholderCharacs!.length, 1);
      expect(result.placeholderCharacs![0].placeholder, "user1");
      expect(result.placeholderCharacs![0].type, "String");
      expect(result.placeholderCharacs![0].format, null);
    });

    test("toWordingEntry: type and format placeholder", () {
      final WordingEntry result = converter
          .toWordingEntry("It's {date|DateTime|dd/MM/yyyy:hh'h'mm'm'ss}");

      expect(result.value, "It's {date}");
      expect(result.placeholderCharacs, isNotNull);
      expect(result.placeholderCharacs!.length, 1);
      expect(result.placeholderCharacs![0].placeholder, "date");
      expect(result.placeholderCharacs![0].type, "DateTime");
      expect(result.placeholderCharacs![0].format, "dd/MM/yyyy:hh'h'mm'm'ss");
    });

    test("toWordingEntry: pipes allowed in format", () {
      final WordingEntry result =
          converter.toWordingEntry("It's {date|DateTime|dd/MM/yyyy hh|mm|ss}");

      expect(result.value, "It's {date}");
      expect(result.placeholderCharacs, isNotNull);
      expect(result.placeholderCharacs!.length, 1);
      expect(result.placeholderCharacs![0].placeholder, "date");
      expect(result.placeholderCharacs![0].type, "DateTime");
      expect(result.placeholderCharacs![0].format, "dd/MM/yyyy hh|mm|ss");
    });

    test("toWordingEntry: multiple placeholders", () {
      final WordingEntry result = converter.toWordingEntry(
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

    test("toWordingEntry: simple plural", () {
      final WordingEntry result = converter
          .toWordingEntry("{days, plural, zero{} one{1 day} other{many days}}");

      expect(
          result.value, "{days, plural, zero{} one{1 day} other{many days}}");
      expect(result.placeholderCharacs, null);
    });

    test("toWordingEntry: placeholder in plural", () {
      final parser = CellConverter();

      final WordingEntry result = parser.toWordingEntry(
          "{days, plural, zero{} one{1 day} other{{days|int} days}}");

      expect(
          result.value, "{days, plural, zero{} one{1 day} other{{days} days}}");
      expect(result.placeholderCharacs, isNotNull);
      expect(result.placeholderCharacs!.length, 1);
      expect(result.placeholderCharacs![0].placeholder, "days");
      expect(result.placeholderCharacs![0].type, "int");
      expect(result.placeholderCharacs![0].format, null);
    });

    /// INVALID CASES

    test("toWordingEntry: placeholder with space", () {
      final WordingEntry result = converter.toWordingEntry("Hello {us er}");

      expect(result.value, "Hello {us er}");
      expect(result.placeholderCharacs, null);
    });

    test("toWordingEntry: no placeholder", () {
      final WordingEntry result = converter.toWordingEntry("Hello {|int}");

      expect(result.value, "Hello {|int}");
      expect(result.placeholderCharacs, null);
    });

    test("toWordingEntry: no type info", () {
      final WordingEntry result = converter.toWordingEntry("Hello {user|}");

      expect(result.value, "Hello {user|}");
      expect(result.placeholderCharacs, null);
    });

    test("toWordingEntry: type info with space", () {
      final WordingEntry result =
          converter.toWordingEntry("Hello {user|Str ing}");

      expect(result.value, "Hello {user|Str ing}");
      expect(result.placeholderCharacs, null);
    });

    test("toWordingEntry: no format info", () {
      final WordingEntry result =
          converter.toWordingEntry("Hello {user|String|}");

      expect(result.value, "Hello {user|String|}");
      expect(result.placeholderCharacs, null);
    });

    test("toWordingEntry: no type and no format info", () {
      final WordingEntry result = converter.toWordingEntry("Hello {user||}");

      expect(result.value, "Hello {user||}");
      expect(result.placeholderCharacs, null);
    });
    test("fromWordingEntry: no placeholder", () {
      final result =
          converter.fromWordingEntry(WordingEntry("Hello everybody", null));

      expect(result, "Hello everybody");
    });

    test("fromWordingEntry: simple placeholder", () {
      final entry = WordingEntry(
        "Hello {user}",
        [PlaceholderCharac("user", null, null)],
      );

      final result = converter.fromWordingEntry(entry);

      expect(result, "Hello {user}");
    });

    test("fromWordingEntry: type placeholder", () {
      final entry = WordingEntry(
        "Hello {user}",
        [PlaceholderCharac("user", "String", null)],
      );

      final result = converter.fromWordingEntry(entry);

      expect(result, "Hello {user|String}");
    });

    test("fromWordingEntry: type alphanumeric placeholder", () {
      final entry = WordingEntry(
        "Hello {user1}",
        [PlaceholderCharac("user1", "String", null)],
      );

      final result = converter.fromWordingEntry(entry);

      expect(result, "Hello {user1|String}");
    });

    test("fromWordingEntry: type and format placeholder", () {
      final entry = WordingEntry(
        "It's {date}",
        [PlaceholderCharac("date", "DateTime", "dd/MM/yyyy:hh'h'mm'm'ss")],
      );

      final result = converter.fromWordingEntry(entry);

      expect(result, "It's {date|DateTime|dd/MM/yyyy:hh'h'mm'm'ss}");
    });

    test("fromWordingEntry: pipes allowed in format", () {
      final entry = WordingEntry(
        "It's {date}",
        [PlaceholderCharac("date", "DateTime", "dd/MM/yyyy hh|mm|ss")],
      );

      final result = converter.fromWordingEntry(entry);

      expect(result, "It's {date|DateTime|dd/MM/yyyy hh|mm|ss}");
    });

    test("fromWordingEntry: multiple placeholders", () {
      final entry = WordingEntry(
        "Hello {user}. It's {meteo} at {date}",
        [
          PlaceholderCharac("user", null, null),
          PlaceholderCharac("meteo", "String", null),
          PlaceholderCharac("date", "DateTime", "dd/MM/yyyy : hh'h'mm'm'ss"),
        ],
      );

      final result = converter.fromWordingEntry(entry);

      expect(result,
          "Hello {user}. It's {meteo|String} at {date|DateTime|dd/MM/yyyy : hh'h'mm'm'ss}");
    });

    test("fromWordingEntry: simple plural", () {
      final entry = WordingEntry(
        "{days, plural, zero{} one{1 day} other{many days}}",
        null,
      );

      final result = converter.fromWordingEntry(entry);

      expect(result, "{days, plural, zero{} one{1 day} other{many days}}");
    });

    test("fromWordingEntry: placeholder in plural", () {
      final entry = WordingEntry(
        "{days, plural, zero{} one{1 day} other{{days} days}}",
        [PlaceholderCharac("days", "int", null)],
      );

      final result = converter.fromWordingEntry(entry);

      expect(
          result, "{days, plural, zero{} one{1 day} other{{days|int} days}}");
    });
  });
}

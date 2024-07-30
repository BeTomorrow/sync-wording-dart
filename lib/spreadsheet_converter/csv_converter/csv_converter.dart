import 'dart:convert';

import 'package:sync_wording_dart/spreadsheet_converter/wording_parser.dart';
import 'package:sync_wording_dart/wording.dart';

class CSVConverter {
  final _parser = WordingParser();

  WordingResult convert(String rawCSVWording) {
    final WordingResult result = {};

    final rows = rawCSVWording.split("\n");
    if (rows.length < 2) {
      print("Not enough data in wording !");
      return result;
    }

    if (!rows[0].contains(',')) {
      print("No language column detected !");
      return result;
    }

    List<String> languages = rows[0].split(',').map((l) => jsonDecode(l) as String).toList().sublist(1);
    for (final l in languages) {
      result[l] = {};
    }

    for (var line = 1; line < rows.length; line++) {
      final elements = rows[line].split(',');
      if (rows[line][0].isEmpty) {
        break;
      }

      for (var languageCol = 0; languageCol < languages.length; languageCol++) {
        final language = languages[languageCol];
        final key = jsonDecode(elements[0]);
        final entry = _parser.parse(jsonDecode(elements[languageCol + 1]));
        result[language]![key] = entry;
      }
    }

    return result;
  }
}

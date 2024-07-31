import 'dart:io';

import 'package:sync_wording/wording.dart';

const _placeholderRegex = r'\{([a-zA-Z]+)([|]{1}[a-zA-Z]+([|]{1}[^}]+){0,1}){1}\}';
const _separator = "|";

class WordingParser {
  WordingEntry parse(String rawText) {
    List<PlaceholderCharac>? characs;

    final matches = RegExp(_placeholderRegex).allMatches(rawText).toList();
    if (matches.isNotEmpty) {
      var value = rawText;

      try {
        for (var index = matches.length - 1; index >= 0; index--) {
          final match = matches[index];
          final matchedStr = rawText.substring(match.start, match.end);

          var matchContent = matchedStr.substring(1, matchedStr.length - 1);

          var pipeIndex = matchContent.indexOf(_separator);
          if (pipeIndex != -1) {
            final placeholder = matchContent.substring(0, pipeIndex);

            value = value.replaceRange(match.start, match.end, "{$placeholder}");

            final typeAndFormat = matchContent.substring(pipeIndex + 1);
            var type = typeAndFormat;
            String? format;

            pipeIndex = type.indexOf(_separator);
            if (pipeIndex != -1) {
              type = typeAndFormat.substring(0, pipeIndex);
              format = typeAndFormat.substring(pipeIndex + 1);
            }

            if (type.isEmpty || (format != null && format.isEmpty)) {
              throw "Empty info";
            }

            characs ??= [];
            characs.insert(0, PlaceholderCharac(placeholder, type, format));
          }
        }
        return WordingEntry(value, characs);
      } catch (e) {
        stdout.writeln("Error parsing placeholders from '$rawText' -> Skip");
      }
    }

    return WordingEntry(rawText, null);
  }
}

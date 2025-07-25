import 'dart:io';

import 'package:sync_wording/src/wording/wording.dart';

// Regex to match placeholders with or without type/format
const _placeholderRegex =
    r'\{([a-zA-Z0-9]+)([|][a-zA-Z]+([|][^}]+){0,1}){0,1}\}';
const _separator = "|";

/// Main parser class that coordinates the parsing process
class CellConverter {
  final PlaceholderExtractor _placeholderExtractor;
  final PlaceholderFormatter _placeholderFormatter;

  CellConverter({
    PlaceholderExtractor? placeholderExtractor,
    PlaceholderFormatter? placeholderFormatter,
  })  : _placeholderExtractor = placeholderExtractor ?? PlaceholderExtractor(),
        _placeholderFormatter = placeholderFormatter ?? PlaceholderFormatter();

  WordingEntry toWordingEntry(String rawText) {
    try {
      final placeholders = _placeholderExtractor.extractPlaceholders(rawText);
      if (placeholders.isEmpty) {
        return WordingEntry(rawText, null);
      }

      final formattedText =
          _placeholderFormatter.formatText(rawText, placeholders);
      final characteristics =
          _placeholderFormatter.createCharacteristics(placeholders);

      return WordingEntry(formattedText, characteristics);
    } catch (e) {
      stdout.writeln("Error parsing placeholders from '$rawText' -> Skip");
      return WordingEntry(rawText, null);
    }
  }

  String fromWordingEntry(WordingEntry wordingEntry) {
    var value = wordingEntry.value;
    return value;
  }
}

/// Class responsible for extracting placeholders from text
class PlaceholderExtractor {
  List<_PlaceholderMatch> extractPlaceholders(String text) {
    final matches = RegExp(_placeholderRegex).allMatches(text).toList();
    return matches.map((match) {
      final matchedStr = text.substring(match.start, match.end);
      final content = matchedStr.substring(1, matchedStr.length - 1);
      return _PlaceholderMatch(match.start, match.end, content);
    }).toList();
  }
}

/// Class responsible for formatting text and creating placeholder characteristics
class PlaceholderFormatter {
  String formatText(String originalText, List<_PlaceholderMatch> placeholders) {
    var formattedText = originalText;
    for (var i = placeholders.length - 1; i >= 0; i--) {
      final placeholder = placeholders[i];
      final name = _extractPlaceholderName(placeholder.content);
      formattedText = formattedText.replaceRange(
        placeholder.start,
        placeholder.end,
        "{$name}",
      );
    }
    return formattedText;
  }

  List<PlaceholderCharac>? createCharacteristics(
      List<_PlaceholderMatch> placeholders) {
    if (placeholders.isEmpty) return null;

    final characteristics = <PlaceholderCharac>[];
    for (final placeholder in placeholders) {
      final name = _extractPlaceholderName(placeholder.content);
      final typeAndFormat = _extractTypeAndFormat(placeholder.content);

      if (typeAndFormat != null) {
        characteristics.add(PlaceholderCharac(
          name,
          typeAndFormat.type,
          typeAndFormat.format,
        ));
      } else {
        // For simple placeholders without type, use null for type and format
        characteristics.add(PlaceholderCharac(
          name,
          null,
          null,
        ));
      }
    }
    return characteristics;
  }

  String _extractPlaceholderName(String content) {
    final pipeIndex = content.indexOf(_separator);
    return pipeIndex == -1 ? content : content.substring(0, pipeIndex);
  }

  _TypeAndFormat? _extractTypeAndFormat(String content) {
    final pipeIndex = content.indexOf(_separator);
    if (pipeIndex == -1) return null;

    final typeAndFormat = content.substring(pipeIndex + 1);
    final secondPipeIndex = typeAndFormat.indexOf(_separator);

    if (secondPipeIndex == -1) {
      return _TypeAndFormat(typeAndFormat, null);
    }

    final type = typeAndFormat.substring(0, secondPipeIndex);
    final format = typeAndFormat.substring(secondPipeIndex + 1);

    if (type.isEmpty || format.isEmpty) {
      return null;
    }

    return _TypeAndFormat(type, format);
  }
}

/// Class representing a placeholder match in the text
class _PlaceholderMatch {
  final int start;
  final int end;
  final String content;

  _PlaceholderMatch(this.start, this.end, this.content);
}

/// Class representing type and format information for a placeholder
class _TypeAndFormat {
  final String type;
  final String? format;

  _TypeAndFormat(this.type, this.format);
}

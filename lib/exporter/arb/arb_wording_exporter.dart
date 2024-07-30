import 'dart:convert';
import 'dart:io';

import 'package:sync_wording_dart/exporter/arb/typed_placeholder_exporter.dart';
import 'package:sync_wording_dart/exporter/wording_exporter.dart';
import 'package:sync_wording_dart/wording.dart';

const _placeholdersKey = "placeholders";

class ARBWordingExporter extends WordingExporter {
  @override
  Future<void> export(String locale, Map<String, WordingEntry> wordingEntries, String outputFile) async {
    final Map<String, dynamic> translations = {"@@locale": locale};
    for (final wording in wordingEntries.entries) {
      _exportWording(translations, wording.key, wording.value);
    }

    final file = File(outputFile);
    if (await file.exists()) {
      await file.delete();
    }
    await file.create(recursive: true);
    final encoder = JsonEncoder.withIndent("  ");
    await file.writeAsString(encoder.convert(translations));
  }

  /// Examples :
  ///     "welcome": "Hello {user}",
  ///     "@welcome": {
  ///         "placeholders": {
  ///             "user": {
  ///                 "type": "String",
  ///             }
  ///         }
  ///     }
  ///     "today": "It's {date}",
  ///     "@today": {
  ///         "placeholders": {
  ///             "date": {
  ///                 "type": "DateTime",
  ///                 "format": "dd/MM/yyyy:hh'h'mm'm'ss",
  ///                 "isCustomDateFormat": "true"
  ///             }
  ///         }
  ///     }
  void _exportWording(Map<String, dynamic> translations, String key, WordingEntry entry) {
    translations[key] = entry.value;

    final characs = entry.placeholderCharacs;
    if (characs != null) {
      final placeholderMap = {};

      for (final charac in characs) {
        final characMap = PlaceholderExporter.forType(charac.type).export(charac);
        placeholderMap[charac.placeholder] = characMap;
      }

      translations["@$key"] = {_placeholdersKey: placeholderMap};
    }
  }
}

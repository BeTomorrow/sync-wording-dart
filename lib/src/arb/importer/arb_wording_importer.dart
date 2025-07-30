import 'dart:convert';
import 'dart:io';

import 'package:sync_wording/src/arb/importer/wording_importer.dart';
import 'package:sync_wording/src/wording/wording.dart';

class ARBWordingImporter extends WordingImporter {
  static const _placeholdersKey = "placeholders";

  @override
  Future<Wordings> import(Map<String, String> localeFiles) async {
    final wordings = <String, LanguageWordings>{};

    for (final locale in localeFiles.keys) {
      final filePath = localeFiles[locale]!;
      final file = File(filePath);

      if (!await file.exists()) {
        wordings[locale] = <String, WordingEntry>{};
        continue;
      }

      final fileContent = await file.readAsString();
      final json = jsonDecode(fileContent) as Map<String, dynamic>;

      final languageWordings = <String, WordingEntry>{};

      for (final entry in json.entries) {
        final key = entry.key;
        final value = entry.value;

        if (key.startsWith('@')) continue;

        final metadataKey = '@$key';
        final metadata = json[metadataKey] as Map<String, dynamic>?;

        List<PlaceholderCharac>? placeholderCharacs;
        if (metadata != null && metadata.containsKey(_placeholdersKey)) {
          final placeholders =
              metadata[_placeholdersKey] as Map<String, dynamic>;
          placeholderCharacs = _parsePlaceholders(placeholders);
        }

        languageWordings[key] =
            WordingEntry(value.toString(), placeholderCharacs);
      }

      wordings[locale] = languageWordings;
    }

    return wordings;
  }

  List<PlaceholderCharac> _parsePlaceholders(
      Map<String, dynamic> placeholders) {
    final characs = <PlaceholderCharac>[];

    for (final entry in placeholders.entries) {
      final placeholder = entry.key;
      final characData = entry.value as Map<String, dynamic>;

      final type = characData['type'] as String?;
      final format = characData['format'] as String?;

      characs.add(PlaceholderCharac(placeholder, type, format));
    }

    return characs;
  }
}

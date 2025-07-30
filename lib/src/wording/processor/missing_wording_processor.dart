import 'package:sync_wording/src/config/wording_config.dart';
import 'package:sync_wording/src/wording/processor/wording_processor_manager.dart';
import 'package:sync_wording/src/wording/wording.dart';

/// A processor that checks for missing translations in the wordings
/// It can be used with or without fallback translations
/// If fallback translations are enabled, it will use the fallback translations
/// If fallback translations are disabled, it will log a warning for each missing translation
class MissingWordingProcessor extends WordingProcessor {
  final FallbackConfig fallbackConfig;

  MissingWordingProcessor(super.logger, this.fallbackConfig);

  @override
  void process(Wordings wordings) {
    if (!fallbackConfig.enabled) {
      _processWithoutFallback(wordings);
      return;
    }

    _processWithFallback(wordings);
  }

  void _processWithoutFallback(Wordings wordings) {
    for (final language in wordings.keys) {
      for (final key in wordings[language]!.keys) {
        final wordingEntry = wordings[language]![key];
        if (wordingEntry == null || wordingEntry.value.isEmpty) {
          logger.log("⚠️ Missing wording for '$key' in '$language'");
        }
      }
    }
  }

  void _processWithFallback(Wordings wordings) {
    final defaultLanguage = fallbackConfig.defaultLanguage;
    final defaultWordings = wordings[defaultLanguage];

    if (defaultWordings == null) {
      logger
          .log("⚠️ Default language '$defaultLanguage' not found in wordings");
      _processWithoutFallback(wordings);
      return;
    }

    for (final language in wordings.keys) {
      if (language == defaultLanguage) continue;

      final languageWordings = wordings[language]!;
      for (final key in defaultWordings.keys) {
        final wordingEntry = languageWordings[key];
        final defaultEntry = defaultWordings[key];

        if (wordingEntry == null || wordingEntry.value.isEmpty) {
          if (defaultEntry != null && defaultEntry.value.isNotEmpty) {
            // Apply fallback translation
            languageWordings[key] = defaultEntry;
            logger.log(
                "ℹ️ Applied fallback translation for '$key' in '$language' from '$defaultLanguage'");
          } else {
            logger.log(
                "⚠️ Missing wording for '$key' in '$language' and '$defaultLanguage'");
          }
        }
      }
    }
  }
}

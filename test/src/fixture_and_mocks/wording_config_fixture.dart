import 'package:sync_wording/src/config/wording_config.dart';

class WordingConfigFixture {
  static WordingConfig forTest({
    String? sheetId,
    List<String>? sheetNames,
    String? outputDir,
    int? sheetStartIndex,
    int? keyColumn,
    List<LanguageConfig>? languages,
    FallbackConfig? fallback,
    ValidationConfig? validation,
    GenL10nConfig? genL10n,
  }) {
    return WordingConfig(
      CredentialsConfig('clientId', 'clientSecret', 'credentials.json'),
      sheetId ?? 'test-sheet-id',
      sheetNames ?? [],
      outputDir ?? 'outputs',
      sheetStartIndex ?? 2,
      keyColumn ?? 1,
      languages ?? [LanguageConfig('en', 2), LanguageConfig('fr', 3)],
      fallback ?? FallbackConfig.disabled(),
      validation ?? ValidationConfig.always(),
      genL10n ?? GenL10nConfig(false),
    );
  }
}

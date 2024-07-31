class CredentialsConfig {
  final String clientId;
  final String clientSecret;
  final String credentialsFile;

  CredentialsConfig(this.clientId, this.clientSecret, this.credentialsFile);
}

class LanguageConfig {
  final String locale;
  final int column;

  LanguageConfig(this.locale, this.column);
}

class ValidationConfig {
  final int? column;
  final String? expected;

  ValidationConfig._(this.column, this.expected);

  factory ValidationConfig.always() => ValidationConfig._(null, null);

  factory ValidationConfig.withExpected(int column, String expected) =>
      ValidationConfig._(column, expected);
}

class GenL10nConfig {
  final bool autoCall;
  final bool withFvm;

  GenL10nConfig(this.autoCall, [this.withFvm = false]);
}

class WordingConfig {
  final CredentialsConfig credentials;
  final String sheetId;
  final List<String> sheetNames;
  final String outputDir;
  final int sheetStartIndex;
  final int keyColumn;
  final List<LanguageConfig> languages;
  final ValidationConfig validation;
  final GenL10nConfig genL10n;

  WordingConfig(
    this.credentials,
    this.sheetId,
    this.sheetNames,
    this.outputDir,
    this.sheetStartIndex,
    this.keyColumn,
    this.languages,
    this.validation,
    this.genL10n,
  );
}

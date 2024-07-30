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
  final List<LanguageConfig> languages;
  final GenL10nConfig genL10n;

  WordingConfig(this.credentials, this.sheetId, this.sheetNames, this.outputDir, this.languages, this.genL10n);
}

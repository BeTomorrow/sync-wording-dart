import 'dart:io';

import 'package:sync_wording/config/wording_config.dart';
import 'package:yaml/yaml.dart';

const _defaultCredentialsFile = ".google_access_token.json";

// These secrets are allowed to be publicly revealed in the codebase.
final _defaultCredentialsConfig = CredentialsConfig(
  "1309740887-6u609jvssi5c2e56vd5n5dc4drgsc906.apps.googleusercontent.com",
  "bEK0Dy-9Y5doRvjfx_AtH0rS",
  _defaultCredentialsFile,
);

/// Interface for loading configuration from a file
/// Main class that coordinates the configuration loading process
class WordingConfigLoader {
  final YamlParser _yamlParser;
  final ConfigBuilder _configBuilder;

  WordingConfigLoader({
    YamlParser? yamlParser,
    ConfigBuilder? configBuilder,
  })  : _yamlParser = yamlParser ?? YamlParser(),
        _configBuilder = configBuilder ?? ConfigBuilder();

  Future<WordingConfig> loadConfiguration(String configPath) async {
    final yamlData = await _yamlParser.parseFile(configPath);
    return _configBuilder.build(yamlData);
  }
}

/// Class responsible for parsing YAML files
class YamlParser {
  Future<Map<String, dynamic>> parseFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('Configuration file not found: $filePath');
    }

    final yamlString = await file.readAsString();
    final yamlMap = loadYaml(yamlString);
    if (yamlMap is! YamlMap) {
      throw Exception('Invalid YAML format');
    }

    return yamlMap.cast<String, dynamic>();
  }
}

/// Class responsible for building configuration objects
class ConfigBuilder {
  WordingConfig build(Map<String, dynamic> yamlData) {
    final sheetId = yamlData['sheetId'] as String?;
    if (sheetId == null) {
      throw Exception('Missing required field: sheetId');
    }

    final outputDir = yamlData['output_dir'] as String?;
    if (outputDir == null) {
      throw Exception('Missing required field: output_dir');
    }

    final languages =
        _parseLanguages(yamlData['languages'] as Map<dynamic, dynamic>?);
    if (languages.isEmpty) {
      throw Exception('Missing required field: languages');
    }

    final credentials =
        _parseCredentials(yamlData['credentials'] as Map<dynamic, dynamic>?);
    final validation =
        _parseValidation(yamlData['validation'] as Map<dynamic, dynamic>?);
    final genL10n =
        _parseGenL10n(yamlData['gen_l10n'] as Map<dynamic, dynamic>?);
    final sheetNames =
        _parseSheetNames(yamlData['sheetNames'] as List<dynamic>?);
    final sheetStartIndex = yamlData['sheetStartIndex'] as int? ?? 2;
    final keyColumn = yamlData['keyColumn'] as int? ?? 1;

    return WordingConfig(
      credentials,
      sheetId,
      sheetNames,
      outputDir,
      sheetStartIndex,
      keyColumn,
      languages,
      validation ?? ValidationConfig.always(),
      genL10n,
    );
  }

  List<LanguageConfig> _parseLanguages(Map<dynamic, dynamic>? languages) {
    if (languages == null) return [];

    return languages.entries.map((entry) {
      final locale = entry.key as String;
      final config = entry.value as Map<dynamic, dynamic>;
      return LanguageConfig(locale, config['column'] as int);
    }).toList();
  }

  CredentialsConfig _parseCredentials(Map<dynamic, dynamic>? credentials) {
    if (credentials == null) {
      return _defaultCredentialsConfig;
    }

    return CredentialsConfig(
      credentials['client_id'] as String,
      credentials['client_secret'] as String,
      credentials['credentials_file'] as String,
    );
  }

  ValidationConfig? _parseValidation(Map<dynamic, dynamic>? validation) {
    if (validation == null) return null;

    return ValidationConfig.withExpected(
      validation['column'] as int,
      validation['expected'] as String,
    );
  }

  GenL10nConfig _parseGenL10n(Map<dynamic, dynamic>? genL10n) {
    if (genL10n == null) {
      return GenL10nConfig(false);
    }

    return GenL10nConfig(
      genL10n['auto_call'] as bool? ?? false,
      genL10n['with_fvm'] as bool? ?? false,
    );
  }

  List<String> _parseSheetNames(List<dynamic>? sheetNames) {
    if (sheetNames == null) return [];
    return sheetNames.map((name) => name as String).toList();
  }
}

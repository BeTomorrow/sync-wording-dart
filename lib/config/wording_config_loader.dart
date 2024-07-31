import 'dart:io';

import 'package:sync_wording/config/wording_config.dart';
import 'package:yaml/yaml.dart';

const _defaultCredentialsFile = ".google_access_token.json";

class WordingConfigLoader {
  Future<WordingConfig> loadConfiguration(String configFile) async {
    try {
      final file = File(configFile);
      final yamlAsString = await file.readAsString();
      YamlMap yamlMap = loadYaml(yamlAsString);
      final yamlData = yamlMap.toMap();

      final credentialsYamlData = yamlData["credentials"];
      if (credentialsYamlData == null) {
        throw "Config file does not contain credentials info";
      }
      final credentialsConfig = CredentialsConfig(
        credentialsYamlData["client_id"] as String,
        credentialsYamlData["client_secret"] as String,
        credentialsYamlData["credentials_file"] ?? _defaultCredentialsFile,
      );

      final sheetNamesYamlData = yamlData["sheetNames"];
      final sheetNames = sheetNamesYamlData != null ? List<String>.from(sheetNamesYamlData) : <String>[];

      final languageMap = yamlData["languages"] as Map<String, dynamic>;

      final validationColumn = yamlData["validation"]?["column"];
      final validationExpected = yamlData["validation"]?["expected"];
      final validationConfig = (validationColumn != null && validationExpected != null)
          ? ValidationConfig.withExpected(validationColumn, validationExpected)
          : ValidationConfig.always();

      final gen10nYamlData = yamlData["gen_l10n"];
      GenL10nConfig genL10nConfig = gen10nYamlData == null
          ? GenL10nConfig(false)
          : GenL10nConfig(gen10nYamlData["auto_call"], gen10nYamlData["with_fvm"] ?? false);

      return WordingConfig(
        credentialsConfig,
        yamlData["sheetId"],
        sheetNames,
        yamlData["output_dir"],
        yamlData["sheet_start_index"] ?? 2,
        yamlData["key_column"] ?? 1,
        languageMap.keys.map((locale) {
          final localeConfig = languageMap[locale];
          return LanguageConfig(locale, localeConfig!["column"]!);
        }).toList(),
        validationConfig,
        genL10nConfig,
      );
    } catch (e) {
      stderr.writeln("Unable to read config file '$configFile' : $e");
      rethrow;
    }
  }
}

extension YamlMapConverter on YamlMap {
  dynamic _convertNode(dynamic v) {
    if (v is YamlMap) {
      return v.toMap();
    } else if (v is YamlList) {
      var list = <dynamic>[];
      for (var e in v) {
        list.add(_convertNode(e));
      }
      return list;
    } else {
      return v;
    }
  }

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{};
    nodes.forEach((k, v) {
      map[(k as YamlScalar).value.toString()] = _convertNode(v.value);
    });
    return map;
  }
}

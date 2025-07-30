import 'dart:io';

import 'package:sync_wording/src/config/wording_config.dart';
import 'package:sync_wording/src/config/wording_config_loader.dart';
import 'package:test/test.dart';

const _defaultCredentialsFile = ".google_access_token.json";

// These secrets are allowed to be publicly revealed in the codebase.
final _defaultCredentialsConfig = CredentialsConfig(
  "1309740887-6u609jvssi5c2e56vd5n5dc4drgsc906.apps.googleusercontent.com",
  "bEK0Dy-9Y5doRvjfx_AtH0rS",
  _defaultCredentialsFile,
);

void main() {
  group('WordingConfigLoader', () {
    late Directory tempDir;
    late File configFile;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('wording_config_test_');
      configFile = File('${tempDir.path}/wording_config.yaml');
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('should load configuration with default credentials', () async {
      await configFile.writeAsString('''
sheetId: "test-sheet-id"
output_dir: "lib/localizations"
languages:
  en:
    column: 2
  fr:
    column: 3
''');

      final loader = WordingConfigLoader();
      final config = await loader.loadConfiguration(configFile.path);

      expect(config.sheetId, equals('test-sheet-id'));
      expect(config.outputDir, equals('lib/localizations'));
      expect(config.languages.length, equals(2));
      expect(config.languages[0].locale, equals('en'));
      expect(config.languages[0].column, equals(2));
      expect(config.languages[1].locale, equals('fr'));
      expect(config.languages[1].column, equals(3));
      expect(config.credentials.clientId,
          equals(_defaultCredentialsConfig.clientId));
      expect(config.credentials.clientSecret,
          equals(_defaultCredentialsConfig.clientSecret));
    });

    test('should load configuration with custom credentials', () async {
      await configFile.writeAsString('''
sheetId: "test-sheet-id"
output_dir: "lib/localizations"
credentials:
  client_id: "custom-client-id"
  client_secret: "custom-client-secret"
  credentials_file: "custom-credentials.json"
languages:
  en:
    column: 2
''');

      final loader = WordingConfigLoader();
      final config = await loader.loadConfiguration(configFile.path);

      expect(config.credentials.clientId, equals('custom-client-id'));
      expect(config.credentials.clientSecret, equals('custom-client-secret'));
      expect(config.credentials.credentialsFile,
          equals('custom-credentials.json'));
    });

    test('should load configuration with validation', () async {
      await configFile.writeAsString('''
sheetId: "test-sheet-id"
output_dir: "lib/localizations"
languages:
  en:
    column: 2
validation:
  column: 4
  expected: "OK"
''');

      final loader = WordingConfigLoader();
      final config = await loader.loadConfiguration(configFile.path);

      expect(config.validation.column, equals(4));
      expect(config.validation.expected, equals('OK'));
    });

    test('should load configuration with gen_l10n settings', () async {
      await configFile.writeAsString('''
sheetId: "test-sheet-id"
output_dir: "lib/localizations"
languages:
  en:
    column: 2
gen_l10n:
  auto_call: true
  with_fvm: true
''');

      final loader = WordingConfigLoader();
      final config = await loader.loadConfiguration(configFile.path);

      expect(config.genL10n.autoCall, isTrue);
      expect(config.genL10n.withFvm, isTrue);
    });

    test('should load configuration with sheet names', () async {
      await configFile.writeAsString('''
sheetId: "test-sheet-id"
output_dir: "lib/localizations"
sheetNames: ["Sheet1", "Sheet2"]
languages:
  en:
    column: 2
''');

      final loader = WordingConfigLoader();
      final config = await loader.loadConfiguration(configFile.path);

      expect(config.sheetNames, equals(['Sheet1', 'Sheet2']));
    });

    test('should use default values for optional fields', () async {
      await configFile.writeAsString('''
sheetId: "test-sheet-id"
output_dir: "lib/localizations"
languages:
  en:
    column: 2
''');

      final loader = WordingConfigLoader();
      final config = await loader.loadConfiguration(configFile.path);

      expect(config.sheetStartIndex, equals(2));
      expect(config.keyColumn, equals(1));
      expect(config.sheetNames, isEmpty);
      expect(config.genL10n.autoCall, isFalse);
      expect(config.genL10n.withFvm, isFalse);
    });

    test('should throw error for invalid YAML', () async {
      await configFile.writeAsString('''
invalid: yaml: content
''');

      final loader = WordingConfigLoader();
      expect(
        () => loader.loadConfiguration(configFile.path),
        throwsException,
      );
    });

    test('should throw error for missing required fields', () async {
      await configFile.writeAsString('''
output_dir: "lib/localizations"
languages:
  en:
    column: 2
''');

      final loader = WordingConfigLoader();
      try {
        await loader.loadConfiguration(configFile.path);
        fail('Expected an error to be thrown');
      } catch (e) {
        expect(e, isA<Exception>());
        expect(e.toString(), contains('Missing required field: sheetId'));
      }
    });

    test('should parse fallback configuration when enabled', () async {
      await configFile.writeAsString('''
sheetId: "test-sheet-id"
output_dir: "lib/localizations"
languages:
  en:
    column: 2
  fr:
    column: 3
fallback:
  enabled: true
  default_language: "en"
''');

      final loader = WordingConfigLoader();
      final config = await loader.loadConfiguration(configFile.path);

      expect(config.fallback.enabled, isTrue);
      expect(config.fallback.defaultLanguage, equals('en'));
    });

    test('should use disabled fallback when disabled', () async {
      await configFile.writeAsString('''
sheetId: "test-sheet-id"
output_dir: "lib/localizations"
languages:
  en:
    column: 2
  fr:
    column: 3
fallback:
  enabled: false
  default_language: "en"
''');

      final loader = WordingConfigLoader();
      final config = await loader.loadConfiguration(configFile.path);

      expect(config.fallback.enabled, isFalse);
    });

    test('should use disabled fallback when not specified', () async {
      await configFile.writeAsString('''
sheetId: "test-sheet-id"
output_dir: "lib/localizations"
languages:
  en:
    column: 2
  fr:
    column: 3
''');

      final loader = WordingConfigLoader();
      final config = await loader.loadConfiguration(configFile.path);

      expect(config.fallback.enabled, isFalse);
      expect(config.fallback.defaultLanguage, equals(''));
    });

    test(
        'should throw error when fallback enabled but default_language missing',
        () async {
      await configFile.writeAsString('''
sheetId: "test-sheet-id"
output_dir: "lib/localizations"
languages:
  en:
    column: 2
  fr:
    column: 3
fallback:
  enabled: true
''');

      final loader = WordingConfigLoader();
      try {
        await loader.loadConfiguration(configFile.path);
        fail('Expected an error to be thrown');
      } catch (e) {
        expect(e, isA<Exception>());
        expect(
            e.toString(),
            contains(
                'Missing required field: default_language in fallback config'));
      }
    });
  });
}

import 'package:sync_wording/src/wording/wording.dart';

abstract class WordingImporter {
  /// Generic method to call to import the translation files used by the project
  Future<Wordings> import(Map<String, String> localeFiles);
}

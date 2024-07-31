import 'package:sync_wording/wording.dart';

sealed class PlaceholderExporter {
  String get _type;

  static final _exporters = <PlaceholderExporter>[_DateTimePlaceholderExporter()];
  static final _defaultExporter = _DefaultPlaceholderExporter();

  Map<String, dynamic> export(PlaceholderCharac placeholderCharac);

  static PlaceholderExporter forType(String type) {
    for (final exporter in _exporters) {
      if (exporter._type == type) {
        return exporter;
      }
    }
    return _defaultExporter;
  }
}

class _DefaultPlaceholderExporter extends PlaceholderExporter {
  @override
  String get _type => "_";

  @override
  Map<String, dynamic> export(PlaceholderCharac placeholderCharac) {
    final characMap = {"type": placeholderCharac.type};

    final format = placeholderCharac.format;
    if (format != null) {
      characMap["format"] = format;
    }

    return characMap;
  }
}

class _DateTimePlaceholderExporter extends PlaceholderExporter {
  @override
  String get _type => "DateTime";

  @override
  Map<String, dynamic> export(PlaceholderCharac charac) {
    final characMap = {"type": charac.type};

    final format = charac.format;
    if (format != null) {
      characMap["format"] = format;
      characMap["isCustomDateFormat"] = "true";
    }

    return characMap;
  }
}

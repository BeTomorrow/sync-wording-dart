import 'package:sync_wording/wording.dart';

/// Generic class dedicated to create the PlaceholderCharac data
/// ready to be exported in the ARB file
sealed class PlaceholderExporter {
  String get _type;

  static final _exporters = <PlaceholderExporter>[
    _DateTimePlaceholderExporter()
  ];
  static final _defaultExporter = _DefaultPlaceholderExporter();

  /// Abstract class to export the
  Map<String, dynamic> export(PlaceholderCharac placeholderCharac);

  /// Factory method to create the exporter dedicated to the defined type
  static PlaceholderExporter forType(String? type) {
    if (type == null) {
      return _defaultExporter;
    }

    for (final exporter in _exporters) {
      if (exporter._type == type) {
        return exporter;
      }
    }
    return _defaultExporter;
  }
}

/// The default exporter for common placeholder types
class _DefaultPlaceholderExporter extends PlaceholderExporter {
  @override
  String get _type => "_";

  @override
  Map<String, dynamic> export(PlaceholderCharac placeholderCharac) {
    final characMap = {"type": placeholderCharac.type ?? "Object"};

    final format = placeholderCharac.format;
    if (format != null) {
      characMap["format"] = format;
    }

    return characMap;
  }
}

/// The exporter dedicated to DataTime placeholder types
class _DateTimePlaceholderExporter extends PlaceholderExporter {
  @override
  String get _type => "DateTime";

  @override
  Map<String, dynamic> export(PlaceholderCharac charac) {
    final characMap = {"type": charac.type ?? "Object"};

    final format = charac.format;
    if (format != null) {
      characMap["format"] = format;
      characMap["isCustomDateFormat"] = "true";
    }

    return characMap;
  }
}

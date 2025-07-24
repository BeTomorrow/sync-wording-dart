import 'package:sync_wording/src/config/wording_config.dart';

/// Class used to validate or invalidate a translation
sealed class Validator {
  static final _alwaysTrueValidator = _AlwaysTrueValidator();
  static final List<_CheckValueValidator> _checkValueValidators = [];

  /// Abstract method called to validate or invalidate a worksheet row
  bool isValid(List<String?> row);

  /// Method that returns a validator object matching the specified config
  factory Validator.get(ValidationConfig config) {
    final column = config.column;
    final expected = config.expected;
    if (column == null || expected == null) {
      return _alwaysTrueValidator;
    }

    return _checkValueValidators.firstWhere(
      (v) => v._column == column && v._expected == expected,
      orElse: () {
        final validator = _CheckValueValidator(column, expected);
        _checkValueValidators.add(validator);
        return validator;
      },
    );
  }
}

class _AlwaysTrueValidator implements Validator {
  /// Always validates a translation row
  @override
  bool isValid(List<String?> row) => true;
}

class _CheckValueValidator implements Validator {
  final int _column;
  final String _expected;

  _CheckValueValidator(this._column, this._expected);

  /// Compare the value in the row a the specified column
  /// Returns true if value is the same than the expected one
  @override
  bool isValid(List<String?> row) {
    if (row.length >= _column) {
      return row[_column - 1] == _expected;
    }
    return false;
  }
}

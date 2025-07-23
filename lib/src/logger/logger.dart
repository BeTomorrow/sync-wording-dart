abstract class Logger {
  void log(String message, {LogColor color = LogColor.none});
}

enum LogColor {
  reset('\x1B[0m'),
  none(''),
  green('\x1B[32m'),
  orange('\x1B[38;5;208m'),
  red('\x1B[31m'),
  blue('\x1B[34m'),
  magenta('\x1B[35m'),
  cyan('\x1B[36m');

  final String code;

  const LogColor(this.code);
}

class ConsoleLogger extends Logger {
  @override
  void log(String message, {LogColor color = LogColor.none}) {
    if (color == LogColor.none) {
      print(message);
    } else {
      print('${color.code}$message${LogColor.reset.code}');
    }
  }
}

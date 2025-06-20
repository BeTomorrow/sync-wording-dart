abstract class Logger {
  void log(String message);
}

class ConsoleLogger extends Logger {
  @override
  void log(String message) {
    print(message);
  }
}

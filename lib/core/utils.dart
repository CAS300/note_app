class AppUtils {
  static int currentTimestamp() {
    return DateTime.now().millisecondsSinceEpoch ~/ 1000;
  }
}

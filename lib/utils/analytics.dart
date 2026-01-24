class Analytics {
  static void logEvent(String name, [Map<String, Object?>? params]) {
    // Lightweight analytics shim — replace with real analytics provider if available.
    // Keep side-effects minimal for tests.
    // ignore: avoid_print
    print('Analytics event: $name ${params ?? {}}');
  }

}

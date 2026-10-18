import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  await integrationDriver(
    onScreenshot:
        (String name, List<int> bytes, [Map<String, Object?>? args]) async {
          const expected = {
            'verified-dashboard',
            'verified-equipment',
            'verified-synthetic',
          };
          const png = [137, 80, 78, 71, 13, 10, 26, 10];
          if (!expected.contains(name) || bytes.length < 1000) return false;
          for (var i = 0; i < png.length; i++) {
            if (bytes[i] != png[i]) return false;
          }
          await Directory('device-evidence').create(recursive: true);
          await File('device-evidence/$name.png')
              .writeAsBytes(bytes, flush: true);
          return true;
        },
    responseDataCallback: (_) async {},
  );
}

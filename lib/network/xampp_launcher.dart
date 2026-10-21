import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// Windows only: starts XAMPP's Apache and MySQL when the app opens, so the
/// server is up without opening the XAMPP Control Panel.
///
/// It only does anything when
///  - the app runs on Windows,
///  - the server address points at this PC (localhost / 127.0.0.1), and
///  - XAMPP is installed in [folder].
/// Services that are already running are left alone. Apache and MySQL keep
/// running after the app closes (stop them in the XAMPP Control Panel, or by
/// signing out / restarting the PC).
class XamppLauncher {
  XamppLauncher._();

  /// Where XAMPP is installed.
  static const folder = r'C:\xampp';

  static Future<void>? _run;

  /// Starts the services if needed and completes when both answer (or after
  /// about 20 seconds). Safe to call several times: it only runs once.
  static Future<void> startIfNeeded(String baseUrl) =>
      _run ??= _startIfNeeded(baseUrl);

  static Future<void> _startIfNeeded(String baseUrl) async {
    if (!Platform.isWindows) return;
    final uri = Uri.tryParse(baseUrl);
    if (uri == null || !_isThisPc(uri.host)) return;
    final apachePort = uri.hasPort ? uri.port : 80;
    const mysqlPort = 3306;

    try {
      if (!await Directory(folder).exists()) return;

      if (!await _isOpen(mysqlPort)) {
        await _start(
          '$folder\\mysql\\bin\\mysqld.exe',
          [
            '--defaults-file=$folder\\mysql\\bin\\my.ini',
            '--standalone',
          ],
          '$folder\\mysql\\bin',
        );
      }
      if (!await _isOpen(apachePort)) {
        await _start(
          '$folder\\apache\\bin\\httpd.exe',
          const [],
          '$folder\\apache\\bin',
        );
      }

      // Give them a moment to come up before the first sync.
      final deadline = DateTime.now().add(const Duration(seconds: 20));
      while (DateTime.now().isBefore(deadline)) {
        if (await _isOpen(mysqlPort) && await _isOpen(apachePort)) return;
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }
      debugPrint('XamppLauncher: Apache/MySQL did not answer within 20 s');
    } catch (e) {
      debugPrint('XamppLauncher: $e');
    }
  }

  static bool _isThisPc(String host) {
    final h = host.toLowerCase();
    return h == 'localhost' || h == '127.0.0.1' || h == '::1' || h == '[::1]';
  }

  static Future<bool> _isOpen(int port) async {
    try {
      final socket = await Socket.connect(
        InternetAddress.loopbackIPv4,
        port,
        timeout: const Duration(milliseconds: 400),
      );
      socket.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> _start(
    String exe,
    List<String> args,
    String workingDirectory,
  ) async {
    if (!await File(exe).exists()) {
      debugPrint('XamppLauncher: $exe not found');
      return;
    }
    // detached: no console window, and it keeps running after the app closes.
    await Process.start(
      exe,
      args,
      workingDirectory: workingDirectory,
      mode: ProcessStartMode.detached,
    );
  }
}

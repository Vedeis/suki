import 'package:flutter/services.dart';

class NotificationService {
  static const _channel = MethodChannel('app.moneyflow/notifications');

  static Future<bool> hasAccess() async {
    try { return await _channel.invokeMethod<bool>('hasNotificationAccess') ?? false; }
    on PlatformException { return false; }
  }

  static Future<void> openSettings() async {
    await _channel.invokeMethod<void>('openNotificationSettings');
  }

  static Future<List<dynamic>> pending() async {
    try {
      return await _channel.invokeMethod<List<dynamic>>('getPendingTransactions') ?? [];
    } on PlatformException { return []; }
  }

  static Future<void> clearPending() async {
    await _channel.invokeMethod<void>('clearPendingTransactions');
  }
}

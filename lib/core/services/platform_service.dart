import 'package:flutter/services.dart';

/// Native Android share sheet and store-rating triggers, through one tiny
/// MethodChannel (see MainActivity.kt). No plugin: nothing extra to ship or
/// keep alive on a 2 GB phone.
class PlatformService {
  PlatformService._();

  static const MethodChannel _channel =
      MethodChannel('scripture_sermon_studio/platform');

  /// The Play Store listing id. Must match `applicationId` in
  /// android/app/build.gradle.kts.
  static const String storeId = 'com.posibabu.holybible';

  static String get storeUrl =>
      'https://play.google.com/store/apps/details?id=$storeId';

  /// Opens the system share sheet. Returns false when it could not be shown.
  static Future<bool> share(String text, {String subject = ''}) async {
    try {
      await _channel.invokeMethod<void>(
          'share', <String, String>{'text': text, 'subject': subject});
      return true;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Opens the app's store page (Play Store app first, browser as fallback).
  static Future<bool> openStorePage() async {
    try {
      await _channel.invokeMethod<void>(
          'openStore', <String, String>{'id': storeId, 'url': storeUrl});
      return true;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}

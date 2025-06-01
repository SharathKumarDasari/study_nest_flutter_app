import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:permission_handler/permission_handler.dart';

Future<bool> requestStoragePermission() async {
  try {
    // On Android, request storage permission; on iOS, this isn't required for Downloads directory
    final status = await Permission.storage.status;
    if (status.isGranted) {
      return true;
    }

    if (status.isPermanentlyDenied) {
      debugPrint('Storage permission permanently denied. Opening settings.');
      await openAppSettings();
      return false;
    }

    final result = await Permission.storage.request();
    if (result.isGranted) {
      debugPrint('Storage permission granted');
      return true;
    } else {
      debugPrint('Storage permission denied');
      return false;
    }
  } catch (e) {
    debugPrint('Error requesting storage permission: $e');
    return false;
  }
}
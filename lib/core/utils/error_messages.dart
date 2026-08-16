import 'package:flutter/foundation.dart';

import '../network/api_client.dart';

/// Backend/Dio error text is often untranslated, technical, or simply not
/// meant for an end user (e.g. raw Dio timeout strings, unlocalized backend
/// validation messages). Call sites that already branch on [ApiException.code]
/// for specific, curated Thai messages should keep doing that — this is only
/// for the generic catch-all branch that used to show `e.message` verbatim.
String friendlyErrorMessage(
  Object error, [
  String fallback = 'เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง',
]) {
  if (error is ApiException && error.statusCode == null) {
    debugPrint('friendlyErrorMessage (network): $error');
    return 'เชื่อมต่อเซิร์ฟเวอร์ไม่สำเร็จ กรุณาตรวจสอบอินเทอร์เน็ตแล้วลองใหม่อีกครั้ง';
  }
  debugPrint('friendlyErrorMessage suppressed raw error: $error');
  return fallback;
}

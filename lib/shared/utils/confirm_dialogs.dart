import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// Shared "discard unsaved changes?" prompt — used by every edit page/sheet
/// that can be left mid-edit (back button, sheet dismiss, tab switch).
/// Returns `true` only if the user explicitly chose to leave.
Future<bool> confirmDiscardChanges(
  BuildContext context, {
  String title = 'ยังไม่ได้บันทึกการเปลี่ยนแปลง',
  String message = 'หากออกจากหน้านี้ตอนนี้ ข้อมูลที่กรอกไว้จะหายไป ต้องการออกจากหน้านี้หรือไม่?',
  String stayLabel = 'อยู่ต่อ',
  String leaveLabel = 'ออกจากหน้านี้',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(stayLabel),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: TextButton.styleFrom(foregroundColor: AppColors.danger),
          child: Text(leaveLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

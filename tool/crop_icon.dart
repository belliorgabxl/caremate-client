// One-off tool: crop the icon mark out of assets/images/caremate-logo.png
// (which bundles the rounded-square mark above a "CareMate" wordmark),
// square it up with transparent padding, and write assets/images/app_icon.png
// for flutter_launcher_icons to consume. Run with `dart run tool/crop_icon.dart`.
import 'dart:io';

import 'package:image/image.dart' as img;

void main() {
  final src = img.decodePng(File('assets/images/caremate-logo.png').readAsBytesSync())!;

  bool rowHasContent(int y) {
    for (var x = 0; x < src.width; x++) {
      if (src.getPixel(x, y).a > 10) return true;
    }
    return false;
  }

  // Find the icon block: first content row, then the first long transparent
  // gap after it (the separator before the wordmark).
  var top = 0;
  while (top < src.height && !rowHasContent(top)) {
    top++;
  }

  var bottom = top;
  var gap = 0;
  for (var y = top; y < src.height; y++) {
    if (rowHasContent(y)) {
      gap = 0;
      bottom = y;
    } else {
      gap++;
      if (gap > 15 && bottom > top) break;
    }
  }

  var left = src.width, right = 0;
  for (var y = top; y <= bottom; y++) {
    for (var x = 0; x < src.width; x++) {
      if (src.getPixel(x, y).a > 10) {
        if (x < left) left = x;
        if (x > right) right = x;
      }
    }
  }

  final contentW = right - left + 1;
  final contentH = bottom - top + 1;
  final side = (contentW > contentH ? contentW : contentH);
  // Small safe-zone padding so adaptive-icon masks don't clip the mark.
  final canvas = (side * 1.12).round();

  final square = img.Image(width: canvas, height: canvas, numChannels: 4);
  img.fill(square, color: img.ColorRgba8(0, 0, 0, 0));

  final cropped = img.copyCrop(src, x: left, y: top, width: contentW, height: contentH);
  final dstX = ((canvas - contentW) / 2).round();
  final dstY = ((canvas - contentH) / 2).round();
  img.compositeImage(square, cropped, dstX: dstX, dstY: dstY);

  File('assets/images/app_icon.png').writeAsBytesSync(img.encodePng(square));

  stdout.writeln('source: ${src.width}x${src.height}');
  stdout.writeln('icon block: top=$top bottom=$bottom left=$left right=$right (${contentW}x$contentH)');
  stdout.writeln('wrote assets/images/app_icon.png at ${canvas}x$canvas');
}

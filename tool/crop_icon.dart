// Crops the square icon mark out of assets/images/caremate-logo.png
// (which also carries the "CareMate" wordmark below the mark), writing the
// result to assets/images/app_icon.png for flutter_launcher_icons.
//
// The mark and the wordmark are separated by a fully-transparent gap row;
// this scans for that gap to find the mark's bottom edge, then crops a
// square centered on the mark's horizontal content, so it stays correct if
// the source logo is ever re-exported at a different size/padding.
//
// Run with: dart run tool/crop_icon.dart

import 'dart:io';

import 'package:image/image.dart' as img;

void main() {
  const sourcePath = 'assets/images/caremate-logo.png';
  const outputPath = 'assets/images/app_icon.png';

  final source = img.decodePng(File(sourcePath).readAsBytesSync());
  if (source == null) {
    stderr.writeln('Could not decode $sourcePath');
    exit(1);
  }

  bool rowHasContent(int y) {
    for (int x = 0; x < source.width; x++) {
      if (source.getPixel(x, y).a > 10) return true;
    }
    return false;
  }

  int? markBottom;
  bool sawContent = false;
  for (int y = 0; y < source.height; y++) {
    final hasContent = rowHasContent(y);
    if (hasContent) {
      sawContent = true;
    } else if (sawContent) {
      markBottom = y;
      break;
    }
  }
  markBottom ??= source.height;

  int minX = source.width, maxX = 0;
  for (int y = 0; y < markBottom; y++) {
    for (int x = 0; x < source.width; x++) {
      if (source.getPixel(x, y).a > 10) {
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
      }
    }
  }

  final side = markBottom;
  final centerX = (minX + maxX) ~/ 2;
  var x = centerX - side ~/ 2;
  if (x < 0) x = 0;
  if (x + side > source.width) x = source.width - side;

  final cropped = img.copyCrop(source, x: x, y: 0, width: side, height: side);

  File(outputPath).writeAsBytesSync(img.encodePng(cropped));
  stdout.writeln('Wrote $outputPath (${cropped.width}x${cropped.height})');
}

// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';

Future<Uint8List> compressImageBytesImpl(
  Uint8List bytes, {
  int maxDimension = 900,
  num quality = 0.78,
}) async {
  if (bytes.lengthInBytes < 120 * 1024) return bytes;
  try {
    final blob = html.Blob([bytes]);
    final objectUrl = html.Url.createObjectUrlFromBlob(blob);
    final imgElement = html.ImageElement()..src = objectUrl;
    await imgElement.onLoad.first.timeout(const Duration(seconds: 4));

    int width = imgElement.naturalWidth;
    int height = imgElement.naturalHeight;
    if (width <= 0 || height <= 0) return bytes;

    if (width > maxDimension || height > maxDimension) {
      if (width >= height) {
        height = (height * maxDimension / width).round();
        width = maxDimension;
      } else {
        width = (width * maxDimension / height).round();
        height = maxDimension;
      }
    }

    final canvas = html.CanvasElement(width: width, height: height);
    final ctx = canvas.context2D;
    ctx.drawImageScaled(imgElement, 0, 0, width, height);
    html.Url.revokeObjectUrl(objectUrl);

    final dataUrl = canvas.toDataUrl('image/jpeg', quality);
    final commaIndex = dataUrl.indexOf(',');
    if (commaIndex != -1) {
      return base64Decode(dataUrl.substring(commaIndex + 1));
    }
  } catch (_) {}
  return bytes;
}

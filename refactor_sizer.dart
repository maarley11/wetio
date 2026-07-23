import 'dart:io';

void main() {
  final dir = Directory('C:/wetio/lib');
  if (!dir.existsSync()) {
    print('Directory not found');
    return;
  }

  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));
  int totalChanges = 0;

  for (final file in files) {
    String content = file.readAsStringSync();
    String original = content;

    // Replace .w
    content = content.replaceAllMapped(RegExp(r'(?<=[^\w\.])(\d+(?:\.\d+)?)\.w\b'), (match) {
      double val = double.parse(match.group(1)!);
      if (val < 50) {
        return (val * 4.0).toStringAsFixed(1);
      }
      return match.group(0)!; // Keep the original for >= 50
    });

    // Replace .h
    content = content.replaceAllMapped(RegExp(r'(?<=[^\w\.])(\d+(?:\.\d+)?)\.h\b'), (match) {
      double val = double.parse(match.group(1)!);
      if (val < 50) {
        return (val * 8.5).toStringAsFixed(1);
      }
      return match.group(0)!; // Keep the original for >= 50
    });

    if (content != original) {
      file.writeAsStringSync(content);
      totalChanges++;
    }
  }

  print('Modified $totalChanges files.');
}

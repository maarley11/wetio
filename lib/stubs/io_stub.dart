// Stub for dart:io on Flutter Web
// Provides no-op implementations of File and Directory used in supabase_service.dart
// This file is used via conditional import (dart.library.html) in supabase_service.dart

class File {
  final String path;
  File(this.path);
  Future<File> writeAsString(String contents) async => this;
}

class Directory {
  final String path;
  Directory(this.path);
}

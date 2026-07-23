// Stub for path_provider on Flutter Web
// Provides no-op implementations used in supabase_service.dart

class Directory {
  final String path;
  Directory(this.path);
}

Future<Directory> getApplicationDocumentsDirectory() async {
  return Directory('');
}

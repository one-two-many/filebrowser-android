class FileEntry {
  final String name;
  final String path;
  final bool isDir;
  final int size;
  final DateTime modified;
  final String type;

  FileEntry({
    required this.name,
    required this.path,
    required this.isDir,
    required this.size,
    required this.modified,
    required this.type,
  });

  // FileBrowser Quantum doesn't include each item's own path in the
  // response, only the name — so we build it from the folder we asked for.
  factory FileEntry.fromJson(
    Map<String, dynamic> json, {
    required bool isDir,
    required String parentPath,
  }) {
    final name = json['name'] as String? ?? '';
    return FileEntry(
      name: name,
      path: joinPath(parentPath, name),
      isDir: isDir,
      size: (json['size'] as num?)?.toInt() ?? 0,
      modified:
          DateTime.tryParse(json['modified'] as String? ?? '') ??
          DateTime.now(),
      type: json['type'] as String? ?? '',
    );
  }

}

String joinPath(String parent, String name) {
  if (parent.isEmpty || parent == '/') return '/$name';
  return '$parent/$name';
}

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

  factory FileEntry.fromJson(Map<String, dynamic> json) {
    return FileEntry(
      name: json['name'] as String? ?? '',
      path: json['path'] as String? ?? '',
      isDir: json['isDir'] as bool? ?? false,
      size: (json['size'] as num?)?.toInt() ?? 0,
      modified: DateTime.tryParse(json['modified'] as String? ?? '') ?? DateTime.now(),
      type: json['type'] as String? ?? '',
    );
  }
}

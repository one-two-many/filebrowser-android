import 'package:flutter/material.dart';
import 'package:flutter_file_downloader/flutter_file_downloader.dart';

import '../models/file_entry.dart';
import '../widgets/nocturne_toast.dart';
import 'filebrowser_client.dart';

Future<void> downloadToDevice({
  required BuildContext context,
  required FileBrowserClient client,
  required FileEntry entry,
}) async {
  final fileName = entry.isDir ? '${entry.name}.zip' : entry.name;
  final authHeader = client.authHeader;

  await FileDownloader.downloadFile(
    url: client.downloadUrl(entry.path),
    name: fileName,
    headers: {'Authorization': ?authHeader},
    notificationType: NotificationType.all,
    onDownloadCompleted: (path) {
      if (context.mounted) {
        showNocturneToast(context, 'Downloaded "$fileName"');
      }
    },
    onDownloadError: (error) {
      if (context.mounted) {
        showNocturneToast(context, 'Download failed: $error', isError: true);
      }
    },
  );
}

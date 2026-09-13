import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../api/filebrowser_client.dart';
import '../models/file_entry.dart';
import '../theme/nocturne_colors.dart';
import '../utils/format.dart';
import 'nocturne_toast.dart';

Future<void> showUploadSheet(
  BuildContext context, {
  required FileBrowserClient client,
  required String targetPath,
  required String targetFolderName,
  required VoidCallback onUploaded,
}) {
  final controller = TextEditingController();
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      final colors = sheetContext.nocturne;
      PlatformFile? pickedFile;
      var submitting = false;

      return StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          Future<void> pickFile() async {
            final file = await FilePicker.pickFile();
            if (file == null) return;
            setSheetState(() {
              pickedFile = file;
              controller.text = file.name;
            });
          }

          Future<void> submit({bool override = false}) async {
            final file = pickedFile;
            if (file == null) return;
            final name = controller.text.trim().isEmpty ? file.name : controller.text.trim();
            setSheetState(() => submitting = true);
            final path = joinPath(targetPath, name);
            try {
              final bytes = await file.readAsBytes();
              await client.uploadFile(path, bytes, override: override);
              if (sheetContext.mounted) Navigator.of(sheetContext).pop();
              if (context.mounted) {
                showNocturneToast(context, 'Uploaded "$name"');
                onUploaded();
              }
            } on ResourceConflictException {
              setSheetState(() => submitting = false);
              if (!sheetContext.mounted) return;
              final replace = await showDialog<bool>(
                context: sheetContext,
                builder: (dialogContext) => AlertDialog(
                  title: Text('"$name" already exists'),
                  content: const Text('Replace it?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                      child: const Text('Replace'),
                    ),
                  ],
                ),
              );
              if (replace == true) {
                await submit(override: true);
              }
            } catch (e) {
              setSheetState(() => submitting = false);
              if (context.mounted) {
                showNocturneToast(context, 'Failed to upload: $e', isError: true);
              }
            }
          }

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
              ),
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 26),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Upload to $targetFolderName',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                      color: colors.text,
                    ),
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: submitting ? null : pickFile,
                    icon: const Icon(Icons.attach_file, size: 18),
                    label: Text(pickedFile == null ? 'Choose file' : 'Change file'),
                  ),
                  if (pickedFile != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      formatBytes(pickedFile!.lengthSync() ?? 0),
                      style: TextStyle(fontSize: 12, color: colors.mutedText(0.60)),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Text(
                    'File name',
                    style: TextStyle(fontSize: 12, color: colors.mutedText(0.70)),
                  ),
                  const SizedBox(height: 5),
                  TextField(
                    controller: controller,
                    enabled: !submitting,
                    decoration: const InputDecoration(hintText: 'New file'),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: submitting
                              ? null
                              : () => Navigator.of(sheetContext).pop(),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          onPressed: (submitting || pickedFile == null)
                              ? null
                              : () => submit(),
                          child: submitting
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Upload'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

import 'package:flutter/material.dart';

import '../api/filebrowser_client.dart';
import '../models/file_entry.dart';
import '../theme/nocturne_colors.dart';
import 'nocturne_toast.dart';

Future<void> showNewFolderSheet(
  BuildContext context, {
  required FileBrowserClient client,
  required String targetPath,
  required VoidCallback onCreated,
}) {
  final controller = TextEditingController();
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      final colors = sheetContext.nocturne;
      var submitting = false;

      Future<void> submit(StateSetter setSheetState, {bool override = false}) async {
        final name = controller.text.trim();
        if (name.isEmpty) return;
        setSheetState(() => submitting = true);
        final path = joinPath(targetPath, name);
        try {
          await client.createFolder(path, override: override);
          if (sheetContext.mounted) Navigator.of(sheetContext).pop();
          if (context.mounted) {
            showNocturneToast(context, 'Created "$name"');
            onCreated();
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
            await submit(setSheetState, override: true);
          }
        } catch (e) {
          setSheetState(() => submitting = false);
          if (context.mounted) {
            showNocturneToast(context, 'Failed to create folder: $e', isError: true);
          }
        }
      }

      return StatefulBuilder(
        builder: (sheetContext, setSheetState) {
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
                    'New folder',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                      color: colors.text,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Folder name',
                    style: TextStyle(fontSize: 12, color: colors.mutedText(0.70)),
                  ),
                  const SizedBox(height: 5),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    enabled: !submitting,
                    decoration: const InputDecoration(hintText: 'Untitled folder'),
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
                          onPressed: submitting ? null : () => submit(setSheetState),
                          child: submitting
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Create'),
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

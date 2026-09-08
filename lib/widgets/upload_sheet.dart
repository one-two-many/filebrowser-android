import 'package:flutter/material.dart';

import '../theme/nocturne_colors.dart';
import 'nocturne_toast.dart';

Future<void> showUploadSheet(BuildContext context, {required String targetFolderName}) {
  final controller = TextEditingController();
  final selectedType = ValueNotifier<String>('PDF');
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      final colors = sheetContext.nocturne;
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
              Text(
                'File name',
                style: TextStyle(fontSize: 12, color: colors.mutedText(0.70)),
              ),
              const SizedBox(height: 5),
              TextField(
                controller: controller,
                decoration: const InputDecoration(hintText: 'New file'),
              ),
              const SizedBox(height: 14),
              Text(
                'Type',
                style: TextStyle(fontSize: 12, color: colors.mutedText(0.70)),
              ),
              const SizedBox(height: 5),
              ValueListenableBuilder<String>(
                valueListenable: selectedType,
                builder: (context, selected, _) {
                  return Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: colors.divider),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        for (final option in const ['PDF', 'Photo', 'Doc'])
                          Expanded(
                            child: _SegmentOption(
                              label: option,
                              selected: option == selected,
                              onTap: () => selectedType.value = option,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        showNocturneToast(context, 'Not implemented yet');
                      },
                      child: const Text('Upload'),
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
}

class _SegmentOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SegmentOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.nocturne;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: selected ? Border.all(color: colors.accent) : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: selected ? colors.accent : colors.text,
          ),
        ),
      ),
    );
  }
}

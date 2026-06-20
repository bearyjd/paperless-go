import 'package:flutter/material.dart';

import '../../core/models/tag.dart';
import 'tag_chip.dart';

/// Bottom-sheet tag picker with live search.
///
/// Shared by the document detail screen and the upload screen. Calls
/// [onSelected] with the chosen tag; the caller is responsible for dismissing
/// the sheet and applying the selection.
class TagPickerSheet extends StatefulWidget {
  final List<Tag> tags;
  final ValueChanged<Tag> onSelected;

  const TagPickerSheet({
    super.key,
    required this.tags,
    required this.onSelected,
  });

  @override
  State<TagPickerSheet> createState() => _TagPickerSheetState();
}

class _TagPickerSheetState extends State<TagPickerSheet> {
  String _filter = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.tags
        .where((t) => t.name.toLowerCase().contains(_filter.toLowerCase()))
        .toList();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.5,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search tags...',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (v) => setState(() => _filter = v),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (_, i) {
                  final tag = filtered[i];
                  return ListTile(
                    leading: CircleAvatar(
                      radius: 12,
                      backgroundColor: TagChip.parseColor(tag.colour) ??
                          Theme.of(context).colorScheme.secondaryContainer,
                    ),
                    title: Text(tag.name),
                    onTap: () => widget.onSelected(tag),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

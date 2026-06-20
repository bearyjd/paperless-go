import 'package:flutter/material.dart';

/// Labeled dropdown for selecting an optional metadata value (correspondent,
/// document type, storage path, ...).
///
/// Generic over the item type [T]; the selection and [items] are objects (look
/// them up by id at the call site if your state stores ids). A leading "None"
/// entry represents the null selection.
///
/// Shared by the document detail, inbox quick-assign, and upload screens.
class MetadataDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<T> items;
  final String Function(T) displayName;

  /// Selection handler. When null the dropdown is disabled (e.g. mid-upload).
  final ValueChanged<T?>? onChanged;

  /// Optional decoration suffix, e.g. an "AI suggested" badge.
  final Widget? suffix;

  const MetadataDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.displayName,
    required this.onChanged,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    // Guard: if value is not in items, treat as null to avoid assertion error.
    final effectiveValue =
        (value != null && items.contains(value)) ? value : null;

    return Row(
      children: [
        Expanded(
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: label,
              border: const OutlineInputBorder(),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              suffix: suffix,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: effectiveValue,
                isExpanded: true,
                isDense: true,
                hint: const Text('None'),
                items: [
                  DropdownMenuItem<T>(value: null, child: const Text('None')),
                  ...items.map((item) => DropdownMenuItem<T>(
                        value: item,
                        child: Text(displayName(item),
                            overflow: TextOverflow.ellipsis),
                      )),
                ],
                onChanged: onChanged,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

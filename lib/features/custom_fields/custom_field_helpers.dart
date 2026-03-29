import 'package:flutter/material.dart';

String dataTypeLabel(String dataType) {
  return switch (dataType) {
    'string' => 'Text',
    'url' => 'URL',
    'date' => 'Date',
    'boolean' => 'Boolean',
    'integer' => 'Integer',
    'float' => 'Float',
    'monetary' => 'Monetary',
    'document_link' => 'Document Link',
    'select' => 'Select',
    _ => dataType,
  };
}

IconData dataTypeIcon(String dataType) {
  return switch (dataType) {
    'string' => Icons.text_fields,
    'url' => Icons.link,
    'date' => Icons.calendar_today,
    'boolean' => Icons.toggle_on_outlined,
    'integer' => Icons.numbers,
    'float' => Icons.data_usage,
    'monetary' => Icons.attach_money,
    'document_link' => Icons.description_outlined,
    'select' => Icons.list,
    _ => Icons.extension,
  };
}

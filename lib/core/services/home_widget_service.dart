import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

class HomeWidgetService {
  static Future<void> updateDocCount(int count) async {
    try {
      await HomeWidget.saveWidgetData('doc_count', count.toString());
      await HomeWidget.updateWidget(
        name: 'PaperlessWidget',
        androidName: 'com.ventoux.paperlessgo.PaperlessWidget',
      );
    } catch (e) {
      debugPrint('Failed to update home widget: $e');
    }
  }
}

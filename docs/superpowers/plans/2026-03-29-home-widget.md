# Android Home Screen Widget Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add an Android home screen widget with a "Quick Upload" button that opens the camera scanner or file picker directly, plus a stats display showing document count.

**Architecture:** Uses the `home_widget` Flutter package for widget registration and data sharing. Native Kotlin `AppWidgetProvider` renders the widget layout. Tapping the upload button launches the Flutter app directly to the scanner screen via a deep link.

**Tech Stack:** `home_widget` package, Kotlin `AppWidgetProvider`, Android XML layouts, deep links

---

## Task 1 — Add `home_widget` dependency + native widget setup

**Files:**
- Modify: `pubspec.yaml` — add `home_widget: ^0.7.0`
- Create: `android/app/src/main/kotlin/com/ventoux/paperlessgo/PaperlessWidget.kt`
- Create: `android/app/src/main/res/layout/paperless_widget.xml`
- Create: `android/app/src/main/res/xml/paperless_widget_info.xml`
- Modify: `android/app/src/main/AndroidManifest.xml` — register widget receiver

- [ ] **Step 1: Add dependency**

```yaml
home_widget: ^0.7.0
```

- [ ] **Step 2: Create widget XML layout**

`android/app/src/main/res/layout/paperless_widget.xml`:
```xml
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:orientation="vertical"
    android:padding="16dp"
    android:background="@android:color/white">

    <TextView
        android:id="@+id/tv_title"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:text="Paperless Go"
        android:textSize="16sp"
        android:textStyle="bold" />

    <TextView
        android:id="@+id/tv_doc_count"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:text="-- documents"
        android:textSize="14sp" />

    <Button
        android:id="@+id/btn_scan"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:layout_marginTop="8dp"
        android:text="Quick Scan" />

    <Button
        android:id="@+id/btn_upload"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:text="Upload File" />
</LinearLayout>
```

- [ ] **Step 3: Create widget info XML**

`android/app/src/main/res/xml/paperless_widget_info.xml`:
```xml
<?xml version="1.0" encoding="utf-8"?>
<appwidget-provider xmlns:android="http://schemas.android.com/apk/res/android"
    android:initialLayout="@layout/paperless_widget"
    android:minWidth="180dp"
    android:minHeight="110dp"
    android:resizeMode="horizontal|vertical"
    android:updatePeriodMillis="3600000"
    android:widgetCategory="home_screen" />
```

- [ ] **Step 4: Create `PaperlessWidget.kt`**

```kotlin
package com.ventoux.paperlessgo

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class PaperlessWidget : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.paperless_widget)
            val docCount = widgetData.getString("doc_count", "--") ?: "--"
            views.setTextViewText(R.id.tv_doc_count, "$docCount documents")

            // Set up click intents for scan and upload buttons
            views.setOnClickPendingIntent(
                R.id.btn_scan,
                HomeWidgetProvider.getUriPendingIntent(context, Uri.parse("paperlessgo://scan"))
            )
            views.setOnClickPendingIntent(
                R.id.btn_upload,
                HomeWidgetProvider.getUriPendingIntent(context, Uri.parse("paperlessgo://upload"))
            )

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
```

- [ ] **Step 5: Register in AndroidManifest.xml**

Add inside `<application>`:
```xml
<receiver android:name=".PaperlessWidget"
    android:exported="true">
    <intent-filter>
        <action android:name="android.appwidget.action.APPWIDGET_UPDATE" />
    </intent-filter>
    <meta-data
        android:name="android.appwidget.provider"
        android:resource="@xml/paperless_widget_info" />
</receiver>
```

- [ ] **Step 6: Run analysis, commit**

---

## Task 2 — Dart-side widget data updates

**Files:**
- Create: `lib/core/services/home_widget_service.dart`

- [ ] **Step 1: Create service that pushes data to widget**

```dart
import 'package:home_widget/home_widget.dart';

class HomeWidgetService {
  static Future<void> updateDocCount(int count) async {
    await HomeWidget.saveWidgetData('doc_count', count.toString());
    await HomeWidget.updateWidget(name: 'PaperlessWidget');
  }
}
```

- [ ] **Step 2: Call from dashboard provider after stats fetch**

In `dashboard_statistics.dart` notifier `build()`, after fetching stats, call `HomeWidgetService.updateDocCount(stats.documentsTotal)`.

- [ ] **Step 3: Handle deep link URIs in `app.dart`**

Handle `paperlessgo://scan` and `paperlessgo://upload` URIs in the GoRouter redirect to navigate to the scanner or file picker.

- [ ] **Step 4: Run analysis and tests, commit**

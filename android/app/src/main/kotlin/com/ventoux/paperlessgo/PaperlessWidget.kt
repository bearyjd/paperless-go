package com.ventoux.paperlessgo

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
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

            views.setOnClickPendingIntent(
                R.id.btn_scan,
                HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("paperlessgo://scan")
                )
            )
            views.setOnClickPendingIntent(
                R.id.btn_upload,
                HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("paperlessgo://upload")
                )
            )

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}

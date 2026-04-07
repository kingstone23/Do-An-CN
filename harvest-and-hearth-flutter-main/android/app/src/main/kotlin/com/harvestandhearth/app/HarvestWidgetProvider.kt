package com.harvestandhearth.app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class HarvestWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: android.content.SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.harvest_widget).apply {
                val expiringCount = widgetData.getString("expiring_count", null)
                val line1 = widgetData.getString("line1", "") ?: ""

                setImageViewResource(R.id.widget_app_icon, R.mipmap.ic_launcher)
                setTextViewText(R.id.widget_title, "Harvest & Hearth")

                val subtitle = widgetData.getString("subtitle", "") ?: ""
                if (subtitle.isNotBlank()) {
                    setTextViewText(R.id.widget_subtitle, subtitle)
                    setViewVisibility(R.id.widget_subtitle, View.VISIBLE)
                } else {
                    setViewVisibility(R.id.widget_subtitle, View.GONE)
                }

                if (expiringCount == null && line1.isNotBlank()) {
                    setViewVisibility(R.id.widget_stats_row, View.GONE)
                    setViewVisibility(R.id.widget_legacy_line1, View.VISIBLE)
                    setTextViewText(R.id.widget_legacy_line1, line1)
                } else {
                    setViewVisibility(R.id.widget_legacy_line1, View.GONE)
                    setViewVisibility(R.id.widget_stats_row, View.VISIBLE)
                    setTextViewText(
                        R.id.widget_expiring_label,
                        widgetData.getString("label_expiring", "")?.takeIf { it.isNotBlank() }
                            ?: context.getString(R.string.widget_fallback_expiring),
                    )
                    setTextViewText(
                        R.id.widget_expiring_value,
                        expiringCount ?: "0",
                    )
                    setTextViewText(
                        R.id.widget_expired_label,
                        widgetData.getString("label_expired", "")?.takeIf { it.isNotBlank() }
                            ?: context.getString(R.string.widget_fallback_expired),
                    )
                    setTextViewText(
                        R.id.widget_expired_value,
                        widgetData.getString("expired_count", "0") ?: "0",
                    )
                }

                setTextViewText(
                    R.id.widget_line2,
                    widgetData.getString("line2", "") ?: "",
                )
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}

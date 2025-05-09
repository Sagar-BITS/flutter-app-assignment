import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_item.dart';

class NotificationService {
  static const String _storageKey = 'notifications';
  static final List<NotificationItem> _notifications = [];
  static final ValueNotifier<int> notificationCount = ValueNotifier<int>(0);

  static Future<void> _loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final String? storedNotifications = prefs.getString(_storageKey);
    
    if (storedNotifications != null) {
      final List<dynamic> decoded = json.decode(storedNotifications);
      _notifications.clear();
      _notifications.addAll(
        decoded
            .map((item) => NotificationItem.fromJson(item))
            .where((notification) =>
                notification.timestamp.isAfter(
                  DateTime.now().subtract(const Duration(days: 1)),
                ))
            .toList(),
      );
      notificationCount.value = _notifications.length;
    }
  }

  static Future<void> _saveNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = json.encode(
      _notifications
          .where((notification) =>
              notification.timestamp.isAfter(
                DateTime.now().subtract(const Duration(days: 1)),
              ))
          .map((notification) => notification.toJson())
          .toList(),
    );
    await prefs.setString(_storageKey, encoded);
    notificationCount.value = _notifications.length;
  }

  static List<NotificationItem> getNotifications() {
    return _notifications
        .where((notification) =>
            notification.timestamp.isAfter(
              DateTime.now().subtract(const Duration(days: 1)),
            ))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  static void showNotification(
    BuildContext context, {
    required String message,
    bool isSuccess = true,
  }) {
    // Store the notification
    _notifications.add(NotificationItem(
      message: message,
      isSuccess: isSuccess,
      timestamp: DateTime.now(),
    ));
    _saveNotifications();

    // Show the overlay notification
    final overlayState = Overlay.of(context);
    OverlayEntry? overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: MediaQuery.of(context).padding.bottom + 16,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 50 * (1 - value)),
                child: Opacity(opacity: value, child: child),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: isSuccess ? Colors.green.shade600 : Colors.red.shade600,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: (isSuccess ? Colors.green : Colors.red)
                        .withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    isSuccess ? Icons.check_circle : Icons.error,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => overlayEntry?.remove(),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white70,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlayState.insert(overlayEntry);

    Future.delayed(const Duration(seconds: 2), () {
      if (overlayEntry?.mounted ?? false) {
        overlayEntry?.remove();
      }
    });
  }

  static Future<void> init() async {
    await _loadNotifications();
  }
}


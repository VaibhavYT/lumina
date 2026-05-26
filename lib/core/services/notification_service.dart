import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lumina/core/extensions/context_extensions.dart';
import 'package:lumina/core/services/device_identity_service.dart';
import 'package:lumina/core/services/edge_function_client.dart';
import 'package:lumina/core/services/supabase_status.dart';
import 'package:lumina/router/app_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LuminaNotification {
  const LuminaNotification({
    required this.title,
    required this.body,
    required this.data,
  });

  final String title;
  final String body;
  final Map<String, dynamic> data;
}

class NotificationService {
  NotificationService._();

  static final currentNotification = ValueNotifier<LuminaNotification?>(null);
  static Timer? _hideTimer;

  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      final token = await messaging.getToken();
      await _registerToken(token);
      FirebaseMessaging.instance.onTokenRefresh.listen(_registerToken);
      if (SupabaseStatus.isInitialized) {
        Supabase.instance.client.auth.onAuthStateChange.listen((state) {
          if (state.session != null) {
            _registerToken(token);
          }
        });
      }

      FirebaseMessaging.onMessage.listen((message) {
        _showInApp(message);
      });
      FirebaseMessaging.onMessageOpenedApp.listen(_navigateFromMessage);
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _navigateFromMessage(initialMessage);
        });
      }
    } on Object catch (error) {
      debugPrint('Lumina notifications skipped: $error');
    }
  }

  static Future<void> _registerToken(String? token) async {
    if (token == null || token.isEmpty) {
      return;
    }
    try {
      final deviceId = await DeviceIdentityService().getDeviceId();
      await EdgeFunctionClient().invoke(
        'sync-daily-log',
        payload: {
          'deviceId': deviceId,
          'profile': {'device_id': deviceId, 'fcm_token': token},
        },
        headers: {'x-device-id': deviceId},
      );
    } on Object catch (error) {
      debugPrint('Lumina FCM token registration failed: $error');
    }
  }

  static void _showInApp(RemoteMessage message) {
    final notification = message.notification;
    currentNotification.value = LuminaNotification(
      title: notification?.title ?? 'Lumina',
      body: notification?.body ?? '',
      data: message.data,
    );
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      currentNotification.value = null;
    });
  }

  static void _navigateFromMessage(RemoteMessage message) {
    final context = rootNavigatorKey.currentContext;
    if (context == null) {
      return;
    }
    _navigateToData(context, message.data);
  }

  static void navigateToNotification(
    BuildContext context,
    LuminaNotification notification,
  ) {
    currentNotification.value = null;
    _navigateToData(context, notification.data);
  }

  static void _navigateToData(BuildContext context, Map<String, dynamic> data) {
    final screen = data['screen'] as String?;
    switch (screen) {
      case 'mentor':
        context.go('/mentor');
        return;
      case 'insights':
        context.go('/insights');
        return;
      case 'log':
        context.go('/log');
        return;
      default:
        context.go('/dashboard');
    }
  }
}

class NotificationBannerHost extends StatelessWidget {
  const NotificationBannerHost({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        ValueListenableBuilder<LuminaNotification?>(
          valueListenable: NotificationService.currentNotification,
          builder: (context, notification, _) {
            return AnimatedPositioned(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              left: 16,
              right: 16,
              top: notification == null ? -120 : 12,
              child: SafeArea(
                child: notification == null
                    ? const SizedBox.shrink()
                    : _NotificationBanner(notification: notification),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _NotificationBanner extends StatelessWidget {
  const _NotificationBanner({required this.notification});

  final LuminaNotification notification;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: () =>
          NotificationService.navigateToNotification(context, notification),
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.backgroundElevated,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.divider),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: context.isDark ? 0.3 : 0.12,
                ),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: colors.primaryAccent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: context.textTheme.labelLarge,
                    ),
                    if (notification.body.isNotEmpty)
                      Text(
                        notification.body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

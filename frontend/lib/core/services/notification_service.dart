import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Servicio Central de Notificaciones (Locales y push remotas FCM)
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _isLocalInitialized = false;
  bool _isFirebaseInitialized = false;
  String? _fcmToken;

  String? get fcmToken => _fcmToken;
  bool get isLocalInitialized => _isLocalInitialized;
  bool get isFirebaseInitialized => _isFirebaseInitialized;

  /// 1. Inicialización de Notificaciones Locales (En el dispositivo)
  Future<void> initializeLocalNotifications() async {
    if (_isLocalInitialized) return;

    try {
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidSettings);

      await _localNotifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse details) {
          debugPrint('Notificación tocada: ${details.payload}');
        },
      );

      // Solicitar permisos en Android 13+
      final androidPlatform = _localNotifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlatform != null) {
        await androidPlatform.requestNotificationsPermission();
      }

      _isLocalInitialized = true;
      debugPrint('Notificaciones Locales de Kpital inicializadas.');
    } catch (e) {
      debugPrint('Error inicializando notificaciones locales: $e');
    }
  }

  /// 2. Disparar Notificación Local genérica
  Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String channelId = 'kpital_general',
    String channelName = 'General Kpital',
  }) async {
    try {
      final androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: const Color(0xFF8261B8),
        styleInformation: BigTextStyleInformation(body),
      );

      final details = NotificationDetails(android: androidDetails);
      await _localNotifications.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: details,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Error mostrando notificación local: $e');
    }
  }

  /// 3. Recordatorio Diario de Finanzas (Inciso A)
  Future<void> showDailyFinanceReminder({String userName = 'Madeline'}) async {
    await showLocalNotification(
      id: 101,
      title: '⏰ Cierre de Balance Diario',
      body: '$userName, son las 8:00 PM. No olvides registrar tus ventas, cobros y gastos de hoy en Kpital.',
      channelId: 'kpital_daily',
      channelName: 'Recordatorios Diarios',
      payload: 'daily_reminder',
    );
  }

  /// 4. Alerta de Vencimiento de Deuda o Cobro (Inciso A)
  Future<void> showDebtDueReminder({
    required String personName,
    required double amount,
    bool isReceivable = true,
  }) async {
    final title = isReceivable ? '💼 Cobranza Pendiente' : '💳 Pago por Realizar';
    final body = isReceivable
        ? 'Mañana vence el plazo para cobrar Bs ${amount.toStringAsFixed(2)} a $personName.'
        : 'Recuerda que mañana vence tu cuota de Bs ${amount.toStringAsFixed(2)} con $personName.';

    await showLocalNotification(
      id: 202,
      title: title,
      body: body,
      channelId: 'kpital_debts',
      channelName: 'Cobranzas y Deudas',
      payload: 'debt_reminder',
    );
  }

  /// 6. Inicialización de Firebase Cloud Messaging (Inciso B - Remotas)
  Future<void> initializeFirebase() async {
    try {
      await Firebase.initializeApp();
      final messaging = FirebaseMessaging.instance;

      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        _fcmToken = await messaging.getToken();

        // Notificar en primer plano cuando llegue push remota
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          if (message.notification != null) {
            showLocalNotification(
              id: message.hashCode,
              title: message.notification!.title ?? 'Kpital',
              body: message.notification!.body ?? '',
              payload: message.data.toString(),
            );
          }
        });

        _isFirebaseInitialized = true;
      }
    } catch (e) {
      debugPrint('Firebase no configurado aún (coloca google-services.json para push remotas): $e');
    }
  }

}

import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../../firebase_options.dart';

/// Handler de mensajes en background — debe ser una función top-level.
/// Se marca con @pragma('vm:entry-point') para que no sea eliminada por tree-shaking.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Asegurar que Firebase esté inicializado en el isolate de background
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Aquí puedes loguear o guardar el mensaje si lo necesitas
  // Los mensajes con notification payload se muestran automáticamente por FCM
}

/// Handler para taps en notificaciones locales cuando la app está en background.
@pragma('vm:entry-point')
void notificationTapBackgroundHandler(NotificationResponse details) {
  NotificationService.handleNotificationPayload(details.payload);
}

/// Plugin global de notificaciones locales
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// Canal de Android para notificaciones de gastos compartidos
const AndroidNotificationChannel _expensesChannel = AndroidNotificationChannel(
  'expenses',        // id del canal
  'Gastos compartidos', // nombre visible
  description: 'Notificaciones de gastos y espacios compartidos',
  importance: Importance.high,
);

const AndroidNotificationChannel _billsChannel = AndroidNotificationChannel(
  'bills',
  'Pagos recurrentes',
  description: 'Recordatorios locales de pagos recurrentes',
  importance: Importance.high,
);

/// Servicio centralizado de notificaciones push (FCM) y locales.
class NotificationService {
  const NotificationService();

  /// Inicializa Firebase, solicita permisos, registra el token FCM en
  /// Supabase y configura los listeners de mensajes.
  Future<void> initialize() async {
    // 1. Inicializar Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // 2. Registrar el handler de background ANTES de cualquier otra cosa
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 3. Solicitar permisos de notificación (iOS / Android 13+)
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 4. Configurar flutter_local_notifications
    await _configurarZonaHoraria();
    await _configurarNotificacionesLocales();

    // 5. Obtener y guardar token FCM en Supabase
    await _registrarTokenFCM();

    // 6. Escuchar actualización de token
    FirebaseMessaging.instance.onTokenRefresh.listen((nuevoToken) async {
      await _guardarTokenEnSupabase(nuevoToken);
    });

    // 7. Escuchar mensajes en foreground → mostrar notificación local
    FirebaseMessaging.onMessage.listen(_mostrarNotificacionLocal);

    // 8. Mensaje abierto desde background (onMessageOpenedApp)
    FirebaseMessaging.onMessageOpenedApp.listen(_manejarTapNotificacion);

    // 9. Revisar si la app se abrió desde una notificación terminada
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _manejarTapNotificacion(initialMessage);
    }
  }

  static Future<void> init() async {
    await const NotificationService().initialize();
  }

  // ─── Helpers privados ────────────────────────────────────────────────────

  /// Configura el canal de Android y la inicialización del plugin local.
  static Future<void> _configurarNotificacionesLocales() async {
    // Crear canal en Android
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_expensesChannel);
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_billsChannel);

    // Configuración de inicialización
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: darwinInit,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
      onDidReceiveBackgroundNotificationResponse:
          notificationTapBackgroundHandler,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// Inicializa la zona horaria local para programar recordatorios exactos.
  static Future<void> _configurarZonaHoraria() async {
    tz.initializeTimeZones();
    final timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));
  }

  /// Obtiene el token FCM y lo guarda (o actualiza) en la tabla push_tokens.
  static Future<void> _registrarTokenFCM() async {
    try {
      // En iOS/macOS se necesita el token APNS primero
      if (Platform.isIOS || Platform.isMacOS) {
        await FirebaseMessaging.instance.getAPNSToken();
      }
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _guardarTokenEnSupabase(token);
      }
    } catch (e) {
      // Silenciar errores en el registro del token para no bloquear el inicio
    }
  }

  /// Inserta o actualiza el token FCM del usuario en Supabase.
  static Future<void> _guardarTokenEnSupabase(String token) async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return; // Sin sesión, no guardar

    final plataforma = Platform.isIOS ? 'ios' : 'android';

    try {
      // Intentar obtener registro existente
      final existing = await supabase
          .from('push_tokens')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();

      if (existing != null) {
        // Actualizar token existente
        await supabase
            .from('push_tokens')
            .update({'token': token, 'platform': plataforma})
            .eq('user_id', userId);
      } else {
        // Insertar nuevo token
        await supabase.from('push_tokens').insert({
          'user_id': userId,
          'token': token,
          'platform': plataforma,
        });
      }
    } catch (_) {
      // Silenciar errores para no bloquear el flujo de autenticación
    }
  }

  /// Muestra una notificación local cuando la app está en foreground.
  static void _mostrarNotificacionLocal(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _expensesChannel.id,
          _expensesChannel.name,
          channelDescription: _expensesChannel.description,
          icon: '@mipmap/ic_launcher',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: _encodePayload(message.data),
    );
  }

  /// Procesa taps en notificaciones locales cuando la app está activa.
  static void _onDidReceiveNotificationResponse(
    NotificationResponse details,
  ) {
    handleNotificationPayload(details.payload);
  }

  /// Determina la ruta destino al abrir una notificación.
  static void _manejarTapNotificacion(RemoteMessage message) {
    _pendingNavigationData = message.data;
  }

  static void handleNotificationPayload(String? payload) {
    if (payload == null || payload.isEmpty) return;
    if (payload.startsWith('bill_')) {
      _pendingNavigationData = {'screen': 'bills'};
      return;
    }
    _pendingNavigationData = _decodePayload(payload);
  }

  static String _encodePayload(Map<String, dynamic> data) {
    return data.entries.map((entry) => '${entry.key}=${entry.value}').join('&');
  }

  static Map<String, dynamic> _decodePayload(String payload) {
    final Map<String, dynamic> result = {};
    for (final segment in payload.split('&')) {
      if (segment.isEmpty) continue;
      final separator = segment.indexOf('=');
      if (separator == -1) continue;
      final key = segment.substring(0, separator);
      final value = segment.substring(separator + 1);
      result[key] = value;
    }
    return result;
  }

  /// Datos de navegación pendiente (para procesar después de que el router esté listo).
  static Map<String, dynamic>? _pendingNavigationData;

  /// Devuelve y limpia los datos de navegación pendiente.
  static Map<String, dynamic>? consumePendingNavigationData() {
    final data = _pendingNavigationData;
    _pendingNavigationData = null;
    return data;
  }
}

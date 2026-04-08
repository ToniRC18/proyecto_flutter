import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// Importa el archivo generado por FlutterFire CLI (debes ejecutar `flutterfire configure` primero)
// import '../../firebase_options.dart';

/// Handler de mensajes en background — debe ser una función top-level.
/// Se marca con @pragma('vm:entry-point') para que no sea eliminada por tree-shaking.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Asegurar que Firebase esté inicializado en el isolate de background
  await Firebase.initializeApp(
    // options: DefaultFirebaseOptions.currentPlatform,
  );
  // Aquí puedes loguear o guardar el mensaje si lo necesitas
  // Los mensajes con notification payload se muestran automáticamente por FCM
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

/// Servicio centralizado de notificaciones push (FCM) y locales.
class NotificationService {
  /// Inicializa Firebase, solicita permisos, registra el token FCM en
  /// Supabase y configura los listeners de mensajes.
  static Future<void> init() async {
    // 1. Inicializar Firebase
    await Firebase.initializeApp(
      // Descomenta la línea siguiente después de ejecutar `flutterfire configure`
      // options: DefaultFirebaseOptions.currentPlatform,
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

  // ─── Helpers privados ────────────────────────────────────────────────────

  /// Configura el canal de Android y la inicialización del plugin local.
  static Future<void> _configurarNotificacionesLocales() async {
    // Crear canal en Android
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_expensesChannel);

    // Configuración de inicialización
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: darwinInit,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        // Maneja tap en notificación local cuando la app está en foreground
        // El routeo se hace desde NotificationHandler
      },
    );
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
      payload: message.data.toString(),
    );
  }

  /// Determina la ruta destino al abrir una notificación.
  static void _manejarTapNotificacion(RemoteMessage message) {
    // El routeo real lo realiza NotificationHandler usando el contexto del navegador.
    // Aquí guardamos el payload para que NotificationHandler lo procese.
    _pendingNavigationData = message.data;
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

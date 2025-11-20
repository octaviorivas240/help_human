import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:home_widget/home_widget.dart';
import 'package:workmanager/workmanager.dart';
import 'package:overlay_support/overlay_support.dart';

import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';
import 'services/storage_service.dart';
import 'services/call_simulator.dart';
import 'services/fall_detection_service.dart';
import 'services/volume_panic_service.dart';
import 'services/shake_panic_service.dart';
import 'services/location_service.dart'; // ← AÑADIDO
import 'services/sms_service.dart'; // ← AÑADIDO
import 'services/whatsapp_service.dart'; // ← AÑADIDO
import 'services/siren_service.dart'; // ← Sirena + flash (opcional)

// CLAVE GLOBAL
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// ===========================================================================
// WORKMANAGER: Llamada falsa
// ===========================================================================
@pragma("vm:entry-point")
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == "fake_call_task") {
      await CallSimulator.simulateIncomingCall();
    }
    return Future.value(true);
  });
}

// ===========================================================================
// WIDGET DE PÁNICO EN PANTALLA DE INICIO
// ===========================================================================
@pragma("vm:entry-point")
Future<void> panicWidgetCallback(Uri? uri) async {
  if (uri?.host != 'panic_widget') return;

  final userData = await StorageService.getUserData();
  if (userData == null) return;

  final locationLink = await LocationService.getCurrentLocationLink();

  await SmsService.sendPanicSms(userData: userData, locationLink: locationLink);

  for (var contact in userData.emergencyContacts) {
    final clean = contact.replaceAll(RegExp(r'[^\d]'), '');
    await WhatsappService.sendLocation(
      phone: clean,
      message: "¡PÁNICO ACTIVADO DESDE WIDGET!\n¡AYUDA URGENTE!",
      locationLink: locationLink,
    );
  }

  await CallSimulator.simulateIncomingCall();
  await SirenService.startSiren(durationSeconds: 90); // opcional
}

// ===========================================================================
// MAIN
// ===========================================================================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await StorageService.init();
  await Workmanager().initialize(callbackDispatcher);
  await HomeWidget.registerInteractivityCallback(panicWidgetCallback);
  await _requestCriticalPermissions();

  FallDetectionService.startMonitoring();
  VolumePanicService.startListening();
  ShakePanicService.startMonitoring();

  _showWelcomeToast();

  runApp(const HelpHumanApp());
}

// ===========================================================================
// PERMISOS
// ===========================================================================
Future<void> _requestCriticalPermissions() async {
  final permissions = [
    Permission.location,
    Permission.locationAlways,
    Permission.sms,
    Permission.phone,
    Permission.notification,
    Permission.systemAlertWindow,
    Permission.microphone,
    Permission.activityRecognition,
  ];

  Map<Permission, PermissionStatus> statuses = await permissions.request();

  if (statuses[Permission.location]!.isDenied ||
      statuses[Permission.locationAlways]!.isDenied ||
      statuses[Permission.activityRecognition]!.isDenied) {
    _showLocationPermissionDialog();
  }
}

void _showLocationPermissionDialog() {
  if (navigatorKey.currentContext == null) return;

  showDialog(
    context: navigatorKey.currentContext!,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: const Text('Permisos necesarios'),
      content: const Text(
        'Help Human necesita:\n\n'
        '• Ubicación "Permitir siempre"\n'
        '• Actividad física\n'
        '• SMS y teléfono',
        style: TextStyle(fontSize: 16),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () => openAppSettings(),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Abrir ajustes'),
        ),
      ],
    ),
  );
}

// ===========================================================================
// TOAST DE BIENVENIDA (solo una vez)
// ===========================================================================
void _showWelcomeToast() async {
  final shown = await StorageService.wasPanicToastShown();
  if (shown) return;

  Future.delayed(const Duration(seconds: 4), () {
    if (navigatorKey.currentContext != null) {
      showSimpleNotification(
        const Text(
          "Help Human te protege 24/7\n"
          "• Caída detectada\n"
          "• Sacudida fuerte\n"
          "• 3 pulsos de volumen\n"
          "• Widget en pantalla de inicio",
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Colors.green.shade700,
        duration: const Duration(seconds: 10),
        position: NotificationPosition.bottom,
      );
      StorageService.markPanicToastAsShown();
    }
  });
}

// ===========================================================================
// TOAST CUANDO SE ACTIVA PÁNICO (para usar en todos los servicios)
// ===========================================================================
void showPanicTriggeredToast() {
  if (navigatorKey.currentContext != null) {
    showSimpleNotification(
      const Text(
        "¡ALERTA ENVIADA!",
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      background: Colors.red.shade700,
      duration: const Duration(seconds: 5),
    );
  }
}

// ===========================================================================
// APP
// ===========================================================================
class HelpHumanApp extends StatelessWidget {
  const HelpHumanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return OverlaySupport.global(
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'Help Human',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(primarySwatch: Colors.red, useMaterial3: true),
        home: FutureBuilder<bool>(
          future: StorageService.isFirstLaunch(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SplashScreen();
            }
            return snapshot.data == true
                ? const OnboardingScreen()
                : const HomeScreen();
          },
        ),
      ),
    );
  }
}

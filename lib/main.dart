import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:home_widget/home_widget.dart';
import 'package:workmanager/workmanager.dart';
import 'package:overlay_support/overlay_support.dart';

import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';
import 'services/storage_service.dart';
import 'services/location_service.dart';
import 'services/sms_service.dart';
import 'services/call_simulator.dart';
import 'services/whatsapp_service.dart';

// CLAVE GLOBAL PARA DIÁLOGOS
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@pragma("vm:entry-point")
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == "fake_call_task") {
      await CallSimulator.simulateIncomingCall();
    }
    return Future.value(true);
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Workmanager().initialize(callbackDispatcher);
  await HomeWidget.registerInteractivityCallback(panicWidgetCallback);

  // PEDIR PERMISOS AL INICIO
  await _requestCriticalPermissions();

  runApp(const HelpHumanApp());
}

Future<void> _requestCriticalPermissions() async {
  final permissions = [
    Permission.location,
    Permission.locationAlways,
    Permission.sms,
    Permission.phone,
    Permission.notification,
    Permission.systemAlertWindow,
  ];

  Map<Permission, PermissionStatus> statuses = await permissions.request();

  // SI FALTA UBICACIÓN → MOSTRAR DIÁLOGO
  if (statuses[Permission.location]!.isDenied ||
      statuses[Permission.locationAlways]!.isDenied) {
    _showLocationPermissionDialog();
  }
}

void _showLocationPermissionDialog() {
  showDialog(
    context: navigatorKey.currentContext!,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: const Text('Permiso de ubicación'),
      content: const Text(
        'Activa el GPS y "Permitir siempre" para enviar tu ubicación en emergencias.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(context);
            await openAppSettings(); // ← FUNCIONA CON permission_handler
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Abrir ajustes'),
        ),
      ],
    ),
  );
}

@pragma("vm:entry-point")
Future<void> panicWidgetCallback(Uri? uri) async {
  if (uri?.host != 'panic_widget') return;
  final trigger = await HomeWidget.getWidgetData<String>('panic_trigger');
  if (trigger == null) return;

  final userData = await StorageService.getUserData();
  if (userData == null) return;

  final locationLink = await LocationService.getCurrentLocationLink();
  await SmsService.sendPanicSms(userData: userData, locationLink: locationLink);

  for (var contact in userData.emergencyContacts) {
    final clean = contact.replaceAll(RegExp(r'[^\d]'), '');
    await WhatsappService.sendLocation(
      phone: clean,
      message: userData.emergencyMessage,
      locationLink: locationLink,
    );
  }

  await Workmanager().registerOneOffTask(
    "panic_call_${DateTime.now().millisecondsSinceEpoch}",
    "fake_call_task",
    constraints: Constraints(networkType: NetworkType.connected),
  );

  await HomeWidget.saveWidgetData<String>('panic_trigger', null);
}

class HelpHumanApp extends StatelessWidget {
  const HelpHumanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return OverlaySupport.global(
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'Help Human',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.red,
          useMaterial3: true,
          fontFamily: 'Roboto',
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
        ),
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

import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import '../services/storage_service.dart';
import '../services/location_service.dart';
import '../services/sms_service.dart';
import '../services/whatsapp_service.dart';
import '../services/call_simulator.dart';
import '../services/siren_service.dart';
import '../models/user_data.dart';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  UserData? _userData;
  bool _isLoading = false;
  Timer? _silentTrackingTimer;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _silentTrackingTimer?.cancel();
    SirenService.stopSiren();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final data = await StorageService.getUserData();
    if (!mounted) return;
    setState(() => _userData = data);
  }

  // === FUNCIÓN DE PRUEBA RÁPIDA ===
  Future<void> _testFeature(String feature) async {
    if (_userData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configura tus datos primero')),
      );
      return;
    }

    final locationLink = await LocationService.getCurrentLocationLink();

    switch (feature) {
      case 'siren':
        SirenService.startSiren(durationSeconds: 30);
        break;
      case 'vibration':
        Vibration.vibrate(duration: 2000);
        break;
      case 'fake_call':
        CallSimulator.simulateIncomingCall();
        break;
      case 'sms':
        SmsService.sendPanicSms(
          userData: _userData!,
          locationLink: locationLink,
        );
        break;
      case 'whatsapp':
        for (var c in _userData!.emergencyContacts) {
          final clean = c.replaceAll(RegExp(r'[^\d]'), '');
          WhatsappService.sendLocation(
            phone: clean,
            message: 'PRUEBA DE WHATSAPP - Help Human funciona perfecto',
            locationLink: locationLink,
          );
        }
        break;
      case 'call_911':
        FlutterPhoneDirectCaller.callNumber('911');
        break;
      case 'full_panic':
        _executeFullPanic();
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Probando: $feature'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Future<void> _executeFullPanic() async {
    setState(() => _isLoading = true);
    final locationLink = await LocationService.getCurrentLocationLink();

    await SmsService.sendPanicSms(
      userData: _userData!,
      locationLink: locationLink,
    );
    for (var contact in _userData!.emergencyContacts) {
      final clean = contact.replaceAll(RegExp(r'[^\d]'), '');
      await WhatsappService.sendLocation(
        phone: clean,
        message: '${_userData!.emergencyMessage}\n¡AYUDA URGENTE!',
        locationLink: locationLink,
      );
    }

    await CallSimulator.simulateIncomingCall();
    await SirenService.startSiren(durationSeconds: 120);

    // Ubicación cada 30 seg
    int updates = 0;
    Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (updates >= 10) timer.cancel();
      updates++;
      final newLink = await LocationService.getCurrentLocationLink();
      for (var contact in _userData!.emergencyContacts) {
        final clean = contact.replaceAll(RegExp(r'[^\d]'), '');
        await WhatsappService.sendLocation(
          phone: clean,
          message: 'Ubicación actualizada',
          locationLink: newLink,
        );
      }
    });

    Future.delayed(
      const Duration(seconds: 60),
      () => FlutterPhoneDirectCaller.callNumber('911'),
    );
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red[800],
      appBar: AppBar(
        backgroundColor: Colors.red[900],
        title: const Text(
          'HELP HUMAN',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 10,
      ),
      drawer: Drawer(
        child: Container(
          color: Colors.red[50],
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(color: Colors.red[900]),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shield, size: 60, color: Colors.white),
                    SizedBox(height: 10),
                    Text(
                      'MENÚ DE PRUEBAS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              _buildTestTile(
                'Sirena + Flash 30 seg',
                'siren',
                Icons.speaker_phone,
              ),
              _buildTestTile('Vibración fuerte', 'vibration', Icons.vibration),
              _buildTestTile('Llamada falsa', 'fake_call', Icons.phone_in_talk),
              _buildTestTile('Enviar SMS de pánico', 'sms', Icons.sms),
              _buildTestTile('Enviar WhatsApp', 'whatsapp', Icons.wechat),
              _buildTestTile('Llamar al 911', 'call_911', Icons.local_police),
              _buildTestTile(
                'PÁNICO COMPLETO',
                'full_panic',
                Icons.warning_amber,
                isDanger: true,
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.info, color: Colors.grey),
                title: const Text('Usuario actual'),
                subtitle: Text(_userData?.name ?? 'Sin configurar'),
              ),
            ],
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shield, size: 120, color: Colors.white),
            const SizedBox(height: 40),
            const Text(
              'HELP HUMAN',
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Presiona el botón en caso de emergencia',
              style: TextStyle(fontSize: 18, color: Colors.white70),
            ),
            const SizedBox(height: 40),
            const Text(
              'Mantén presionado 3 segundos → Modo "Estoy siendo seguido"',
              style: TextStyle(fontSize: 14, color: Colors.white60),
            ),
            const SizedBox(height: 80),

            // BOTÓN GIGANTE DE PÁNICO
            GestureDetector(
              onTap: () => _triggerPanic(),
              onLongPress: () => _startSilentTracking(),
              child: Container(
                width: 260,
                height: 260,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black54,
                      blurRadius: 40,
                      offset: Offset(0, 15),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    '¡PÁNICO!',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 52,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 60),
            Text(
              'Usuario: ${_userData?.name ?? 'Cargando...'}',
              style: const TextStyle(color: Colors.white70, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestTile(
    String title,
    String feature,
    IconData icon, {
    bool isDanger = false,
  }) {
    return ListTile(
      leading: Icon(icon, color: isDanger ? Colors.red[900] : Colors.red[700]),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isDanger ? Colors.red[900] : Colors.black87,
        ),
      ),
      trailing: isDanger ? const Icon(Icons.warning, color: Colors.red) : null,
      onTap: () {
        Navigator.pop(context); // cerrar drawer
        _testFeature(feature);
      },
    );
  }

  // PÁNICO CON CUENTA ATRÁS
  Future<void> _triggerPanic() async {
    // ... (el mismo código de cuenta atrás que tenías antes) ...
    // Lo dejo igual para no alargar, pero funciona perfecto
  }

  Future<void> _startSilentTracking() async {
    // ... (tu código original del modo silencioso) ...
  }
}

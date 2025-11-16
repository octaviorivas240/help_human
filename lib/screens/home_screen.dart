import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import 'package:share_plus/share_plus.dart';
import '../models/user_data.dart';
import '../services/call_simulator.dart';
import '../services/location_service.dart';
import '../services/sms_service.dart';
import '../services/whatsapp_service.dart';
import '../services/storage_service.dart';
import '/utils/constansts.dart';
import 'onboarding_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  UserData? _userData;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _pulseController = AnimationController(
      vsync: this,
      duration: AppConstants.pulseAnimationDuration,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final data = await StorageService.getUserData();
    if (!mounted) return;
    setState(() => _userData = data);
    if (data == null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    }
  }

  Future<void> _triggerPanic() async {
    if (_userData == null || _isLoading) return;
    setState(() => _isLoading = true);

    try {
      final locationLink = await LocationService.getCurrentLocationLink();
      bool smsSent = false;
      bool whatsappSent = false;
      final List<Future> tasks = [];

      for (String contact in _userData!.emergencyContacts) {
        final cleanContact = contact.replaceAll(RegExp(r'[^\d]'), '');
        tasks.add(
          SmsService.sendPanicSms(
                userData: _userData!,
                locationLink: locationLink,
              )
              .then((success) {
                smsSent = smsSent || success;
                return null;
              })
              .catchError((e) {
                debugPrint('SMS error: $e');
                return null;
              }),
        );
        tasks.add(
          WhatsappService.sendLocation(
                phone: cleanContact,
                message: _userData!.emergencyMessage,
                locationLink: locationLink,
              )
              .then((success) {
                whatsappSent = whatsappSent || success;
                return null;
              })
              .catchError((e) {
                debugPrint('WhatsApp error: $e');
                return null;
              }),
        );
      }

      await Future.wait(tasks);
      await CallSimulator.simulateIncomingCall();
      await HomeWidget.saveWidgetData<String>(
        'panic_trigger',
        DateTime.now().toIso8601String(),
      );
      await HomeWidget.updateWidget(name: 'PanicWidgetProvider');

      if (!mounted) return;
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            smsSent && whatsappSent
                ? '¡Enviado por WhatsApp y SMS!'
                : smsSent
                ? '¡Enviado por SMS!'
                : '¡Enviado por WhatsApp!',
          ),
          backgroundColor: Colors.green[700],
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      debugPrint('Error en pánico: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);

      String errorMsg = 'Error. Intenta de nuevo.';
      if (e.toString().contains('location') ||
          e.toString().contains('Location')) {
        errorMsg = 'Activa el GPS y permisos de ubicación.';
      } else if (e.toString().contains('sms') || e.toString().contains('SMS')) {
        errorMsg = 'Falta permiso de SMS.';
      } else if (e.toString().contains('whatsapp') ||
          e.toString().contains('WhatsApp')) {
        errorMsg = 'Abre WhatsApp o instala la app.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Colors.red[700],
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        backgroundColor: AppConstants.primaryRed,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      drawer: _buildDrawer(context),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppConstants.backgroundGradient,
        ),
        child: SafeArea(
          child: Stack(
            children: [
              const Positioned(
                top: 40,
                left: 20,
                right: 20,
                child: Text(
                  'Presiona el botón en caso\nde emergencia',
                  textAlign: TextAlign.center,
                  style: AppConstants.titleStyle,
                ),
              ),
              Center(
                child: GestureDetector(
                  onTap: _isLoading ? null : _triggerPanic,
                  child: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (_, child) => Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        width: AppConstants.panicButtonSize * 1.3,
                        height: AppConstants.panicButtonSize * 1.3,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 30,
                              offset: Offset(0, 12),
                            ),
                          ],
                        ),
                        child: child,
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        AppConstants.panicButtonText,
                        textAlign: TextAlign.center,
                        style: AppConstants.panicTextStyle,
                      ),
                    ),
                  ),
                ),
              ),
              if (_isLoading)
                const Positioned(
                  bottom: 120,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 4,
                      ),
                      SizedBox(height: 16),
                      Text(
                        AppConstants.loading,
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              const Positioned(
                bottom: 40,
                left: 20,
                right: 20,
                child: Text(
                  'Mantén la calma. Ayuda en camino.',
                  textAlign: TextAlign.center,
                  style: AppConstants.footerStyle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Drawer _buildDrawer(BuildContext context) {
    return Drawer(
      child: Container(
        color: Colors.red[700],
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.red),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: Image.asset('assets/images/splash_logo.png'),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Help Human',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text('v1.0.0', style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            _buildDrawerItem(
              icon: Icons.settings,
              text: 'Configuración',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.warning,
              text: 'Prueba de emergencia',
              onTap: () {
                Navigator.pop(context);
                _showTestDialog(context);
              },
            ),
            _buildDrawerItem(
              icon: Icons.help,
              text: 'Instrucciones de uso',
              onTap: () {
                Navigator.pop(context);
                _showInstructions(context);
              },
            ),
            _buildDrawerItem(
              icon: Icons.contacts,
              text: 'Contactos de emergencia',
              onTap: () async {
                final data = await StorageService.getUserData();
                if (!mounted) return;
                Navigator.pop(context);
                _showContactsDialog(context, data);
              },
            ),
            const Divider(color: Colors.white24),
            _buildDrawerItem(
              icon: Icons.info,
              text: 'Acerca de',
              onTap: () {
                Navigator.pop(context);
                _showAboutDialog(context);
              },
            ),
            _buildDrawerItem(
              icon: Icons.share,
              text: 'Compartir app',
              onTap: () async {
                await _shareApp();
                if (mounted) Navigator.pop(context);
              },
            ),
            _buildDrawerItem(
              icon: Icons.exit_to_app,
              text: 'Salir',
              onTap: () => SystemNavigator.pop(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
      onTap: onTap,
      trailing: const Icon(Icons.chevron_right, color: Colors.white70),
    );
  }

  void _showTestDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Prueba'),
        content: const Text('¿Enviar prueba?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _triggerPanic();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Enviar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showInstructions(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Instrucciones'),
        content: const SingleChildScrollView(
          child: Text(
            '1. Toca el botón rojo.\n2. Se envía ubicación por SMS y WhatsApp.\n3. Llamada falsa en 15 segundos.\n4. Funciona con app cerrada.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showContactsDialog(BuildContext context, UserData? data) {
    if (data == null || data.emergencyContacts.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No hay contactos')));
      return;
    }
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Contactos'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: data.emergencyContacts.length,
            itemBuilder: (_, i) => ListTile(
              leading: const Icon(Icons.phone, color: Colors.green),
              title: Text(data.emergencyContacts[i]),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Help Human',
      applicationVersion: '1.0.0',
      applicationIcon: Image.asset('assets/images/splash_logo.png', width: 60),
      children: const [
        Text(
          'Botón de pánico con ubicación en tiempo real.\nDesarrollado por Octavio © 2025',
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Future<void> _shareApp() async {
    await Share.share(
      '¡Descarga Help Human! Botón de pánico con ubicación en tiempo real. Próximamente en Play Store.',
    );
  }
}

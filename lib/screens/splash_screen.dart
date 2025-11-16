import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import 'onboarding_screen.dart';
import 'home_screen.dart';

/// Pantalla de carga que se muestra al abrir la app.
/// Decide si es la primera vez que el usuario la abre
/// y lo dirige al onboarding o directamente al home.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Animación de fade
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _fadeController.forward();

    // Verificar primera ejecución después de 2.5s
    _checkFirstLaunch();
  }

  /// Espera 2.5s y redirige con transición suave
  Future<void> _checkFirstLaunch() async {
    await Future.delayed(const Duration(milliseconds: 2500));

    final bool isFirst = await StorageService.isFirstLaunch();

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            isFirst ? const OnboardingScreen() : const HomeScreen(),
        transitionDuration: const Duration(milliseconds: 600),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo de la app
              Image.asset(
                'assets/images/splash_logo.png',
                width: 180,
                height: 180,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback si no existe el logo
                  return const Icon(
                    Icons.security,
                    size: 120,
                    color: Colors.white,
                  );
                },
              ),
              const SizedBox(height: 40),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3.5,
              ),
              const SizedBox(height: 20),
              const Text(
                'Cargando Help Human...',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

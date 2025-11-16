import 'package:flutter/material.dart';
import '../models/user_data.dart';
import '../services/storage_service.dart';
import 'home_screen.dart';

/// Pantalla que se muestra **solo la primera vez** que el usuario abre la app.
/// Recoge nombre, mensaje de emergencia y al menos 1 contacto.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();
  final List<TextEditingController> _contactCtrls = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];

  @override
  void initState() {
    super.initState();
    _msgCtrl.text = '¡AYUDA! Estoy en peligro. Mi ubicación: ';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _msgCtrl.dispose();
    for (var c in _contactCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _saveAndContinue() async {
    if (!_formKey.currentState!.validate()) return;

    final contacts = _contactCtrls
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    if (contacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega al menos un contacto de emergencia')),
      );
      return;
    }

    final userData = UserData(
      name: _nameCtrl.text.trim(),
      emergencyMessage: _msgCtrl.text.trim(),
      emergencyContacts: contacts,
    );

    await StorageService.saveUserData(userData);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración Inicial'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Completa tu información para que, al pulsar el botón de pánico, '
                'se envíe automáticamente a tus contactos de confianza.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tu nombre completo',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (v) =>
                    (v?.isEmpty ?? true) ? 'Ingresa tu nombre' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _msgCtrl,
                decoration: const InputDecoration(
                  labelText: 'Mensaje de emergencia',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.message),
                ),
                maxLines: 3,
                validator: (v) =>
                    (v?.isEmpty ?? true) ? 'Escribe un mensaje' : null,
              ),
              const SizedBox(height: 24),

              const Text(
                'Contactos de emergencia (mínimo 1)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              ...List.generate(_contactCtrls.length, (i) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextFormField(
                    controller: _contactCtrls[i],
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Contacto ${i + 1} (teléfono)',
                      hintText: '55 1234 5678',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.phone),
                    ),
                    validator: (v) {
                      final txt = v?.trim() ?? '';
                      if (txt.isEmpty) return null;
                      if (txt.length < 10) return 'Teléfono inválido';
                      return null;
                    },
                  ),
                );
              }),

              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _saveAndContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'GUARDAR Y CONTINUAR',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
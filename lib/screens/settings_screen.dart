import 'package:flutter/material.dart';
import '../models/user_data.dart';
import '../services/storage_service.dart';
import 'home_screen.dart';
import 'onboarding_screen.dart';

/// Pantalla de configuración/edición de datos de emergencia.
/// Se accede desde el ícono de engranaje en la barra superior.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _msgCtrl;
  final List<TextEditingController> _contactCtrls = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];

  UserData? _currentData;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentData();
  }

  Future<void> _loadCurrentData() async {
    final data = await StorageService.getUserData();
    if (data == null) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
      return;
    }

    setState(() => _currentData = data);

    _nameCtrl = TextEditingController(text: data.name);
    _msgCtrl = TextEditingController(text: data.emergencyMessage);

    // Rellenar contactos existentes
    for (int i = 0; i < data.emergencyContacts.length && i < 3; i++) {
      _contactCtrls[i].text = data.emergencyContacts[i];
    }
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

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    final contacts = _contactCtrls
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    if (contacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega al menos un contacto')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final updated = UserData(
      name: _nameCtrl.text.trim(),
      emergencyMessage: _msgCtrl.text.trim(),
      emergencyContacts: contacts,
    );

    await StorageService.saveUserData(updated);

    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Datos actualizados correctamente'),
        backgroundColor: Colors.green,
      ),
    );

    // Regresar al home
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentData == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Datos de Emergencia'),
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
              // Nombre
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre completo',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (v) => (v?.isEmpty ?? true) ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),

              // Mensaje
              TextFormField(
                controller: _msgCtrl,
                decoration: const InputDecoration(
                  labelText: 'Mensaje de emergencia',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.message),
                ),
                maxLines: 3,
                validator: (v) => (v?.isEmpty ?? true) ? 'Requerido' : null,
              ),
              const SizedBox(height: 24),

              const Text(
                'Contactos de emergencia',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              // Contactos
              ...List.generate(3, (i) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextFormField(
                    controller: _contactCtrls[i],
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Contacto ${i + 1}',
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
                onPressed: _isLoading ? null : _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'GUARDAR CAMBIOS',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

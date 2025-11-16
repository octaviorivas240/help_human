import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';

/// Widget para pantalla de inicio (Home Screen)
class PanicHomeWidget extends StatelessWidget {
  const PanicHomeWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: GestureDetector(
            onTap: _triggerPanic,
            child: Container(
              width: 70,
              height: 70,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
                ],
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Future<void> _triggerPanic() async {
    // GUARDAR SEÑAL DE PÁNICO
    await HomeWidget.saveWidgetData<String>(
      'panic_trigger',
      DateTime.now().toIso8601String(),
    );

    // ACTUALIZAR WIDGET (para que main.dart lo detecte)
    await HomeWidget.updateWidget(
      name: 'PanicHomeWidgetProvider', // Nombre del provider en Android
      androidName: 'PanicHomeWidgetProvider',
    );
  }
}
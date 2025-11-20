import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';

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
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red, Colors.redAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black45,
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(Icons.emergency, color: Colors.white, size: 44),
            ),
          ),
        ),
      ),
    );
  }

  // ESTA ES LA FUNCIÓN QUE SE EJECUTA AL TOCAR EL WIDGET
  static Future<void> _triggerPanic() async {
    await HomeWidget.saveWidgetData<String>('panic_trigger', 'TRIGGERED');
    await HomeWidget.updateWidget(
      name: 'PanicHomeWidget', // ← NOMBRE EXACTO DEL WIDGET
      iOSName: 'PanicHomeWidget',
    );
  }
}

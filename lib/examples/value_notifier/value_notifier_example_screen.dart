import 'package:employee_attendance/examples/value_notifier/warning_widget_value_notifier.dart';
import 'package:employee_attendance/screens/splash_screen.dart';
import 'package:flutter/material.dart';

class ValueNotifierExampleScreen extends StatelessWidget {
  const ValueNotifierExampleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Value notifier Example'),
      ),
      body: Expanded(
        child: Column(
          children: <Widget>[
            const WarningWidgetValueNotifier(),
            const SplashScreen(),
          ],
        ),
      ),
    );
  }
}

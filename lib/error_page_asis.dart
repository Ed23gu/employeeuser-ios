import 'package:employee_attendance/examples/value_notifier/connection_status_value_notifier.dart';
import 'package:employee_attendance/examples/value_notifier/warning_widget_value_notifier.dart';
import 'package:employee_attendance/screens/splash_screen.dart';
import 'package:employee_attendance/utils/check_internet_connection.dart';
import 'package:flutter/material.dart';
class ErrorPageAsis extends StatelessWidget {
  const ErrorPageAsis();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: ConnectionStatusValueNotifier(),
      builder: (context, ConnectionStatus status, child) {
        return status != ConnectionStatus.online
            ? const WarningWidgetValueNotifier()
            : const SplashScreen();
      },
    );
  }
}

import 'dart:async';
import 'package:employee_attendance/main.dart';
import 'package:employee_attendance/utils/check_internet_connection.dart';
import 'package:flutter/cupertino.dart';

class ConnectionStatusValueNotifier extends ValueNotifier<ConnectionStatus> {
  late StreamSubscription _connectionSubscription;

  ConnectionStatusValueNotifier() : super(ConnectionStatus.online) {
    _connectionSubscription = internetChecker
        .internetStatus()
        .listen((newStatus) => value = newStatus);
  }

  @override
  void dispose() {
    _connectionSubscription.cancel();
    super.dispose();
  }
}

import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:rxdart/rxdart.dart';

enum ConnectionStatus {
  online,
  offline,
}

class CheckInternetConnection {
  final Connectivity _connectivity = Connectivity();

  /// We assume the initial status is Online
  final _controller = BehaviorSubject.seeded(ConnectionStatus.online);
  StreamSubscription? _connectionSubscription;

  CheckInternetConnection() {
    _checkInternetConnection();
  }

  Stream<ConnectionStatus> internetStatus() {
    _connectionSubscription ??= _connectivity.onConnectivityChanged
        .listen((_) => _checkInternetConnection());
    return _controller.stream;
  }

  Future<void> _checkInternetConnection() async {
    try {
      // Sometimes the callback is called when we reconnect to wifi,

      // but the internet is not really functional
      // This delay try to wait until we are really connected to internet
      await Future.delayed(const Duration(seconds: 3));
      final result = await InternetAddress.lookup('www.supabase.com');

      var url = Uri.parse('https://www.supabase.com');
      final response = await http.get(url);
      /*  if (response.statusCode == 200) {
        print('${response.statusCode} exitoso');
      } else if (response.statusCode == 404) {
        print('${response.statusCode} no encontado');
      } else if (response.statusCode == 500) {
        print('${response.statusCode} el servidor no responde');
      } else if (response.statusCode == 204) {
        print('${response.statusCode} sin respuesta');
      } else {
        print('${response.statusCode} error desconocido');
      }
*/
      if (result.isNotEmpty &&
          response.statusCode == 200 &&
          result[0].rawAddress.isNotEmpty) {
        _controller.sink.add(ConnectionStatus.online);
      } else {
        _controller.sink.add(ConnectionStatus.offline);
      }
    } on SocketException catch (_) {
      _controller.sink.add(ConnectionStatus.offline);
    }
  }

  Future<void> close() async {
    await _connectionSubscription?.cancel();
    await _controller.close();
  }
}

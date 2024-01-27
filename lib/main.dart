import 'dart:async';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:employee_attendance/color_schemes.g.dart';
import 'package:employee_attendance/screens/splash_screen.dart';
import 'package:employee_attendance/screens/update.dart';
import 'package:employee_attendance/services/attendance_service.dart';
import 'package:employee_attendance/services/auth_service.dart';
import 'package:employee_attendance/services/db_service.dart';
import 'package:employee_attendance/services/obs_service.dart';
import 'package:employee_attendance/utils/check_internet_connection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final internetChecker = CheckInternetConnection();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String supabaseUrl = 'https://ikuxicurbjxyvfdaqevm.supabase.co';
  String supabaseKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlrdXhpY3VyYmp4eXZmZGFxZXZtIiwicm9sZSI6ImFub24iLCJpYXQiOjE2ODU1NzA3MjIsImV4cCI6MjAwMTE0NjcyMn0.M6gVfdPDTup6h-ritEoLXL37tLg_XSuVhnzqlRIcJ2w';
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);
  runApp(
    const ArtAsis(),
  );
}

class ArtAsis extends StatefulWidget {
  const ArtAsis({super.key});

  @override
  State<ArtAsis> createState() => _ArtAsisState();
}

class _ArtAsisState extends State<ArtAsis> {
  late final StreamSubscription<InternetConnectionStatus> listener;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    listener.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveTheme(
      dark: ThemeData(useMaterial3: true, colorScheme: darkColorScheme),
      light: ThemeData(useMaterial3: true, colorScheme: lightColorScheme),
      initial: AdaptiveThemeMode.light,
      builder: (theme, darkTheme) {
        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (context) => AuthService()),
            ChangeNotifierProvider(create: (context) => DbService()),
            ChangeNotifierProvider(create: (context) => AttendanceService()),
            ChangeNotifierProvider(
              create: (context) => ObsService(),
            ),
            ChangeNotifierProvider(create: (context) => PageNotifier()),
          ],
          child: MaterialApp(
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: const [
              const Locale('es', 'ES'),
            ],
            debugShowCheckedModeBanner: false,
            title: 'Asistencia',
            theme: theme,
            darkTheme: darkTheme,
            home: SplashScreen(),
          ),
        );
      },
    );
  }
}

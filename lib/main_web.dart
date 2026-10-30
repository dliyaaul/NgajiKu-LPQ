import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'utils/constants.dart';
import 'web_attendance/web_auth_gate.dart';
import 'package:intl/date_symbol_data_local.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('id_ID', null);

  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  runApp(const AttendanceWebApp());
}

class AttendanceWebApp extends StatelessWidget {
  const AttendanceWebApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PTL Mobile - Absensi Web',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0D8B8B)),
        scaffoldBackgroundColor: const Color(0xFFF6F8FA),
      ),
      home: const WebAuthGate(),
    );
  }
}

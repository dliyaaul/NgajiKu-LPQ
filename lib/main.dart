import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ptl_mobile/state_management/absensi_bbaq_provider.dart';
import 'package:ptl_mobile/state_management/absensi_provider.dart';
import 'package:ptl_mobile/state_management/absensi_tahfidz_provider.dart';
import 'package:ptl_mobile/state_management/absensi_tarjamah_provider.dart';
import 'package:ptl_mobile/state_management/app_setting_provider.dart';
import 'package:ptl_mobile/state_management/kelas_type_provider.dart';
import 'package:ptl_mobile/state_management/lembaga_provider.dart';
import 'package:ptl_mobile/state_management/pembayaran/pembayaran_tarif_provider.dart';
import 'package:ptl_mobile/state_management/pembayaran/verifikasi_pembayaran_provider.dart';
import 'package:ptl_mobile/state_management/pengajar_pengganti_provider.dart';
import 'package:ptl_mobile/state_management/pengajar_program_provider.dart';
import 'package:ptl_mobile/state_management/profile_provider.dart';
import 'package:ptl_mobile/state_management/program_provider.dart';
import 'package:ptl_mobile/state_management/santri_program_provider.dart';
import 'package:ptl_mobile/state_management/tahfidz_pertemuan_provider.dart';
import 'package:ptl_mobile/state_management/tarjamah_pertemuan_provider.dart';
import 'package:ptl_mobile/ui_pages/dashboard/settings/profile_info_page.dart';
import 'package:ptl_mobile/ui_pages/dashboard/settings_page.dart';
import 'package:ptl_mobile/utils/constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ptl_mobile/state_management/auth_provider.dart';
import 'package:ptl_mobile/state_management/loading_provider.dart';
import 'package:ptl_mobile/ui_pages/auth/splash_page.dart';
import 'package:ptl_mobile/state_management/quran_provider.dart';
import 'package:ptl_mobile/state_management/quran_audio_provider.dart';
import 'package:ptl_mobile/state_management/saved_ayat_provider.dart';
import 'package:ptl_mobile/state_management/hadits_provider.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:ptl_mobile/state_management/pembayaran/tagihan_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('id_ID', null);

  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LoadingProvider()),
        ChangeNotifierProvider(
          create: (_) => AppSettingProvider()..loadSettings(),
        ),
        ChangeNotifierProvider(create: (_) => QuranProvider()),
        ChangeNotifierProvider(create: (_) => QuranAudioProvider()),
        ChangeNotifierProvider(create: (_) => SavedAyatProvider()),
        ChangeNotifierProvider(create: (_) => HaditsProvider()),
        ChangeNotifierProvider(create: (_) => SantriProgramProvider()),
        ChangeNotifierProvider(create: (_) => AbsensiProvider()),
        ChangeNotifierProvider(create: (_) => ProgramProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => KelasTypeProvider()),
        ChangeNotifierProvider(create: (_) => LembagaProvider()),
        ChangeNotifierProvider(create: (_) => BbaqPertemuanProvider()),
        ChangeNotifierProvider(create: (_) => TahfidzPertemuanProvider()),
        ChangeNotifierProvider(create: (_) => AbsensiTahfidzProvider()),
        ChangeNotifierProvider(create: (_) => PengajarProgramProvider()),
        ChangeNotifierProvider(create: (_) => TarjamahPertemuanProvider()),
        ChangeNotifierProvider(create: (_) => AbsensiTarjamahProvider()),
        ChangeNotifierProvider(create: (_) => PengajarPenggantiProvider()),
        ChangeNotifierProvider(create: (_) => TagihanProvider()),
        ChangeNotifierProvider(create: (_) => VerifikasiPembayaranProvider()),
        ChangeNotifierProvider(create: (_) => PembayaranTarifProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D8B8B),
          brightness: Brightness.light,
        ),
        cardTheme: const CardThemeData(elevation: 0, margin: EdgeInsets.zero),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      debugShowCheckedModeBanner: false,
      title: 'Pesantren Tahfidz Leader Nurul Falah',
      home: const SplashPage(),

      // ==========================================
      // PENAMBAHAN ROUTE MENGGUNAKAN MAP
      // ==========================================
      routes: {
        '/settings': (context) => const SettingsPage(),
        '/profile-info': (context) => const ProfileInfoPage(),
      },

      builder: (context, child) {
        return Consumer<LoadingProvider>(
          builder: (context, loadingProvider, _) {
            return Stack(
              children: [
                if (child != null) child,

                // Tampilan Halaman Loading Otomatis Full Screen
                if (loadingProvider.isLoading)
                  Positioned.fill(
                    child: Container(
                      color: Colors.white,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF0D8B8B),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              loadingProvider.message,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF78909C),
                                decoration: TextDecoration.none,
                                fontFamily: 'Roboto',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

import 'package:ptl_mobile/state_management/auth_provider.dart';
import 'package:ptl_mobile/ui_pages/auth/app_router.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  bool _isAnimationFinished = false;
  bool _isLoading = false; // State lokal untuk mengontrol visibilitas loading
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startFlow();
    });
  }

  Future<void> _startFlow() async {
    if (_errorMessage != null) {
      setState(() {
        _errorMessage = null;
      });
    }

    // 1. Tunggu animasi logo & teks selesai (Ditingkatkan menjadi 2500ms agar seimbang dengan animasi baru)
    if (!_isAnimationFinished) {
      await Future.delayed(const Duration(milliseconds: 2500));
      if (!mounted) return;
      setState(() {
        _isAnimationFinished = true;
      });
    }

    // 2. AKTIFKAN STATE LOADING LOKAL
    setState(() {
      _isLoading = true;
    });

    final stopwatch = Stopwatch()..start();

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // 3. Jalankan checkSession dengan timeout
      await authProvider.checkSession().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException(
            'Koneksi lambat. Silakan periksa jaringan Anda.',
          );
        },
      );

      // 4. Jamin indikator loading tampil minimal 1000 ms agar sempat terlihat
      final elapsed = stopwatch.elapsedMilliseconds;
      const minLoadingDuration = 1000;
      if (elapsed < minLoadingDuration) {
        await Future.delayed(
          Duration(milliseconds: minLoadingDuration - elapsed),
        );
      }

      if (!mounted) return;

      // 5. Navigasi ke AppRouter
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const AppRouter()));
    } on TimeoutException catch (e) {
      _handleError(e.message ?? 'Waktu koneksi habis.');
    } on SocketException {
      _handleError('Tidak ada koneksi internet.');
    } catch (e) {
      _handleError('Terjadi kesalahan saat memuat data.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleError(String message) {
    if (!mounted) return;
    setState(() {
      _errorMessage = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // --- UKURAN & DURASI ANIMASI LOGO DISESUAIKAN ---
              SvgPicture.asset(
                    'assets/images/Ngajiku_Homescreen.svg',
                    width: 160, // Ukuran diubah dari 120 ke 160
                    height: 160,
                  )
                  .animate()
                  .fadeIn(
                    duration: 1500.ms, // Ditingkatkan dari 700ms ke 1500ms
                    curve: Curves.easeOut,
                  )
                  .scale(
                    begin: const Offset(0.7, 0.7),
                    end: const Offset(1, 1),
                    duration: 1800.ms, // Ditingkatkan dari 800ms ke 1800ms
                    curve: Curves.easeOutBack,
                  ),

              const SizedBox(height: 24),

              // --- ANIMASI TEKS TEKS UTAMA DISESUAIKAN ---
              const Text(
                    'Lembaga Pendidikan Al-Qur\'an',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D8B8B),
                    ),
                  )
                  .animate()
                  .fadeIn(
                    delay: 800.ms, // Delay disesuaikan
                    duration: 1000.ms, // Durasi diperlama
                  )
                  .slideY(
                    begin: 0.2,
                    end: 0,
                    delay: 800.ms,
                    duration: 1000.ms,
                    curve: Curves.easeOut,
                  ),

              const SizedBox(height: 8),

              // --- ANIMASI SUBTEXT DISESUAIKAN ---
              const Text(
                'Platform Informasi & Edukasi Islami',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Color(0xFF78909C)),
              ).animate().fadeIn(
                delay: 1400.ms, // Delay disesuaikan
                duration: 1000.ms, // Durasi diperlama
              ),

              const SizedBox(height: 40),

              // SECTION LOADING / ERROR
              if (_errorMessage != null) ...[
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: Colors.redAccent),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _startFlow,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Coba Lagi'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0D8B8B),
                    side: const BorderSide(color: Color(0xFF0D8B8B)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ] else ...[
                // Menggunakan variabel _isLoading lokal
                SizedBox(
                  width: 22,
                  height: 22,
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF0D8B8B),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                const SizedBox(height: 16),

                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    _isLoading ? 'loading...' : '',
                    key: ValueKey(_isLoading),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF78909C),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:async';
import 'dart:math' as math;

import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';

class QiblaPage extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String locationName;

  const QiblaPage({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.locationName,
  });

  @override
  State<QiblaPage> createState() => _QiblaPageState();
}

class _QiblaPageState extends State<QiblaPage> {
  double _heading = 0.0;
  double _qiblaDirection = 0.0;

  bool _compassAvailable = true;

  StreamSubscription<CompassEvent>? _compassSubscription;

  // ---------------------------------------------------------------------------
  // SELISIH ARAH HP DENGAN ARAH KIBLAT
  // ---------------------------------------------------------------------------
  double get _qiblaOffset {
    return ((_qiblaDirection - _heading + 540) % 360) - 180;
  }

  // ---------------------------------------------------------------------------
  // INIT
  // ---------------------------------------------------------------------------
  @override
  void initState() {
    super.initState();

    _calculateQibla();
    _startCompass();
  }

  @override
  void didUpdateWidget(covariant QiblaPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Cek apakah koordinat latitude atau longitude berubah
    if (oldWidget.latitude != widget.latitude ||
        oldWidget.longitude != widget.longitude) {
      _calculateQibla();
    }
  }

  // ---------------------------------------------------------------------------
  // DISPOSE
  // ---------------------------------------------------------------------------
  @override
  void dispose() {
    _compassSubscription?.cancel();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // HITUNG ARAH KIBLAT
  // ---------------------------------------------------------------------------
  void _calculateQibla() {
    final coordinates = Coordinates(widget.latitude, widget.longitude);

    final qibla = Qibla(coordinates);

    setState(() {
      _qiblaDirection = qibla.direction;
    });
  }

  // ---------------------------------------------------------------------------
  // KOMPAS REALTIME
  // ---------------------------------------------------------------------------
  void _startCompass() {
    _compassSubscription = FlutterCompass.events?.listen(
      (CompassEvent event) {
        final heading = event.heading;

        // Beberapa HP bisa mengembalikan null
        if (heading == null) {
          if (mounted) {
            setState(() {
              _compassAvailable = false;
            });
          }
          return;
        }

        // Normalisasi nilai heading ke 0 - 360
        final normalizedHeading = (heading + 360) % 360;

        if (!mounted) return;

        setState(() {
          _heading = normalizedHeading;
          _compassAvailable = true;
        });
      },
      onError: (error) {
        if (!mounted) return;

        setState(() {
          _compassAvailable = false;
        });
      },
    );
  }

  // ---------------------------------------------------------------------------
  // NAMA ARAH
  // ---------------------------------------------------------------------------
  String _getDirectionName(double degree) {
    final normalized = (degree + 360) % 360;

    if (normalized >= 337.5 || normalized < 22.5) {
      return 'Utara';
    } else if (normalized < 67.5) {
      return 'Timur Laut';
    } else if (normalized < 112.5) {
      return 'Timur';
    } else if (normalized < 157.5) {
      return 'Tenggara';
    } else if (normalized < 202.5) {
      return 'Selatan';
    } else if (normalized < 247.5) {
      return 'Barat Daya';
    } else if (normalized < 292.5) {
      return 'Barat';
    } else {
      return 'Barat Laut';
    }
  }

  // ---------------------------------------------------------------------------
  // STATUS MENGHADAP KIBLAT
  // ---------------------------------------------------------------------------
  bool get _isFacingQibla {
    return _qiblaOffset.abs() <= 5;
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    const tealPrimary = Color(0xFF0D8B8B);
    const tealDark = Color(0xFF006666);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),

      // -----------------------------------------------------------------------
      // APP BAR
      // -----------------------------------------------------------------------
      appBar: AppBar(
        elevation: 0,
        backgroundColor: tealPrimary,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'Arah Kiblat',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),

      // -----------------------------------------------------------------------
      // BODY
      // -----------------------------------------------------------------------
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // ===============================================================
              // LOKASI
              // ===============================================================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: tealPrimary.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(
                        Icons.location_on_outlined,
                        color: tealPrimary,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Lokasi Anda',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),

                          const SizedBox(height: 3),

                          Text(
                            widget.locationName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // ===============================================================
              // STATUS KOMPAS
              // ===============================================================
              if (!_compassAvailable)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.orange.withOpacity(0.30)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.orange),

                      SizedBox(width: 10),

                      Expanded(
                        child: Text(
                          'Sensor kompas tidak tersedia atau tidak dapat membaca arah pada perangkat ini.',
                          style: TextStyle(fontSize: 12, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),

              // ===============================================================
              // STATUS KIBLAT
              // ===============================================================
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  color: _isFacingQibla
                      ? tealPrimary.withOpacity(0.10)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _isFacingQibla
                        ? tealPrimary.withOpacity(0.30)
                        : Colors.grey.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isFacingQibla
                          ? Icons.check_circle
                          : Icons.explore_outlined,
                      color: _isFacingQibla ? tealPrimary : Colors.black54,
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: Text(
                        _isFacingQibla
                            ? 'Anda menghadap arah kiblat'
                            : 'Putar HP hingga indikator menuju kiblat',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _isFacingQibla ? tealDark : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // ===============================================================
              // KOMPAS
              // ===============================================================
              SizedBox(
                width: 310,
                height: 310,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // ---------------------------------------------------------
                    // LINGKARAN LUAR
                    // ---------------------------------------------------------
                    Container(
                      width: 290,
                      height: 290,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                    ),

                    // ---------------------------------------------------------
                    // KOMPAS
                    //
                    // Kompas akan berputar mengikuti arah HP.
                    // ---------------------------------------------------------
                    Transform.rotate(
                      angle: -_heading * math.pi / 180,
                      child: SizedBox(
                        width: 270,
                        height: 270,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Lingkaran kompas
                            Container(
                              width: 250,
                              height: 250,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: tealPrimary.withOpacity(0.18),
                                  width: 2,
                                ),
                              ),
                            ),

                            // -------------------------------------------------
                            // UTARA
                            // -------------------------------------------------
                            const Positioned(
                              top: 8,
                              child: Text(
                                'U',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            ),

                            // -------------------------------------------------
                            // TIMUR
                            // -------------------------------------------------
                            const Positioned(
                              right: 8,
                              child: Text(
                                'T',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            // -------------------------------------------------
                            // SELATAN
                            // -------------------------------------------------
                            const Positioned(
                              bottom: 8,
                              child: Text(
                                'S',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            // -------------------------------------------------
                            // BARAT
                            // -------------------------------------------------
                            const Positioned(
                              left: 8,
                              child: Text(
                                'B',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            // -------------------------------------------------
                            // TANDA DERAJAT
                            // -------------------------------------------------
                            for (int i = 0; i < 8; i++)
                              Transform.rotate(
                                angle: i * math.pi / 4,
                                child: Align(
                                  alignment: Alignment.topCenter,
                                  child: Container(
                                    margin: const EdgeInsets.only(top: 30),
                                    width: 2,
                                    height: 12,
                                    color: Colors.black26,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    // =========================================================
                    // INDIKATOR KIBLAT
                    // =========================================================
                    Transform.rotate(
                      angle: _qiblaOffset * math.pi / 180,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Container(
                          margin: const EdgeInsets.only(top: 18),
                          width: 6,
                          height: 125,
                          decoration: BoxDecoration(
                            color: tealPrimary,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: tealPrimary.withOpacity(0.35),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // =========================================================
                    // ICON KIBLAT
                    // =========================================================
                    Transform.rotate(
                      angle: _qiblaOffset * math.pi / 180,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Container(
                          margin: const EdgeInsets.only(top: 0),
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(
                            color: tealPrimary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.mosque_outlined,
                            color: Colors.white,
                            size: 25,
                          ),
                        ),
                      ),
                    ),

                    // =========================================================
                    // TITIK TENGAH
                    // =========================================================
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: tealPrimary, width: 4),
                      ),
                    ),

                    // =========================================================
                    // PENUNJUK UTARA HP
                    // =========================================================
                    const Positioned(
                      top: 0,
                      child: Icon(
                        Icons.navigation_rounded,
                        color: Colors.red,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // ===============================================================
              // INFORMASI ARAH KIBLAT
              // ===============================================================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                decoration: BoxDecoration(
                  color: tealPrimary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Arah Kiblat',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      '${_qiblaDirection.toStringAsFixed(1)}°',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      _getDirectionName(_qiblaDirection),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ===============================================================
              // ARAH HP SEKARANG
              // ===============================================================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.explore_outlined,
                          size: 20,
                          color: Colors.black54,
                        ),

                        SizedBox(width: 8),

                        Text(
                          'Arah HP saat ini',
                          style: TextStyle(fontSize: 13, color: Colors.black54),
                        ),
                      ],
                    ),

                    Text(
                      '${_heading.toStringAsFixed(1)}°',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ===============================================================
              // POSISI HP
              // ===============================================================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Selisih dari arah kiblat',
                      style: TextStyle(fontSize: 13, color: Colors.black54),
                    ),

                    Text(
                      '${_qiblaOffset.abs().toStringAsFixed(1)}°',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: _isFacingQibla ? tealPrimary : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ===============================================================
              // PETUNJUK
              // ===============================================================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: tealPrimary),

                    SizedBox(width: 12),

                    Expanded(
                      child: Text(
                        'Untuk hasil yang lebih akurat, jauhkan HP dari benda yang mengandung magnet atau logam. Jika arah kompas terasa tidak stabil, lakukan kalibrasi sensor dengan menggerakkan HP perlahan.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

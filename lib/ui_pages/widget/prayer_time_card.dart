import 'dart:async';
import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

class PrayerTimeCard extends StatefulWidget {
  const PrayerTimeCard({super.key});

  @override
  State<PrayerTimeCard> createState() => _PrayerTimeCardState();
}

class _PrayerTimeCardState extends State<PrayerTimeCard> {
  String _locationName = "Mendapatkan lokasi...";
  String _nextPrayerName = "-";
  String _nextPrayerTimeStr = "-:-";
  Duration _timeRemaining = Duration.zero;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initPrayerTimes();
    // Update countdown setiap detik
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateCountdown(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  PrayerTimes? _prayerTimes;

  Future<void> _initPrayerTimes() async {
    try {
      // 1. Cek & minta izin lokasi
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      Position position;
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
        );
        setState(() {
          _locationName =
              "${position.latitude.toStringAsFixed(2)}°, ${position.longitude.toStringAsFixed(2)}°";
        });
      } else {
        // Default koordinat jika izin ditolak (Contoh: Surabaya)
        position = Position(
          latitude: -7.2575,
          longitude: 112.7521,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );
        setState(() {
          _locationName = "Surabaya (Default)";
        });
      }

      // 2. Hitung waktu sholat berdasarkan koordinat
      final coordinates = Coordinates(position.latitude, position.longitude);
      final params = CalculationMethod.singapore.getParameters();
      params.madhab = Madhab.shafi; // Mazhab Syafi'i (standar Indonesia)

      _prayerTimes = PrayerTimes.today(coordinates, params);
      _updateCountdown();
    } catch (e) {
      setState(() {
        _locationName = "Lokasi tidak tersedia";
      });
    }
  }

  void _updateCountdown() {
    if (_prayerTimes == null) return;

    final now = DateTime.now();
    final nextPrayer = _prayerTimes!.nextPrayer();
    final nextTime = _prayerTimes!.timeForPrayer(nextPrayer);

    if (nextTime != null) {
      setState(() {
        _nextPrayerName = _getPrayerNameInIndonesian(nextPrayer);
        _nextPrayerTimeStr = DateFormat('HH:mm').format(nextTime.toLocal());
        _timeRemaining = nextTime.difference(now);
      });
    } else {
      // Jika sudah lewat Isya, hitung untuk Subuh besok
      setState(() {
        _nextPrayerName = "Subuh (Besok)";
        _nextPrayerTimeStr = DateFormat(
          'HH:mm',
        ).format(_prayerTimes!.fajr.add(const Duration(days: 1)).toLocal());
        _timeRemaining = _prayerTimes!.fajr
            .add(const Duration(days: 1))
            .difference(now);
      });
    }
  }

  String _getPrayerNameInIndonesian(Prayer prayer) {
    switch (prayer) {
      case Prayer.fajr:
        return 'Subuh';
      case Prayer.sunrise:
        return 'Terbit';
      case Prayer.dhuhr:
        return 'Dzuhur';
      case Prayer.asr:
        return 'Ashar';
      case Prayer.maghrib:
        return 'Maghrib';
      case Prayer.isha:
        return 'Isya';
      default:
        return 'Subuh';
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.isNegative) return "00:00:00";
    String hours = duration.inHours.remainder(24).toString().padLeft(2, '0');
    String minutes = duration.inMinutes
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    String seconds = duration.inSeconds
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    return "$hours:$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        children: [
          // Row Lokasi
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_on, color: Colors.amber, size: 14),
              const SizedBox(width: 4),
              Text(
                _locationName,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Teks Jadwal Sholat Berikutnya
          Text(
            'Menuju $_nextPrayerName pukul $_nextPrayerTimeStr WIB',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),

          // Countdown Waktu Kurang Berapa
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.timer_outlined,
                color: Colors.amberAccent,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                '-${_formatDuration(_timeRemaining)}',
                style: const TextStyle(
                  color: Colors.amberAccent,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

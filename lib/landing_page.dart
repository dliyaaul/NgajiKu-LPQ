import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:ptl_mobile/ui_pages/auth/login_page.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ptl_mobile/models/location_model.dart';
import 'package:ptl_mobile/services/location_service.dart';
import 'package:ptl_mobile/ui_pages/widget/feature_menu.dart';
import 'package:ptl_mobile/ui_pages/widget/mading_section.dart';
import 'package:ptl_mobile/ui_pages/widget/media_section.dart';
import 'package:ptl_mobile/ui_pages/widget/qibla_page.dart';

// -----------------------------------------------------------------------------
// FUNGSI UTAMA PENENTUAN LOKASI GPS
// -----------------------------------------------------------------------------
Future<Position> determinePosition() async {
  bool serviceEnabled;
  LocationPermission permission;

  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    return Future.error('Layanan lokasi/GPS mati. Silakan aktifkan GPS Anda.');
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return Future.error('Izin lokasi ditolak oleh pengguna.');
    }
  }

  if (permission == LocationPermission.deniedForever) {
    return Future.error('Izin lokasi ditolak permanen. Ubah di pengaturan HP.');
  }

  return await Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.low,
  );
}

// -----------------------------------------------------------------------------
// WIDGET UTAMA LANDING PAGE
// -----------------------------------------------------------------------------
class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  // State Waktu Sholat & Lokasi
  String _locationName = "MENCARI LOKASI...";
  String _nextPrayerName = "Subuh";
  String _nextPrayerTimeStr = "04:00";
  int _secondsRemaining = 0;

  final LocationService _locationService = LocationService();
  final Geocoding geocoding = Geocoding();

  List<CityLocation> _locationResults = [];
  bool _isSearchingLocation = false;
  bool _isUpdatingLocation = false;

  final List<String> _backgroundImages = [
    'assets/images/header_bg1.jpg',
    'assets/images/header_bg2.jpg',
    'assets/images/header_bg3.jpg',
    'assets/images/header_bg4.jpg',
    'assets/images/header_bg5.jpg',
  ];
  int _currentBackground = 0;
  Timer? _backgroundTimer;
  Timer? _timer;
  Timer? _searchDebounceTimer;

  int _searchRequestId = 0;

  double? _latitude;
  double? _longitude;

  JadwalSholatModel? _jadwalSholat;

  @override
  void initState() {
    super.initState();
    _initPrayerSchedule();
    _startBackgroundSlider();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateCountdown(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _backgroundTimer?.cancel();
    _searchDebounceTimer?.cancel();
    super.dispose();
  }

  // Init Jadwal Sholat dari GPS
  Future<void> _initPrayerSchedule() async {
    try {
      final Position position = await determinePosition();

      _latitude = position.latitude;
      _longitude = position.longitude;

      final List<Placemark> placemarks = await geocoding
          .placemarkFromCoordinates(position.latitude, position.longitude);

      String cityName = "KOTA SURABAYA";

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        cityName =
            (place.subAdministrativeArea ?? place.locality ?? "KOTA SURABAYA")
                .toUpperCase();
      }

      // Cari ID Kota berdasarkan nama dari geocoding GPS
      final cities = await _locationService.searchLocations(cityName);
      if (cities.isNotEmpty) {
        final city = cities.first;
        final jadwal = await _locationService.getJadwalSholat(
          cityId: city.id,
          date: DateTime.now(),
        );

        setState(() {
          _locationName = city.name.toUpperCase();
          _jadwalSholat = jadwal;
        });

        _updateCountdown();
      } else {
        _useFallbackLocation();
      }
    } catch (e) {
      _useFallbackLocation();
    }
  }

  void _startBackgroundSlider() {
    _backgroundTimer = Timer.periodic(const Duration(seconds: 6), (timer) {
      if (!mounted) return;

      setState(() {
        _currentBackground =
            (_currentBackground + 1) % _backgroundImages.length;
      });
    });
  }

  Future<void> _useFallbackLocation() async {
    const latitude = -7.2575;
    const longitude = 112.7521;

    try {
      // Fallback Surabaya ID: 1638
      final jadwal = await _locationService.getJadwalSholat(
        cityId: '1638',
        date: DateTime.now(),
      );

      setState(() {
        _latitude = latitude;
        _longitude = longitude;
        _locationName = "KOTA SURABAYA";
        _jadwalSholat = jadwal;
      });

      _updateCountdown();
    } catch (_) {}
  }

  // Hitung mundur & Penentuan Waktu Sholat Berikutnya
  void _updateCountdown() {
    if (_jadwalSholat == null) return;

    final now = DateTime.now();
    DateFormat('yyyy-MM-dd').format(now);

    DateTime? parseTime(String timeStr) {
      try {
        final parts = timeStr.split(':');
        if (parts.length < 2) return null;
        return DateTime(
          now.year,
          now.month,
          now.day,
          int.parse(parts[0]),
          int.parse(parts[1]),
        );
      } catch (_) {
        return null;
      }
    }

    final times = <String, DateTime?>{
      'Subuh': parseTime(_jadwalSholat!.subuh),
      'Dzuhur': parseTime(_jadwalSholat!.dzuhur),
      'Ashar': parseTime(_jadwalSholat!.ashar),
      'Maghrib': parseTime(_jadwalSholat!.maghrib),
      'Isya': parseTime(_jadwalSholat!.isya),
    };

    String nextName = 'Subuh';
    DateTime? nextTime;

    for (var entry in times.entries) {
      if (entry.value != null && entry.value!.isAfter(now)) {
        nextName = entry.key;
        nextTime = entry.value;
        break;
      }
    }

    // Jika semua jadwal hari ini lewat, tuju Subuh besok hari
    if (nextTime == null && times['Subuh'] != null) {
      nextName = 'Subuh';
      nextTime = times['Subuh']!.add(const Duration(days: 1));
    }

    if (nextTime != null) {
      final diff = nextTime.difference(now).inSeconds;

      setState(() {
        _nextPrayerName = nextName;
        _nextPrayerTimeStr = DateFormat('HH:mm').format(nextTime!);
        _secondsRemaining = diff > 0 ? diff : 0;
      });
    }
  }

  Future<void> _searchLocation(
    String query,
    void Function(void Function()) setModalState,
  ) async {
    _searchDebounceTimer?.cancel();

    final trimmedQuery = query.trim();

    if (trimmedQuery.length < 2) {
      setModalState(() {
        _locationResults = [];
        _isSearchingLocation = false;
      });
      return;
    }

    final int requestId = ++_searchRequestId;

    setModalState(() {
      _isSearchingLocation = true;
    });

    _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () async {
      try {
        final results = await _locationService.searchLocations(trimmedQuery);

        if (!mounted) return;
        if (requestId != _searchRequestId) return;

        setModalState(() {
          _locationResults = results;
          _isSearchingLocation = false;
        });
      } catch (e) {
        if (!mounted) return;
        if (requestId != _searchRequestId) return;

        setModalState(() {
          _locationResults = [];
          _isSearchingLocation = false;
        });
      }
    });
  }

  Future<void> _selectApiLocation(CityLocation location) async {
    if (_isUpdatingLocation) return;

    setState(() {
      _isUpdatingLocation = true;
    });

    try {
      final locations = await geocoding.locationFromAddress(location.name);

      double? newLat = _latitude;
      double? newLng = _longitude;

      if (locations.isNotEmpty) {
        newLat = locations.first.latitude;
        newLng = locations.first.longitude;
      }

      final jadwal = await _locationService.getJadwalSholat(
        cityId: location.id,
        date: DateTime.now(),
      );

      if (!mounted) return;

      setState(() {
        _latitude = newLat;
        _longitude = newLng;
        _jadwalSholat = jadwal;
        _locationName = location.name.toUpperCase();
        _isUpdatingLocation = false;
      });

      _updateCountdown();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lokasi berhasil diubah ke ${location.name}.'),
          backgroundColor: const Color(0xFF0D8B8B),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isUpdatingLocation = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memperbarui jadwal sholat: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showLocationPicker() {
    final searchController = TextEditingController();
    _locationResults = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (sheetContext, setModalState) {
            return Container(
              height: MediaQuery.of(sheetContext).size.height * 0.78,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D8B8B).withOpacity(0.10),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.location_on_outlined,
                            color: Color(0xFF0D8B8B),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pilih Lokasi',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Cari kota atau kabupaten',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: TextField(
                      controller: searchController,
                      onChanged: (value) {
                        _searchLocation(value, setModalState);
                      },
                      decoration: InputDecoration(
                        hintText: 'Cari kota atau kabupaten...',
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: Color(0xFF0D8B8B),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF5F7F6),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _buildLocationResults(setModalState, modalContext),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _formatDuration(int seconds) {
    Duration duration = Duration(seconds: seconds);
    String hours = duration.inHours.toString().padLeft(2, '0');
    String minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    String secs = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return "- $hours:$minutes:$secs";
  }

  @override
  Widget build(BuildContext context) {
    const tealPrimary = Color(0xFF0D8B8B);
    const yellowAccent = Color(0xFFFFCC00);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ---------------------------------------------------------------
              // 1. HEADER SECTION (AZAN & LOKASI)
              // ---------------------------------------------------------------
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: double.infinity,
                    height: 340,
                    clipBehavior: Clip.antiAlias,
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 2000),
                          switchInCurve: Curves.easeInOutCubic,
                          switchOutCurve: Curves.easeInOutCubic,
                          child:
                              Image.asset(
                                    _backgroundImages[_currentBackground],
                                    key: ValueKey(_currentBackground),
                                    width: double.infinity,
                                    height: double.infinity,
                                    fit: BoxFit.cover,
                                  )
                                  .animate(key: ValueKey(_currentBackground))
                                  .scale(
                                    begin: const Offset(1.05, 1.05),
                                    end: const Offset(1.0, 1.0),
                                    duration: 6000.ms,
                                    curve: Curves.easeOutCubic,
                                  ),
                        ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              stops: const [0.0, 0.35, 0.75, 1.0],
                              colors: [
                                Colors.black.withOpacity(0.55),
                                Colors.black.withOpacity(0.20),
                                Colors.black.withOpacity(0.30),
                                Colors.black.withOpacity(0.70),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 25,
                    left: 0,
                    right: 0,
                    child: Padding(
                      padding: const EdgeInsets.only(
                        top: 50,
                        left: 20,
                        right: 20,
                        bottom: 45,
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                color: yellowAccent,
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _locationName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "$_nextPrayerName $_nextPrayerTimeStr",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  color: Color.fromARGB(152, 0, 0, 0),
                                  offset: Offset(0, 2),
                                  blurRadius: 5,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.30),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _formatDuration(_secondsRemaining),
                              style: const TextStyle(
                                color: yellowAccent,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 45),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ElevatedButton(
                                onPressed: _showLocationPicker,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  elevation: 0,
                                  visualDensity: VisualDensity.compact,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  minimumSize: Size.zero,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(
                                      Icons.location_on,
                                      size: 18,
                                      color: tealPrimary,
                                    ),
                                    SizedBox(width: 3),
                                    Text(
                                      "Ubah Lokasi",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: tealPrimary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  if (_latitude == null || _longitude == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Koordinat lokasi belum tersedia.',
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => QiblaPage(
                                        latitude: _latitude!,
                                        longitude: _longitude!,
                                        locationName: _locationName,
                                      ),
                                    ),
                                  );
                                },
                                child: Row(
                                  children: const [
                                    Icon(
                                      Icons.explore_outlined,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      "Arah Kiblat",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 42,
                    right: 20,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset(
                          'assets/images/Ngajiku_Homescreen.svg',
                          width: 40,
                          height: 40,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: -28,
                    left: 16,
                    right: 16,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: const BoxDecoration(
                                color: Color(0xFF00C4EE),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.logout_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  "Keluarga Tilawati,",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  "Login Dulu Yuk !",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 44),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.search, color: tealPrimary, size: 20),
                      SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: "cari doa/kajian/konten dll",
                            hintStyle: TextStyle(
                              color: Colors.black38,
                              fontSize: 13,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const FeatureMenu(),
              const SizedBox(height: 24),
              const MadingSection(),
              const MediaSection(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationResults(
    void Function(void Function()) setModalState,
    BuildContext modalContext,
  ) {
    if (_isSearchingLocation) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF0D8B8B)),
      );
    }

    if (_locationResults.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.location_searching_rounded,
                size: 52,
                color: Colors.black26,
              ),
              SizedBox(height: 12),
              Text(
                'Cari kota atau kabupaten',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 5),
              Text(
                'Ketik minimal 2 karakter untuk mencari lokasi.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 30),
      itemCount: _locationResults.length,
      itemBuilder: (context, index) {
        final location = _locationResults[index];

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 3,
          ),
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF0D8B8B).withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.location_city_outlined,
              color: Color(0xFF0D8B8B),
            ),
          ),
          title: Text(
            location.name,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
          onTap: _isUpdatingLocation
              ? null
              : () async {
                  Navigator.of(modalContext).pop();
                  await _selectApiLocation(location);
                },
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'attendance_module.dart';
import 'bbaq/web_bbaq_classes_page.dart';

class WebAttendanceHome extends StatefulWidget {
  const WebAttendanceHome({super.key});

  @override
  State<WebAttendanceHome> createState() => _WebAttendanceHomeState();
}

class _WebAttendanceHomeState extends State<WebAttendanceHome> {
  final _supabase = Supabase.instance.client;

  Map<String, dynamic>? _profile;
  bool _loadingProfile = true;
  bool _loggingOut = false;

  static const _primaryColor = Color(0xFF0D8B8B);

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final user = _supabase.auth.currentUser;

      if (user == null) {
        if (mounted) {
          setState(() => _loadingProfile = false);
        }
        return;
      }

      final result = await _supabase
          .from('profiles')
          .select('username, avatar_url')
          .eq('id', user.id)
          .maybeSingle();

      if (!mounted) return;

      setState(() {
        _profile = result;
        _loadingProfile = false;
      });
    } catch (e) {
      debugPrint('Gagal memuat profil: $e');

      if (!mounted) return;

      setState(() => _loadingProfile = false);
    }
  }

  String get _displayName {
    final username = _profile?['username']?.toString().trim();

    if (username != null && username.isNotEmpty) {
      return username;
    }

    return _supabase.auth.currentUser?.email ?? 'Pengguna';
  }

  String? get _photoUrl {
    final value = _profile?['avatar_url']?.toString().trim();

    if (value == null || value.isEmpty) return null;
    return value;
  }

  Future<void> _logout() async {
    if (_loggingOut) return;

    setState(() => _loggingOut = true);

    try {
      await _supabase.auth.signOut();
    } catch (e) {
      if (!mounted) return;

      setState(() => _loggingOut = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal logout: $e')));
    }
  }

  void _showProfile() {
    final user = _supabase.auth.currentUser;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Profil Pengguna'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAvatar(size: 76),
              const SizedBox(height: 16),
              Text(
                _displayName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                user?.email ?? '-',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAvatar({double size = 40}) {
    final photo = _photoUrl;

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: const Color(0xFFE2F4F2),
      backgroundImage: photo != null ? NetworkImage(photo) : null,
      onBackgroundImageError: photo != null
          ? (exception, stackTrace) {
              debugPrint('Gagal memuat foto profil: $exception');
            }
          : null,
      child: photo == null
          ? Text(
              _displayName.isNotEmpty ? _displayName[0].toUpperCase() : 'U',
              style: const TextStyle(
                color: _primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _supabase.auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Absensi PTL Mobile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (!_loadingProfile)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: PopupMenuButton<String>(
                tooltip: 'Menu akun',
                onSelected: (value) {
                  switch (value) {
                    case 'profile':
                      _showProfile();
                      break;
                    case 'logout':
                      _logout();
                      break;
                  }
                },
                offset: const Offset(0, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                itemBuilder: (context) => [
                  PopupMenuItem<String>(
                    value: 'profile',
                    child: Row(
                      children: [
                        const Icon(Icons.person_outline_rounded),
                        const SizedBox(width: 12),
                        const Text('Profil'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem<String>(
                    value: 'logout',
                    child: Row(
                      children: [
                        const Icon(Icons.logout_rounded, color: Colors.red),
                        const SizedBox(width: 12),
                        Text(
                          'Logout',
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ],
                    ),
                  ),
                ],
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (MediaQuery.sizeOf(context).width >= 600) ...[
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _displayName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            user?.email ?? '',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 10),
                    ],
                    _buildAvatar(),
                    const SizedBox(width: 4),
                    const Icon(Icons.keyboard_arrow_down_rounded),
                  ],
                ),
              ),
            ),
          if (_loggingOut)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _primaryColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.fact_check_outlined,
                      size: 38,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Pusat Absensi',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Selamat datang, $_displayName',
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Pilih program untuk membuka modul absensinya.',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Program Absensi',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 700 ? 2 : 1;

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: attendanceModules.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      mainAxisExtent: 116,
                    ),
                    itemBuilder: (context, index) {
                      final module = attendanceModules[index];

                      return Card(
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () {
                            if (module.id == 'bbaq') {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const WebBbaqClassesPage(),
                                ),
                              );
                              return;
                            }

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Modul ${module.title} akan diintegrasikan berikutnya.',
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE2F4F2),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(
                                    _iconFor(module.iconKey),
                                    color: _primaryColor,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        module.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        module.description,
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right_rounded),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconFor(String key) {
    switch (key) {
      case 'menu_book':
        return Icons.menu_book_rounded;
      case 'auto_stories':
        return Icons.auto_stories_rounded;
      case 'translate':
        return Icons.translate_rounded;
      case 'school':
        return Icons.school_rounded;
      default:
        return Icons.fact_check_outlined;
    }
  }
}

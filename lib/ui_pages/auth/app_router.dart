import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ptl_mobile/landing_page.dart';
import 'package:ptl_mobile/ui_pages/dashboard/pengajar/pengajar_page.dart';

import '../../state_management/auth_provider.dart';

import '../dashboard/admin/admin_page.dart';
import '../dashboard/staff/staff_page.dart';
import '../dashboard/santri/santri_page.dart';

class AppRouter extends StatelessWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    // Masih mengecek session
    if (!authProvider.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Belum login
    if (!authProvider.isLoggedIn) {
      return const LandingPage();
    }

    // Ambil nama user dari AuthProvider (dengan fallback)
    final String displayName = authProvider.userName ?? 'Pengguna';

    // Arahkan ke halaman berdasarkan Role
    if (authProvider.isAdmin) {
      return AdminPage(userName: displayName);
    }
    if (authProvider.isStaff) {
      return StaffPage(userName: displayName);
    }

    if (authProvider.isPengajar) {
      return PengajarPage(userName: displayName);
    }

    if (authProvider.isSantri) {
      return SantriPage(userName: displayName);
    }

    // Role tidak dikenali
    return const Scaffold(
      body: Center(child: Text('Role pengguna tidak dikenali.')),
    );
  }
}

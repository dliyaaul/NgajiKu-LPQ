import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ptl_mobile/state_management/auth_provider.dart';
import 'package:ptl_mobile/ui_pages/dashboard/admin/beranda_admin_tab.dart';
import 'package:ptl_mobile/ui_pages/dashboard/base_dashboard_template.dart';

class AdminPage extends StatelessWidget {
  final String userName;

  const AdminPage({super.key, required this.userName});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final profile = authProvider.userProfile ?? {};

    final avatar = profile['avatar_url']?.toString();

    return BaseDashboardTemplate(
      userName: profile['username']?.toString() ?? userName,
      roleLabel: 'Admin Pesantren',
      avatarUrl: avatar,
      body: const BerandaAdminTab(),
    );
  }
}

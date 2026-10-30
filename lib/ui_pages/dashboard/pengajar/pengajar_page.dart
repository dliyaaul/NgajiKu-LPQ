import 'package:flutter/material.dart';
import 'package:ptl_mobile/ui_pages/dashboard/base_dashboard_template.dart';
import 'package:ptl_mobile/ui_pages/dashboard/pengajar/beranda_pengajar_tab.dart';

class PengajarPage extends StatelessWidget {
  final String userName;

  const PengajarPage({super.key, required this.userName});

  @override
  Widget build(BuildContext context) {
    return BaseDashboardTemplate(
      userName: userName,
      roleLabel: 'Pengajar',      
      body: const BerandaPengajarTab(),
    );
  }
}

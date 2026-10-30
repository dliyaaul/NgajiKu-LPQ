import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class AttendanceWebHandoffService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> openAttendanceWeb({required String pertemuanId}) async {
    if (kIsWeb) {
      throw UnsupportedError(
        'Handoff ini hanya dipanggil dari aplikasi Android.',
      );
    }

    final session = _supabase.auth.currentSession;

    if (session == null) {
      throw Exception('Sesi login tidak ditemukan. Silakan login kembali.');
    }

    final response = await _supabase.functions.invoke(
      'attendance-web-handoff',
      method: HttpMethod.post,
      body: {'pertemuan_id': pertemuanId},
    );

    final data = response.data;

    if (response.status < 200 || response.status >= 300) {
      throw Exception('Backend gagal menyiapkan akses Web.');
    }

    if (data is! Map || data['action_url'] is! String) {
      throw Exception('Respons handoff dari backend tidak valid.');
    }

    final actionUrl = Uri.tryParse(data['action_url'] as String);

    if (actionUrl == null ||
        actionUrl.scheme != 'https' ||
        actionUrl.host.isEmpty) {
      throw Exception('Alamat autentikasi Web tidak valid.');
    }

    final opened = await launchUrl(
      actionUrl,
      mode: LaunchMode.externalApplication,
    );

    if (!opened) {
      throw Exception('Browser tidak dapat dibuka.');
    }
  }
}

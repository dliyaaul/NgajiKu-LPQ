import 'package:supabase_flutter/supabase_flutter.dart';

class AttendanceWebTestService {
  static Future<void> testHandoff() async {
    final supabase = Supabase.instance.client;
    final session = supabase.auth.currentSession;

    if (session == null || session.isExpired) {
      print('Sesi tidak tersedia atau sudah kedaluwarsa.');
      return;
    }

    try {
      final response = await supabase.functions.invoke(
        'attendance-web-handoff',
        method: HttpMethod.post,
      );

      print('Handoff HTTP status: ${response.status}');
      print('Handoff response: ${response.data}');
    } on FunctionException catch (e) {
      print('Handoff HTTP status: ${e.status}');
      print('Handoff error: ${e.details}');
    } catch (e) {
      print('Handoff gagal: $e');
    }
  }
}

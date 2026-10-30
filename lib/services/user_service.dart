import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

class UserService {
  final SupabaseClient _supabase = SupabaseService.client;

  Future<Map<String, dynamic>> createUser({
    required String email,
    required String password,
    required String username,
    String? alamat,
    String? no_hp,
    required String role,
  }) async {
    final response = await _supabase.functions.invoke(
      'create-user',
      body: {
        'email': email,
        'password': password,
        'username': username,
        'alamat': alamat,
        'no_hp': no_hp,
        'role': role,
      },
    );

    final data = response.data;

    if (data is! Map) {
      throw Exception('Response dari server tidak valid.');
    }

    if (data['success'] != true) {
      throw Exception(data['message'] ?? 'Gagal membuat pengguna.');
    }

    return Map<String, dynamic>.from(data);
  }
}

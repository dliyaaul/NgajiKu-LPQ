import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'web_attendance_home.dart';

class WebAuthGate extends StatelessWidget {
  const WebAuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Supabase.instance.client.auth;

    return StreamBuilder<AuthState>(
      stream: auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = auth.currentSession;

        if (session != null) {
          return const WebAttendanceHome();
        }

        return Scaffold(
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Card(
                margin: const EdgeInsets.all(24),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.verified_user_outlined,
                        size: 52,
                        color: Color(0xFF0D8B8B),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Absensi PTL Mobile',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Sesi browser belum tersedia. Buka absensi '
                        'melalui aplikasi Android PTL Mobile untuk '
                        'melanjutkan proses autentikasi.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      OutlinedButton.icon(
                        onPressed: () async {
                          await auth.refreshSession();
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Periksa Sesi Lagi'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../state_management/auth_provider.dart';

class StaffPage extends StatelessWidget {
  final String userName;
  const StaffPage({super.key, required this.userName});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Staff'),
        actions: [
          IconButton(
            onPressed: () async {
              await authProvider.logout();
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: Text(
          'Selamat datang Staff ${user?.username}',
          style: const TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class TestConnectionPage extends StatefulWidget {
  const TestConnectionPage({super.key});

  @override
  State<TestConnectionPage> createState() => _TestConnectionPageState();
}

class _TestConnectionPageState extends State<TestConnectionPage> {
  String message = 'Mengambil data...';

  @override
  void initState() {
    super.initState();
    testConnection();
  }

  Future<void> testConnection() async {
    try {
      final response = await SupabaseService.client.from('profiles').select();

      setState(() {
        message = 'Berhasil! Data: $response';
      });
    } catch (e) {
      setState(() {
        message = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test Supabase')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(message, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}

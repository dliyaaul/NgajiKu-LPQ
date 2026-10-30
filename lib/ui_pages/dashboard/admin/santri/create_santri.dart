import 'package:flutter/material.dart';
import 'package:ptl_mobile/ui_pages/widget/santri_form.dart';
import 'package:ptl_mobile/models/santri_form_mode.dart';

const Color _primaryColor = Color(0xFF0D8B8B);
const Color _backgroundColor = Color(0xFFF8FAFA);

class TambahSantriPage extends StatelessWidget {
  const TambahSantriPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Tambah Santri',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: _primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SantriForm(
          mode: SantriFormMode.add,
          onSubmitSuccess: () => Navigator.pop(context, true),
        ),
      ),
    );
  }
}

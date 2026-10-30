import 'package:flutter/material.dart';
import 'package:ptl_mobile/ui_pages/widget/santri_form.dart';
import 'package:ptl_mobile/models/santri_form_mode.dart';

const Color _primaryColor = Color(0xFF0D8B8B);
const Color _backgroundColor = Color(0xFFF8FAFA);

class EditSantriPage extends StatelessWidget {
  final Map<String, dynamic> santri;

  const EditSantriPage({super.key, required this.santri});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Edit Data Santri',
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
          mode: SantriFormMode.edit,
          santri: santri,
          onSubmitSuccess: () => Navigator.pop(context, true),
        ),
      ),
    );
  }
}

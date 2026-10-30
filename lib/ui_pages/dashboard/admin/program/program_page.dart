import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ptl_mobile/state_management/loading_provider.dart';

import '../../../../state_management/program_provider.dart';
import '../../../../models/program/program_model.dart';

const Color _primaryColor = Color(0xFF0D8B8B);
const Color _backgroundColor = Color(0xFFF8FAFA);
const Color _textColor = Color(0xFF263238);
const Color _secondaryTextColor = Color(0xFF607D8B);

class ProgramPage extends StatefulWidget {
  const ProgramPage({super.key});

  @override
  State<ProgramPage> createState() => _ProgramPageState();
}

class _ProgramPageState extends State<ProgramPage> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final programProvider = context.read<ProgramProvider>();

      final loadingProvider = context.read<LoadingProvider>();

      programProvider.loadAll(loadingProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Program',
          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
        ),
        backgroundColor: _primaryColor,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showProgramForm(),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: Consumer<ProgramProvider>(
        builder: (context, provider, child) {
          if (provider.errorMessage != null && !provider.hasData) {
            return _buildErrorState(provider);
          }

          if (!provider.hasData) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            color: _primaryColor,
            onRefresh: () {
              return context.read<ProgramProvider>().refresh(
                context.read<LoadingProvider>(),
              );
            },
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: provider.items.length,
              itemBuilder: (context, index) {
                final program = provider.items[index];

                return _buildProgramCard(program, provider);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgramCard(ProgramModel program, ProgramProvider provider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.menu_book_rounded,
                color: _primaryColor,
                size: 25,
              ),
            ),
            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    program.nama,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _textColor,
                    ),
                  ),

                  if (program.deskripsi != null &&
                      program.deskripsi!.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      program.deskripsi!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: _secondaryTextColor,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _showProgramForm(program: program);
                } else if (value == 'delete') {
                  _confirmDelete(program, provider);
                }
              },
              itemBuilder: (context) {
                return const [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 20),
                        SizedBox(width: 10),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 20, color: Colors.red),
                        SizedBox(width: 10),
                        Text('Hapus', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ];
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      color: _primaryColor,
      onRefresh: () {
        return context.read<ProgramProvider>().refresh(LoadingProvider());
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.3),
          const Icon(
            Icons.menu_book_outlined,
            size: 64,
            color: _secondaryTextColor,
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'Belum ada program',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: _textColor,
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Center(
            child: Text(
              'Tambahkan program pembelajaran terlebih dahulu.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: _secondaryTextColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ProgramProvider provider) {
    return RefreshIndicator(
      color: _primaryColor,
      onRefresh: () {
        return context.read<ProgramProvider>().refresh(
          context.read<LoadingProvider>(),
        );
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.25),
          const Icon(
            Icons.cloud_off_rounded,
            size: 60,
            color: Colors.redAccent,
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'Gagal memuat program',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: _textColor,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              provider.errorMessage ?? 'Terjadi kesalahan.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: _secondaryTextColor),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton.icon(
              onPressed: () {
                provider.refresh(context.read<LoadingProvider>());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showProgramForm({ProgramModel? program}) async {
    final isEdit = program != null;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _ProgramFormSheet(program: program, isEdit: isEdit);
      },
    );

    if (!mounted) return;

    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEdit
                ? 'Program berhasil diperbarui'
                : 'Program berhasil ditambahkan',
          ),
          backgroundColor: _primaryColor,
        ),
      );
    }
  }

  Future<void> _confirmDelete(
    ProgramModel program,
    ProgramProvider provider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Hapus Program?',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          content: Text(
            'Program "${program.nama}" akan dihapus. '
            'Pastikan program ini tidak sedang digunakan '
            'oleh data santri.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final success = await provider.delete(
      program.id,
      loadingProvider: context.read<LoadingProvider>(),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Program berhasil dihapus'
              : provider.errorMessage ?? 'Gagal menghapus program',
        ),
        backgroundColor: success ? _primaryColor : Colors.redAccent,
      ),
    );
  }
}

class _ProgramFormSheet extends StatefulWidget {
  final ProgramModel? program;
  final bool isEdit;

  const _ProgramFormSheet({required this.program, required this.isEdit});

  @override
  State<_ProgramFormSheet> createState() => _ProgramFormSheetState();
}

class _ProgramFormSheetState extends State<_ProgramFormSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _namaController;
  late final TextEditingController _deskripsiController;

  @override
  void initState() {
    super.initState();

    _namaController = TextEditingController(text: widget.program?.nama ?? '');

    _deskripsiController = TextEditingController(
      text: widget.program?.deskripsi ?? '',
    );
  }

  @override
  void dispose() {
    _namaController.dispose();
    _deskripsiController.dispose();

    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final provider = context.read<ProgramProvider>();
    final loadingProvider = context.read<LoadingProvider>();

    bool success;

    if (widget.isEdit) {
      success = await provider.update(
        ProgramModel(
          id: widget.program!.id,
          nama: _namaController.text.trim(),
          deskripsi: _deskripsiController.text.trim().isEmpty
              ? null
              : _deskripsiController.text.trim(),
        ),
        loadingProvider: loadingProvider,
      );
    } else {
      success = await provider.create(
        nama: _namaController.text.trim(),
        deskripsi: _deskripsiController.text.trim().isEmpty
            ? null
            : _deskripsiController.text.trim(),
        loadingProvider: loadingProvider,
      );
    }

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Consumer<ProgramProvider>(
              builder: (context, provider, child) {
                return Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        Text(
                          widget.isEdit ? 'Edit Program' : 'Tambah Program',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: _textColor,
                          ),
                        ),

                        const SizedBox(height: 20),

                        TextFormField(
                          controller: _namaController,
                          textInputAction: TextInputAction.next,
                          enabled: !provider.isSaving,
                          decoration: InputDecoration(
                            labelText: 'Nama Program',
                            hintText: 'Contoh: Tahfidz Al-Qur\'an',
                            prefixIcon: const Icon(Icons.menu_book_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: _primaryColor,
                                width: 1.5,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Nama program wajib diisi';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 14),

                        TextFormField(
                          controller: _deskripsiController,
                          enabled: !provider.isSaving,
                          maxLines: 4,
                          decoration: InputDecoration(
                            labelText: 'Deskripsi',
                            hintText: 'Masukkan deskripsi program (opsional)',
                            prefixIcon: const Padding(
                              padding: EdgeInsets.only(bottom: 55),
                              child: Icon(Icons.description_outlined),
                            ),
                            alignLabelWithHint: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: _primaryColor,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: provider.isSaving ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryColor,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.grey.shade300,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: provider.isSaving
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    widget.isEdit
                                        ? 'Simpan Perubahan'
                                        : 'Tambah Program',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),

                        if (provider.errorMessage != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            provider.errorMessage!,
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

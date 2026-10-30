import 'package:flutter/material.dart';
import 'package:ptl_mobile/models/program/program_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const Color _primaryColor = Color(0xFF0D8B8B);
const Color _backgroundColor = Color(0xFFF8FAFA);
const Color _textColor = Color(0xFF263238);
const Color _secondaryTextColor = Color(0xFF607D8B);
const Color _borderColor = Color(0xFFECEFF1);

class KelolaProgramPage extends StatefulWidget {
  const KelolaProgramPage({super.key});

  @override
  State<KelolaProgramPage> createState() => _KelolaProgramPageState();
}

class _KelolaProgramPageState extends State<KelolaProgramPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<ProgramModel> _programList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPrograms();
  }

  // READ: Mengambil daftar program dari Supabase
  Future<void> _fetchPrograms() async {
    if (mounted) setState(() => _isLoading = true);

    try {
      final response = await _supabase
          .from('programs')
          .select('*')
          .order('created_at', ascending: true);

      if (!mounted) return;
      setState(() {
        _programList = (response as List)
            .map((json) => ProgramModel.fromMap(json))
            .toList();
        _isLoading = false;
      });
    } on PostgrestException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnackBar('Gagal memuat program: ${e.message}', isError: true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnackBar('Terjadi kesalahan: $e', isError: true);
    }
  }

  // CREATE / UPDATE Dialog Form
  void _showProgramFormDialog({ProgramModel? program}) {
    final formKey = GlobalKey<FormState>();
    final namaController = TextEditingController(text: program?.nama ?? '');
    final deskripsiController = TextEditingController(
      text: program?.deskripsi ?? '',
    );
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isEdit = program != null;

            Future<void> saveProgram() async {
              if (!formKey.currentState!.validate()) return;

              setDialogState(() => isSubmitting = true);

              try {
                final payload = {
                  'nama': namaController.text.trim(),
                  'deskripsi': deskripsiController.text.trim().isEmpty
                      ? null
                      : deskripsiController.text.trim(),
                };

                if (isEdit) {
                  // UPDATE
                  await _supabase
                      .from('programs')
                      .update(payload)
                      .eq('id', program.id);
                } else {
                  // CREATE
                  await _supabase.from('programs').insert(payload);
                }

                if (!mounted) return;
                Navigator.pop(ctx);
                _showSnackBar(
                  isEdit
                      ? 'Program berhasil diperbarui'
                      : 'Program baru berhasil ditambahkan',
                );
                _fetchPrograms();
              } on PostgrestException catch (e) {
                setDialogState(() => isSubmitting = false);
                _showSnackBar('Gagal menyimpan: ${e.message}', isError: true);
              } catch (e) {
                setDialogState(() => isSubmitting = false);
                _showSnackBar('Terjadi kesalahan: $e', isError: true);
              }
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: Text(
                isEdit ? 'Edit Program' : 'Tambah Program Baru',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _textColor,
                ),
              ),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: namaController,
                      decoration: InputDecoration(
                        labelText: 'Nama Program',
                        hintText: 'Contoh: Tahfidz, BBAQ, PTL',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Nama program tidak boleh kosong'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: deskripsiController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Deskripsi (Opsional)',
                        hintText: 'Penjelasan singkat program...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                  ),
                  onPressed: isSubmitting ? null : saveProgram,
                  child: isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          isEdit ? 'Simpan' : 'Tambah',
                          style: const TextStyle(color: Colors.white),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // DELETE: Menghapus program dari database
  Future<void> _deleteProgram(ProgramModel program) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text(
          'Apakah Anda yakin ingin menghapus program "${program.nama}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _supabase.from('programs').delete().eq('id', program.id);

      if (!mounted) return;
      _showSnackBar('Program "${program.nama}" berhasil dihapus');
      _fetchPrograms();
    } on PostgrestException catch (e) {
      if (!mounted) return;
      _showSnackBar('Gagal menghapus program: ${e.message}', isError: true);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Terjadi kesalahan: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : const Color(0xFF2E7D32),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Kelola Program',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: _primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _primaryColor,
        onPressed: () => _showProgramFormDialog(),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Tambah Program',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primaryColor))
          : _programList.isEmpty
          ? const Center(
              child: Text(
                'Belum ada program tersedia.',
                style: TextStyle(color: _secondaryTextColor),
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetchPrograms,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _programList.length,
                itemBuilder: (context, index) {
                  final item = _programList[index];
                  return Card(
                    color: Colors.white,
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: _borderColor),
                    ),
                    child: ListTile(
                      title: Text(
                        item.nama,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _textColor,
                        ),
                      ),
                      subtitle: Text(
                        item.deskripsi ?? 'Tidak ada deskripsi',
                        style: const TextStyle(
                          fontSize: 12,
                          color: _secondaryTextColor,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.edit_outlined,
                              color: _primaryColor,
                            ),
                            onPressed: () =>
                                _showProgramFormDialog(program: item),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.redAccent,
                            ),
                            onPressed: () => _deleteProgram(item),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:ptl_mobile/utils/constants.dart';
import 'package:ptl_mobile/models/santri_form_mode.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const Color _primaryColor = Color(0xFF0D8B8B);
const Color _textColor = Color(0xFF263238);
const Color _borderColor = Color(0xFFECEFF1);

class SantriForm extends StatefulWidget {
  final SantriFormMode mode;
  final Map<String, dynamic>? santri;
  final VoidCallback onSubmitSuccess;

  const SantriForm({
    super.key,
    required this.mode,
    this.santri,
    required this.onSubmitSuccess,
  });

  bool get isEdit => mode == SantriFormMode.edit;

  @override
  State<SantriForm> createState() => _SantriFormState();
}

class _SantriFormState extends State<SantriForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // ============================================================
  // AKUN
  // ============================================================

  final TextEditingController _emailController = TextEditingController();

  final TextEditingController _passwordController = TextEditingController();

  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // ============================================================
  // DATA DIRI
  // ============================================================

  final TextEditingController _nikController = TextEditingController();

  final TextEditingController _usernameController = TextEditingController();

  final TextEditingController _noHpSantriController = TextEditingController();

  final TextEditingController _alamatController = TextEditingController();

  // ============================================================
  // DATA WALI
  // ============================================================

  final TextEditingController _namaWaliController = TextEditingController();

  final TextEditingController _noHpWaliController = TextEditingController();

  final List<String> _hubunganWaliList = ['Ayah', 'Ibu', 'Wakil'];

  String _hubunganWali = 'Ayah';

  // ============================================================
  // STATE
  // ============================================================

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSubmitting = false;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    final data = widget.santri;

    if (data == null) return;

    _emailController.text = data['email']?.toString() ?? '';

    _nikController.text = data['nik']?.toString() ?? '';

    _usernameController.text = data['username']?.toString() ?? '';

    _noHpSantriController.text = data['no_hp']?.toString() ?? '';

    _alamatController.text = data['alamat']?.toString() ?? '';

    _namaWaliController.text = data['nama_wali']?.toString() ?? '';

    _noHpWaliController.text = data['no_hp_wali']?.toString() ?? '';

    final hubungan = data['hubungan_wali']?.toString();

    if (_hubunganWaliList.contains(hubungan)) {
      _hubunganWali = hubungan!;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    _nikController.dispose();
    _usernameController.dispose();
    _noHpSantriController.dispose();
    _alamatController.dispose();

    _namaWaliController.dispose();
    _noHpWaliController.dispose();

    super.dispose();
  }

  // ============================================================
  // SUBMIT
  // ============================================================

  Future<void> _submitData() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (widget.isEdit) {
      await _updateSantri();
    } else {
      await _createSantri();
    }
  }

  // ============================================================
  // PROFILE PAYLOAD
  // ============================================================

  Map<String, dynamic> _buildProfilePayload({required String id}) {
    return {
      'id': id,
      'role': 'santri',
      'email': _emailController.text.trim(),
      'nik': _nikController.text.trim(),
      'username': _usernameController.text.trim(),
      'no_hp': _noHpSantriController.text.trim(),
      'alamat': _alamatController.text.trim(),
      'nama_wali': _namaWaliController.text.trim(),
      'no_hp_wali': _noHpWaliController.text.trim(),
      'hubungan_wali': _hubunganWali,
    };
  }

  // ============================================================
  // CREATE
  // ============================================================

  Future<void> _createSantri() async {
    setState(() => _isSubmitting = true);

    SupabaseClient? tempClient;

    try {
      tempClient = SupabaseClient(
        AppConstants.supabaseUrl,
        AppConstants.supabaseAnonKey,
        authOptions: const AuthClientOptions(
          authFlowType: AuthFlowType.implicit,
        ),
      );

      final AuthResponse response = await tempClient.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        data: {'username': _usernameController.text.trim(), 'role': 'santri'},
      );

      final String? newUserId = response.user?.id;

      if (newUserId == null) {
        throw 'Gagal mendapatkan ID akun santri dari Supabase Auth.';
      }

      final payload = _buildProfilePayload(id: newUserId);

      await Supabase.instance.client.from('profiles').upsert(payload);

      if (!mounted) return;

      _showSnackBar('Data santri berhasil ditambahkan!');

      widget.onSubmitSuccess();
    } on AuthException catch (e) {
      if (!mounted) return;

      _showSnackBar('Gagal pendaftaran akun: ${e.message}', isError: true);
    } on PostgrestException catch (e) {
      if (!mounted) return;

      _showSnackBar('Gagal menyimpan profil: ${e.message}', isError: true);
    } catch (e) {
      if (!mounted) return;

      _showSnackBar('Terjadi kesalahan: $e', isError: true);
    } finally {
      tempClient?.dispose();

      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  // ============================================================
  // UPDATE
  // ============================================================

  Future<void> _updateSantri() async {
    final id = widget.santri?['id']?.toString();

    if (id == null || id.isEmpty) {
      _showSnackBar('ID santri tidak ditemukan.', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final payload = _buildProfilePayload(id: id);

      // ID tidak perlu dikirim saat UPDATE
      payload.remove('id');
      payload.remove('role');

      await Supabase.instance.client
          .from('profiles')
          .update(payload)
          .eq('id', id);

      if (!mounted) return;

      _showSnackBar('Data santri berhasil diperbarui!');

      widget.onSubmitSuccess();
    } on PostgrestException catch (e) {
      if (!mounted) return;

      _showSnackBar('Gagal memperbarui data: ${e.message}', isError: true);
    } catch (e) {
      if (!mounted) return;

      _showSnackBar('Terjadi kesalahan: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  // ============================================================
  // SNACKBAR
  // ============================================================

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : const Color(0xFF2E7D32),
      ),
    );
  }

  // ============================================================
  // VALIDATION
  // ============================================================

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email wajib diisi';
    }

    final emailRegExp = RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,}$');

    if (!emailRegExp.hasMatch(value.trim())) {
      return 'Format email tidak valid';
    }

    return null;
  }

  String? _validateNik(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'NIK wajib diisi';
    }

    if (!RegExp(r'^\d{16}$').hasMatch(value.trim())) {
      return 'NIK harus terdiri dari 16 digit angka';
    }

    return null;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildAccountSection(),

          const SizedBox(height: 20),

          _buildPersonalSection(),

          const SizedBox(height: 20),

          _buildGuardianSection(),

          const SizedBox(height: 28),

          _buildSubmitButton(),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: _primaryColor,
      ),
    );
  }

  // ============================================================
  // ACCOUNT SECTION
  // ============================================================

  Widget _buildAccountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Akun Login Santri'),

        const SizedBox(height: 12),

        _buildTextField(
          controller: _emailController,
          label: 'Email Santri',
          hint: 'contoh: santri@gmail.com',
          keyboardType: TextInputType.emailAddress,
          readOnly: widget.isEdit,
          suffixIcon: widget.isEdit
              ? const Icon(
                  Icons.lock_outline,
                  color: Color(0xFF90A4AE),
                  size: 20,
                )
              : null,
          validator: widget.isEdit ? null : _validateEmail,
        ),

        if (widget.isEdit) ...[
          const SizedBox(height: 6),

          const Text(
            'Email login tidak diubah pada halaman edit.',
            style: TextStyle(fontSize: 11, color: Color(0xFF90A4AE)),
          ),
        ],

        if (!widget.isEdit) ...[
          const SizedBox(height: 12),

          _buildTextField(
            controller: _passwordController,
            label: 'Password',
            hint: 'Masukkan password',
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: const Color(0xFF90A4AE),
              ),
              onPressed: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Password wajib diisi';
              }

              if (value.length < 6) {
                return 'Password minimal 6 karakter';
              }

              return null;
            },
          ),

          const SizedBox(height: 12),

          _buildTextField(
            controller: _confirmPasswordController,
            label: 'Konfirmasi Password',
            hint: 'Ulangi password di atas',
            obscureText: _obscureConfirmPassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility_off
                    : Icons.visibility,
                color: const Color(0xFF90A4AE),
              ),
              onPressed: () {
                setState(
                  () => _obscureConfirmPassword = !_obscureConfirmPassword,
                );
              },
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Konfirmasi password wajib diisi';
              }

              if (value != _passwordController.text) {
                return 'Password tidak cocok';
              }

              return null;
            },
          ),
        ],
      ],
    );
  }

  // ============================================================
  // PERSONAL SECTION
  // ============================================================

  Widget _buildPersonalSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Data Diri Santri'),

        const SizedBox(height: 12),

        _buildTextField(
          controller: _nikController,
          label: 'NIK (Nomor Induk Kependudukan)',
          hint: 'Masukkan 16 digit NIK',
          keyboardType: TextInputType.number,
          validator: _validateNik,
        ),

        const SizedBox(height: 12),

        _buildTextField(
          controller: _usernameController,
          label: 'Nama Lengkap Santri',
          hint: 'Masukkan nama lengkap',
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Nama santri wajib diisi';
            }

            return null;
          },
        ),

        const SizedBox(height: 12),

        _buildTextField(
          controller: _noHpSantriController,
          label: 'No. HP / WhatsApp Santri',
          hint: 'Contoh: 081234567890',
          keyboardType: TextInputType.phone,
        ),

        const SizedBox(height: 12),

        _buildTextField(
          controller: _alamatController,
          label: 'Alamat Lengkap',
          hint: 'Jalan, RT/RW, Kecamatan, Kota',
          maxLines: 3,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Alamat wajib diisi';
            }

            return null;
          },
        ),
      ],
    );
  }

  // ============================================================
  // GUARDIAN SECTION
  // ============================================================

  Widget _buildGuardianSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Data Orang Tua / Wali'),

        const SizedBox(height: 12),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: _buildTextField(
                controller: _namaWaliController,
                label: 'Nama Wali',
                hint: 'Nama lengkap wali',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nama wali wajib diisi';
                  }

                  return null;
                },
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              flex: 1,
              child: _buildDropdownField(
                label: 'Hubungan',
                value: _hubunganWali,
                items: _hubunganWaliList,
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _hubunganWali = value);
                  }
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        _buildTextField(
          controller: _noHpWaliController,
          label: 'No. HP / WhatsApp Wali',
          hint: 'Contoh: 081234567890',
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'No HP wali wajib diisi';
            }

            return null;
          },
        ),
      ],
    );
  }

  // ============================================================
  // SUBMIT BUTTON
  // ============================================================

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitData,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                widget.isEdit ? 'Simpan Perubahan' : 'Simpan Data Santri',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  // ============================================================
  // DROPDOWN
  // ============================================================

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final safeValue = value != null && items.contains(value) ? value : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF455A64),
          ),
        ),

        const SizedBox(height: 6),

        DropdownButtonFormField<String>(
          value: safeValue,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: _primaryColor,
            size: 22,
          ),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(12),
          elevation: 3,
          style: const TextStyle(
            fontSize: 13,
            color: _textColor,
            fontWeight: FontWeight.w500,
          ),
          decoration: _dropdownDecoration(),
          items: items
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(item, style: const TextStyle(fontSize: 13)),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  // ============================================================
  // DROPDOWN DECORATION
  // ============================================================

  InputDecoration _dropdownDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _primaryColor, width: 1.5),
      ),
    );
  }

  // ============================================================
  // TEXT FIELD
  // ============================================================

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
    int maxLines = 1,
    String? Function(String?)? validator,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF455A64),
          ),
        ),

        const SizedBox(height: 6),

        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          maxLines: maxLines,
          validator: validator,
          readOnly: readOnly,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFB0BEC5)),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: readOnly ? const Color(0xFFF1F5F5) : Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _primaryColor),
            ),
          ),
        ),
      ],
    );
  }
}

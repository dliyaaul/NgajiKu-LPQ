import 'package:flutter/material.dart';

const Color _primaryColor = Color(0xFF0D8B8B);
const Color _primaryLightColor = Color(0xFFE6F3F3);
const Color _cardColor = Colors.white;
const Color _textColor = Color(0xFF1E293B);
const Color _subtitleColor = Color(0xFF64748B);
const Color _borderColor = Color(0xFFE2E8F0);

class AbsensiRekapFilter extends StatelessWidget {
  final List<Map<String, dynamic>> pengajarList;
  final String? selectedPengajarId;
  final String namaPengajar;

  final String selectedSemester;
  final DateTime dariTanggal;
  final DateTime sampaiTanggal;
  final DateTime tanggalCetak;

  final bool isLoading;
  final bool isExportingPdf;
  final bool canExportPdf;

  final ValueChanged<String?> onPengajarChanged;
  final ValueChanged<String> onSemesterChanged;
  final ValueChanged<DateTime> onDariTanggalChanged;
  final ValueChanged<DateTime> onSampaiTanggalChanged;
  final ValueChanged<DateTime> onTanggalCetakChanged;

  final VoidCallback onTampilkanRekap;
  final VoidCallback onExportPdf;

  const AbsensiRekapFilter({
    super.key,
    required this.pengajarList,
    required this.selectedPengajarId,
    required this.namaPengajar,
    required this.selectedSemester,
    required this.dariTanggal,
    required this.sampaiTanggal,
    required this.tanggalCetak,
    required this.isLoading,
    required this.isExportingPdf,
    required this.canExportPdf,
    required this.onPengajarChanged,
    required this.onSemesterChanged,
    required this.onDariTanggalChanged,
    required this.onSampaiTanggalChanged,
    required this.onTanggalCetakChanged,
    required this.onTampilkanRekap,
    required this.onExportPdf,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitle(),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 850) {
                return _buildWideLayout(context);
              }

              return _buildMobileLayout(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: _primaryLightColor,
            borderRadius: BorderRadius.circular(11),
          ),
          child: const Icon(
            Icons.filter_alt_outlined,
            color: _primaryColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 11),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filter Rekap',
                style: TextStyle(
                  color: _textColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Atur parameter laporan yang ingin ditampilkan.',
                style: TextStyle(color: _subtitleColor, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWideLayout(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildPengajarField(context)),
            const SizedBox(width: 12),
            Expanded(child: _buildSemesterField(context)),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDateField(
                context: context,
                label: 'Dari Tanggal',
                value: dariTanggal,
                onTap: () =>
                    _pickDate(context, dariTanggal, onDariTanggalChanged),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDateField(
                context: context,
                label: 'Sampai Tanggal',
                value: sampaiTanggal,
                onTap: () =>
                    _pickDate(context, sampaiTanggal, onSampaiTanggalChanged),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: _buildDateField(
                context: context,
                label: 'Tanggal Cetak Laporan',
                value: tanggalCetak,
                onTap: () =>
                    _pickDate(context, tanggalCetak, onTanggalCetakChanged),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: _buildActionButtons(context)),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      children: [
        _buildPengajarField(context),
        const SizedBox(height: 12),

        _buildSemesterField(context),
        const SizedBox(height: 12),

        _buildDateField(
          context: context,
          label: 'Dari Tanggal',
          value: dariTanggal,
          onTap: () => _pickDate(context, dariTanggal, onDariTanggalChanged),
        ),
        const SizedBox(height: 12),

        _buildDateField(
          context: context,
          label: 'Sampai Tanggal',
          value: sampaiTanggal,
          onTap: () =>
              _pickDate(context, sampaiTanggal, onSampaiTanggalChanged),
        ),
        const SizedBox(height: 12),

        _buildDateField(
          context: context,
          label: 'Tanggal Cetak Laporan',
          value: tanggalCetak,
          onTap: () => _pickDate(context, tanggalCetak, onTanggalCetakChanged),
        ),
        const SizedBox(height: 16),

        _buildActionButtons(context),
      ],
    );
  }

  Widget _buildPengajarField(BuildContext context) {
    return _buildFieldContainer(
      icon: Icons.person_outline,
      label: 'Pengajar',
      child: InkWell(
        onTap: isLoading ? null : () => _showPengajarPicker(context),
        borderRadius: BorderRadius.circular(10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                namaPengajar,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: _subtitleColor,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSemesterField(BuildContext context) {
    return _buildFieldContainer(
      icon: Icons.calendar_month_outlined,
      label: 'Semester',
      child: InkWell(
        onTap: isLoading ? null : () => _showSemesterPicker(context),
        borderRadius: BorderRadius.circular(10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                selectedSemester,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: _subtitleColor,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField({
    required BuildContext context,
    required String label,
    required DateTime value,
    required VoidCallback onTap,
  }) {
    return _buildFieldContainer(
      icon: Icons.event_outlined,
      label: label,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _formatDate(value),
                style: const TextStyle(
                  color: _textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: _subtitleColor,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldContainer({
    required IconData icon,
    required String label,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: _subtitleColor, size: 19),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: _subtitleColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 46,
            child: FilledButton.icon(
              onPressed: isLoading ? null : onTampilkanRekap,
              style: FilledButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _primaryColor.withValues(alpha: 0.45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: isLoading
                  ? const SizedBox(
                      width: 17,
                      height: 17,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.search_rounded, size: 19),
              label: Text(isLoading ? 'Memuat...' : 'Tampilkan Rekap'),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          height: 46,
          child: OutlinedButton.icon(
            onPressed: isLoading || isExportingPdf ? null : onExportPdf,
            style: OutlinedButton.styleFrom(
              foregroundColor: _primaryColor,
              side: const BorderSide(color: _primaryColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            icon: isExportingPdf
                ? const SizedBox(
                    width: 17,
                    height: 17,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.picture_as_pdf_outlined, size: 18),
            label: Text(isExportingPdf ? 'Proses...' : 'PDF'),
          ),
        ),
      ],
    );
  }

  Future<void> _pickDate(
    BuildContext context,
    DateTime currentDate,
    ValueChanged<DateTime> onChanged,
  ) async {
    final DateTime? selected = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: _primaryColor),
          ),
          child: child!,
        );
      },
    );

    if (selected != null) {
      onChanged(DateTime(selected.year, selected.month, selected.day));
    }
  }

  Future<void> _showPengajarPicker(BuildContext context) async {
    final String? selected = await showModalBottomSheet<String?>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            constraints: const BoxConstraints(maxHeight: 600),
            decoration: const BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSheetHandle(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Pilih Pengajar',
                          style: TextStyle(
                            color: _textColor,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: _borderColor),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      _buildPengajarOption(
                        context: sheetContext,
                        id: null,
                        nama: 'Semua Pengajar',
                      ),
                      ...pengajarList.map((pengajar) {
                        final String id = pengajar['id']?.toString() ?? '';

                        final String nama =
                            pengajar['username']?.toString() ??
                            pengajar['nama']?.toString() ??
                            'Pengajar';

                        return _buildPengajarOption(
                          context: sheetContext,
                          id: id,
                          nama: nama,
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    // Penting:
    // null berarti "Semua Pengajar", jadi tetap kirim callback
    // walaupun bottom sheet ditutup setelah memilih opsi tersebut.
    if (selected != null) {
      onPengajarChanged(selected);
    }
  }

  Widget _buildPengajarOption({
    required BuildContext context,
    required String? id,
    required String nama,
  }) {
    final bool isSelected = selectedPengajarId == id;

    return InkWell(
      onTap: () {
        Navigator.pop(context, id);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isSelected
                    ? _primaryLightColor
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                id == null ? Icons.groups_outlined : Icons.person_outline,
                color: isSelected ? _primaryColor : _subtitleColor,
                size: 19,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                nama,
                style: TextStyle(
                  color: _textColor,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: _primaryColor,
                size: 21,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showSemesterPicker(BuildContext context) async {
    final String? selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            decoration: const BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSheetHandle(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Pilih Semester',
                          style: TextStyle(
                            color: _textColor,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: _borderColor),
                _buildSemesterOption(
                  context: sheetContext,
                  value: 'Semester Ganjil',
                ),
                _buildSemesterOption(
                  context: sheetContext,
                  value: 'Semester Genap',
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );

    if (selected != null) {
      onSemesterChanged(selected);
    }
  }

  Widget _buildSemesterOption({
    required BuildContext context,
    required String value,
  }) {
    final bool isSelected = selectedSemester == value;

    return InkWell(
      onTap: () {
        Navigator.pop(context, value);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isSelected
                    ? _primaryLightColor
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.school_outlined,
                color: isSelected ? _primaryColor : _subtitleColor,
                size: 19,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  color: _textColor,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: _primaryColor,
                size: 21,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSheetHandle() {
    return Container(
      width: 42,
      height: 4,
      margin: const EdgeInsets.only(top: 10, bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFCBD5E1),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}

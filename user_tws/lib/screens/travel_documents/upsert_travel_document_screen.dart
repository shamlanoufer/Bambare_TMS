import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme.dart';
import '../../models/travel_document.dart';
import '../../services/travel_document_service.dart';

class UpsertTravelDocumentScreen extends StatefulWidget {
  const UpsertTravelDocumentScreen({super.key, this.existing});

  final TravelDocument? existing;

  @override
  State<UpsertTravelDocumentScreen> createState() =>
      _UpsertTravelDocumentScreenState();
}

class _UpsertTravelDocumentScreenState extends State<UpsertTravelDocumentScreen> {
  final _svc = TravelDocumentService();

  final _fullNameCtrl = TextEditingController();
  final _docNoCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();

  String _type = 'Passport';
  DateTime _issue = DateTime(DateTime.now().year, 1, 1);
  DateTime _expiry = DateTime(DateTime.now().year + 5, 1, 1);

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _type = e.type;
      _countryCtrl.text = e.issuingCountry;
      _fullNameCtrl.text = e.fullName;
      _docNoCtrl.text = e.documentNo;
      _issue = e.issueDate;
      _expiry = e.expiryDate;
    } else {
      _countryCtrl.text = 'Sri Lanka';
    }
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _docNoCtrl.dispose();
    _countryCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate({
    required DateTime initial,
    required ValueChanged<DateTime> onPicked,
    required DateTime first,
    required DateTime last,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
    );
    if (picked != null) onPicked(picked);
  }

  Future<void> _save() async {
    if (_saving) return;
    final fullName = _fullNameCtrl.text.trim();
    final docNo = _docNoCtrl.text.trim();
    final country = _countryCtrl.text.trim();

    if (fullName.isEmpty || docNo.isEmpty || country.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields.')),
      );
      return;
    }
    if (_expiry.isBefore(_issue)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expiry date must be after issue date.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final now = DateTime.now();
      final base = TravelDocument(
        id: widget.existing?.id ?? '',
        type: _type,
        issuingCountry: country,
        fullName: fullName,
        documentNo: docNo,
        issueDate: _issue,
        expiryDate: _expiry,
        createdAt: widget.existing?.createdAt ?? now,
        updatedAt: now,
      );

      if (widget.existing == null) {
        await _svc.create(base);
      } else {
        await _svc.update(base);
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final existing = widget.existing;
    if (existing == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete document?'),
        content: const Text('This will remove it from your account.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _saving = true);
    try {
      await _svc.delete(existing.id);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          isEdit ? 'Edit Document' : 'Add Document',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w900,
            color: AppTheme.black,
          ),
        ),
        iconTheme: const IconThemeData(color: AppTheme.black),
        actions: [
          if (isEdit)
            IconButton(
              onPressed: _saving ? null : _delete,
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: 'Delete',
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
        children: [
          _label('Document Type *'),
          _dropdown(
            value: _type,
            items: const [
              'Passport',
              'National ID',
              'Visa',
              'Travel Insurance',
              'Other',
            ],
            onChanged: (v) => setState(() => _type = v),
          ),
          const SizedBox(height: 12),
          _label('Issuing Country *'),
          _field(controller: _countryCtrl, hint: 'Sri Lanka'),
          const SizedBox(height: 12),
          _label('Full Name *'),
          _field(controller: _fullNameCtrl, hint: 'Your name'),
          const SizedBox(height: 12),
          _label('Document No. *'),
          _field(controller: _docNoCtrl, hint: 'e.g. N1234567'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _dateTile(
                  label: 'Issue Date *',
                  value: _fmt(_issue),
                  onTap: () => _pickDate(
                    initial: _issue,
                    first: DateTime(1950, 1, 1),
                    last: DateTime.now().add(const Duration(days: 365 * 50)),
                    onPicked: (d) => setState(() => _issue = d),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _dateTile(
                  label: 'Expiry Date *',
                  value: _fmt(_expiry),
                  onTap: () => _pickDate(
                    initial: _expiry,
                    first: DateTime(1950, 1, 1),
                    last: DateTime.now().add(const Duration(days: 365 * 50)),
                    onPicked: (d) => setState(() => _expiry = d),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF111827),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      isEdit ? 'Update' : 'Save',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: AppTheme.grey,
          ),
        ),
      );

  Widget _field({required TextEditingController controller, required String hint}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.10)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.10)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE8B800), width: 2),
        ),
      ),
    );
  }

  Widget _dropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.10)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          onChanged: (v) => v == null ? null : onChanged(v),
          items: items
              .map(
                (x) => DropdownMenuItem(
                  value: x,
                  child: Text(
                    x,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.black,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _dateTile({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black.withValues(alpha: 0.10)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.grey,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.black,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.calendar_month_rounded, color: AppTheme.grey),
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[d.month - 1]} ${d.day.toString().padLeft(2, '0')}, ${d.year}';
  }
}


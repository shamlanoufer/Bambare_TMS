import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/admin_theme_colors.dart';
import '../../theme/brand_colors.dart';
import '../../widgets/admin_profile_bar.dart';
import '../../services/activity_log_service.dart';

class AdminHotelsScreen extends StatelessWidget {
  const AdminHotelsScreen({super.key});

  void _showHotelDialog(
    BuildContext context, {
    String? docId,
    Map<String, dynamic>? existing,
  }) {
    final nameCtrl = TextEditingController(text: existing?['name'] ?? '');
    final locationCtrl =
        TextEditingController(text: existing?['location'] ?? '');
    final priceCtrl = TextEditingController(
      text: existing?['pricePerNight']?.toString() ?? '',
    );
    final roomsCtrl = TextEditingController(
      text: existing?['totalRooms']?.toString() ?? '',
    );
    int stars = existing?['stars'] ?? 3;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) {
          final c = ctx.adminColors;
          return AlertDialog(
          backgroundColor: c.dialogBackground,
          title: Text(
            docId == null ? 'Add Hotel' : 'Edit Hotel',
            style: GoogleFonts.dmSans(
              color: c.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field(ctx, 'Hotel Name', nameCtrl),
                const SizedBox(height: 12),
                _field(ctx, 'Location', locationCtrl),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _field(
                        ctx,
                        'Price / Night (LKR)',
                        priceCtrl,
                        inputType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _field(
                        ctx,
                        'Total Rooms',
                        roomsCtrl,
                        inputType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      'Stars:',
                      style: GoogleFonts.dmSans(
                        color: c.muted,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 12),
                    ...List.generate(
                      5,
                      (i) => GestureDetector(
                        onTap: () => setS(() => stars = i + 1),
                        child: Icon(
                          i < stars ? Icons.star : Icons.star_border,
                          color: i < stars
                              ? const Color(0xFFF0A94A)
                              : c.muted,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: GoogleFonts.dmSans(color: c.muted),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.isEmpty) return;
                final payload = {
                  'name': nameCtrl.text.trim(),
                  'location': locationCtrl.text.trim(),
                  'pricePerNight': double.tryParse(priceCtrl.text) ?? 0,
                  'totalRooms': int.tryParse(roomsCtrl.text) ?? 0,
                  'stars': stars,
                  'updatedAt': FieldValue.serverTimestamp(),
                };
                if (docId == null) {
                  payload['createdAt'] = FieldValue.serverTimestamp();
                  await FirebaseFirestore.instance
                      .collection('hotels')
                      .add(payload);
                  await ActivityLogService.log(
                    type: 'hotel',
                    message: 'Hotel added: ${nameCtrl.text.trim()}',
                  );
                } else {
                  await FirebaseFirestore.instance
                      .collection('hotels')
                      .doc(docId)
                      .update(payload);
                  await ActivityLogService.log(
                    type: 'hotel',
                    message: 'Hotel updated: ${nameCtrl.text.trim()}',
                  );
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: BrandColors.accent,
                foregroundColor: BrandColors.onAccent,
              ),
              child: Text(
                docId == null ? 'Add Hotel' : 'Update',
                style: GoogleFonts.dmSans(color: BrandColors.onAccent),
              ),
            ),
          ],
        );
        },
      ),
    );
  }

  Future<void> _deleteHotel(BuildContext context, String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final c = dialogContext.adminColors;
        return AlertDialog(
          backgroundColor: c.dialogBackground,
          title: Text(
            'Delete Hotel',
            style: GoogleFonts.dmSans(color: c.textPrimary),
          ),
          content: Text(
            'Remove this hotel permanently?',
            style: GoogleFonts.dmSans(color: c.muted),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(
                'Cancel',
                style: GoogleFonts.dmSans(color: c.muted),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(
                'Delete',
                style: GoogleFonts.dmSans(color: const Color(0xFFF47067)),
              ),
            ),
          ],
        );
      },
    );
    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('hotels')
          .doc(docId)
          .delete();
      await ActivityLogService.log(
        type: 'cancel',
        message: 'Hotel removed',
      );
    }
  }

  Widget _field(
    BuildContext context,
    String label,
    TextEditingController ctrl, {
    TextInputType inputType = TextInputType.text,
  }) {
    final c = context.adminColors;
    return TextFormField(
      controller: ctrl,
      keyboardType: inputType,
      style: GoogleFonts.dmSans(color: c.textPrimary, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.dmSans(
          color: c.muted,
          fontSize: 12,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: c.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: BrandColors.accent),
        ),
        filled: true,
        fillColor: c.surface,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.adminColors;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
          decoration: BoxDecoration(
            color: c.topBarBackground,
            border: Border(
              bottom: BorderSide(color: c.border, width: 1),
            ),
          ),
          child: Row(
            children: [
              Text(
                'Hotels',
                style: GoogleFonts.dmSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: c.textPrimary,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _showHotelDialog(context),
                icon: const Icon(Icons.add, size: 16),
                label: Text(
                  'Add Hotel',
                  style: GoogleFonts.dmSans(fontSize: 12),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: BrandColors.accent,
                  foregroundColor: BrandColors.onAccent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const AdminProfileBar(),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('hotels')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: BrandColors.accent,
                    strokeWidth: 2,
                  ),
                );
              }
              final docs = snap.data!.docs;
              return GridView.builder(
                padding: const EdgeInsets.all(24),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.6,
                ),
                itemCount: docs.length,
                itemBuilder: (_, i) {
                  final d = docs[i].data() as Map<String, dynamic>;
                  final stars = d['stars'] ?? 3;
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: c.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              '🏨',
                              style: TextStyle(fontSize: 20),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () => _showHotelDialog(
                                context,
                                docId: docs[i].id,
                                existing: d,
                              ),
                              child: Icon(
                                Icons.edit_outlined,
                                size: 15,
                                color: c.muted,
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () =>
                                  _deleteHotel(context, docs[i].id),
                              child: const Icon(
                                Icons.delete_outline,
                                size: 15,
                                color: Color(0xFFF47067),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          d['name'] ?? '—',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: c.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          d['location'] ?? '',
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            color: c.muted,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: List.generate(
                            5,
                            (si) => Icon(
                              si < stars ? Icons.star : Icons.star_border,
                              size: 12,
                              color: si < stars
                                  ? const Color(0xFFF0A94A)
                                  : c.border,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'LKR ${d['pricePerNight'] ?? 0}/night',
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: BrandColors.accent,
                              ),
                            ),
                            Text(
                              '${d['totalRooms'] ?? 0} rooms',
                              style: GoogleFonts.dmSans(
                                fontSize: 10,
                                color: c.muted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

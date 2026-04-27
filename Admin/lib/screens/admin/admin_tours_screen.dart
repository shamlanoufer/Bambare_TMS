import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/admin_theme_colors.dart';
import '../../theme/brand_colors.dart';
import '../../widgets/admin_profile_bar.dart';
import '../../services/activity_log_service.dart';
import 'admin_add_tour_screen.dart';

class AdminToursScreen extends StatelessWidget {
  const AdminToursScreen({super.key});

  Future<void> _deleteTour(BuildContext context, String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final c = dialogContext.adminColors;
        return AlertDialog(
          backgroundColor: c.dialogBackground,
          title: Text(
            'Delete Tour',
            style: GoogleFonts.dmSans(color: c.textPrimary),
          ),
          content: Text(
            'This will remove the tour package permanently.',
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
      await FirebaseFirestore.instance.collection('tours').doc(docId).delete();
      await ActivityLogService.log(
        type: 'cancel',
        message: 'Tour package removed',
      );
    }
  }

  Future<void> _openEditor(BuildContext context, {String? docId}) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => AdminAddTourScreen(docId: docId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.adminColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
                'Tour Packages',
                style: GoogleFonts.dmSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: c.textPrimary,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _openEditor(context),
                icon: const Icon(Icons.add, size: 16),
                label: Text(
                  'Add Tour',
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
                .collection('tours')
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
                  childAspectRatio: 1.5,
                ),
                itemCount: docs.length,
                itemBuilder: (_, i) {
                  final d = docs[i].data() as Map<String, dynamic>;
                  final isActive = d['isActive'] ?? true;
                  final heroUrl = (d['image_url'] ?? d['imageUrl'] ?? '').toString().trim();
                  return Container(
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isActive
                            ? BrandColors.accent.withOpacity(0.3)
                            : c.border,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (heroUrl.isNotEmpty)
                          Image.network(
                            heroUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const ColoredBox(color: Color(0xFF0F141A)),
                          )
                        else
                          const ColoredBox(color: Color(0xFF0F141A)),
                        // Dark overlay so text stays readable
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                const Color(0xFF0F141A).withOpacity(0.38),
                                const Color(0xFF0F141A).withOpacity(0.72),
                              ],
                              stops: const [0.0, 1.0],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    d['emoji'] ?? '🗺',
                                    style: const TextStyle(fontSize: 22),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isActive
                                          ? BrandColors.accent.withOpacity(0.18)
                                          : const Color(0xFFF47067)
                                              .withOpacity(0.18),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      isActive ? 'Active' : 'Inactive',
                                      style: GoogleFonts.dmSans(
                                        fontSize: 10,
                                        color: isActive
                                            ? BrandColors.accent
                                            : const Color(0xFFF47067),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  GestureDetector(
                                    onTap: () => _openEditor(
                                      context,
                                      docId: docs[i].id,
                                    ),
                                    child: Icon(
                                      Icons.edit_outlined,
                                      size: 15,
                                      color: Colors.white.withOpacity(0.75),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  GestureDetector(
                                    onTap: () => _deleteTour(context, docs[i].id),
                                    child: const Icon(
                                      Icons.delete_outline,
                                      size: 15,
                                      color: Color(0xFFF47067),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                d['tourName'] ?? '—',
                                style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withOpacity(0.92),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                d['duration'] ?? '',
                                style: GoogleFonts.dmSans(
                                  fontSize: 11,
                                  color: Colors.white.withOpacity(0.65),
                                ),
                              ),
                              const Spacer(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'LKR ${d['basePrice'] ?? 0}',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: BrandColors.accent,
                                    ),
                                  ),
                                  Text(
                                    'Max: ${d['maxCapacity'] ?? 0} pax',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 10,
                                      color: Colors.white.withOpacity(0.65),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
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

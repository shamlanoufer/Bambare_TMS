import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/admin_tour_storage.dart';
import '../theme/admin_theme_colors.dart';
import '../theme/brand_colors.dart';

/// Image field: paste a direct **https://** link to an image file (no device upload).
class AdminImagePickRow extends StatefulWidget {
  const AdminImagePickRow({
    super.key,
    required this.label,
    required this.urlController,
    this.compactPreview = false,
  });

  final String label;
  final TextEditingController urlController;
  final bool compactPreview;

  @override
  State<AdminImagePickRow> createState() => _AdminImagePickRowState();
}

class _AdminImagePickRowState extends State<AdminImagePickRow> {
  @override
  Widget build(BuildContext context) {
    final c = context.adminColors;
    final url = widget.urlController.text.trim();
    final isHttp = AdminTourStorage.isHttpUrl(url);
    final isData = AdminTourStorage.isDataImageUrl(url);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: GoogleFonts.dmSans(
            color: c.muted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Paste a direct image link (https://…). Upload the file to ImgBB, Imgur, etc., then copy “direct link”.',
          style: GoogleFonts.dmSans(fontSize: 10, color: c.muted, height: 1.35),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: widget.urlController,
          style: GoogleFonts.dmSans(color: c.textPrimary, fontSize: 12),
          decoration: InputDecoration(
            hintText: 'https://…',
            hintStyle: GoogleFonts.dmSans(color: c.muted, fontSize: 11),
            isDense: true,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: c.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: BrandColors.accent),
            ),
            filled: true,
            fillColor: c.inputFill,
          ),
          onChanged: (_) => setState(() {}),
        ),
        if (isData) ...[
          const SizedBox(height: 8),
          Text(
            'Base64 images are too large for Firestore. Replace with a short https:// link.',
            style: GoogleFonts.dmSans(
              fontSize: 11,
              color: const Color(0xFFFFB74D),
              height: 1.35,
            ),
          ),
        ],
        if (url.isNotEmpty && isHttp) ...[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              url,
              height: widget.compactPreview ? 72 : 140,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        ],
      ],
    );
  }
}

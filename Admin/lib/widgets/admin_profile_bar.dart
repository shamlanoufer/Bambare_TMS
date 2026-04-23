import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/admin_theme_colors.dart';
import '../theme/brand_colors.dart';

/// Logged-in admin: photo (Auth / Firestore) or initials, plus display name.
/// Use in every admin screen top bar so profile is visible on all tabs.
class AdminProfileBar extends StatelessWidget {
  const AdminProfileBar({super.key});

  static String _initialsFromDisplayName(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return '?';
    final parts = t.split(RegExp(r'\s+'));
    if (parts.length >= 2 &&
        parts[0].isNotEmpty &&
        parts[1].isNotEmpty) {
      final a = parts[0].runes.first;
      final b = parts[1].runes.first;
      return '${String.fromCharCode(a)}${String.fromCharCode(b)}'
          .toUpperCase();
    }
    final runes = t.runes.toList();
    if (runes.length >= 2) {
      return '${String.fromCharCode(runes[0])}${String.fromCharCode(runes[1])}'
          .toUpperCase();
    }
    return String.fromCharCode(runes.first).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.adminColors;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('admins')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snap) {
        final data = snap.data?.data() as Map<String, dynamic>?;
        final name = (data?['name'] ??
                data?['email'] ??
                user.displayName ??
                user.email ??
                '')
            .toString()
            .trim();
        final displayName = name.isNotEmpty ? name : (user.email ?? 'Admin');
        final photoUrl = (user.photoURL ??
                data?['photoUrl'] ??
                data?['photoURL'])
            ?.toString();
        final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;
        final initials = _initialsFromDisplayName(
          name.isNotEmpty ? name : (user.email ?? '?'),
        );

        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return const SizedBox(
            height: 40,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 36,
                  height: 36,
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: BrandColors.accent,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        Widget avatarInner;
        if (hasPhoto) {
          avatarInner = Image.network(
            photoUrl,
            width: 36,
            height: 36,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _InitialsAvatar(initials: initials),
          );
        } else {
          avatarInner = _InitialsAvatar(initials: initials);
        }

        return Tooltip(
          message: displayName,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: c.border),
                ),
                clipBehavior: Clip.antiAlias,
                child: avatarInner,
              ),
              const SizedBox(width: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 160),
                child: Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: c.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            BrandColors.accent,
            Color(0xFFFFA726),
          ],
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: GoogleFonts.dmSans(
            fontSize: initials.length > 2 ? 9 : 12,
            fontWeight: FontWeight.w600,
            color: BrandColors.onAccent,
          ),
        ),
      ),
    );
  }
}

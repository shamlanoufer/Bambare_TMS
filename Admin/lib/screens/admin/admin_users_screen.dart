import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/admin_theme_colors.dart';
import '../../theme/brand_colors.dart';
import '../../services/activity_log_service.dart';
import '../../widgets/admin_profile_bar.dart';

String _userDisplayName(Map<String, dynamic> d) {
  for (final key in ['fullName', 'name', 'displayName', 'username']) {
    final v = d[key];
    if (v != null) {
      final s = v.toString().trim();
      if (s.isNotEmpty) return s;
    }
  }
  final email = d['email']?.toString().trim();
  if (email != null && email.contains('@')) {
    return email.split('@').first;
  }
  return '—';
}

String? _userPhotoUrl(Map<String, dynamic> d) {
  for (final key in ['photoUrl', 'photoURL', 'avatarUrl', 'avatar', 'profilePic']) {
    final v = d[key];
    if (v != null) {
      final s = v.toString().trim();
      if (s.isNotEmpty) return s;
    }
  }
  return null;
}

String _userInitials(String displayName, String email) {
  final t = displayName.trim();
  if (t.isNotEmpty && t != '—') {
    final parts = t.split(RegExp(r'\s+'));
    if (parts.length >= 2 &&
        parts[0].isNotEmpty &&
        parts[1].isNotEmpty) {
      final a = parts[0].runes.first;
      final b = parts[1].runes.first;
      return '${String.fromCharCode(a)}${String.fromCharCode(b)}'.toUpperCase();
    }
    final runes = t.runes.toList();
    if (runes.length >= 2) {
      return '${String.fromCharCode(runes[0])}${String.fromCharCode(runes[1])}'
          .toUpperCase();
    }
    if (runes.isNotEmpty) {
      return String.fromCharCode(runes.first).toUpperCase();
    }
  }
  final e = email.trim();
  if (e.contains('@')) {
    final local = e.split('@').first;
    if (local.length >= 2) {
      return local.substring(0, 2).toUpperCase();
    }
    if (local.isNotEmpty) {
      return local.substring(0, 1).toUpperCase();
    }
  }
  if (e.length >= 2) {
    return e.substring(0, 2).toUpperCase();
  }
  return '?';
}

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  String _roleFilter = 'all';

  Query<Map<String, dynamic>> get _query {
    final base = FirebaseFirestore.instance
        .collection('users')
        .orderBy('createdAt', descending: true);
    if (_roleFilter == 'all') return base;
    return base.where('role', isEqualTo: _roleFilter);
  }

  Future<void> _toggleStatus(String docId, bool isActive) async {
    await FirebaseFirestore.instance.collection('users').doc(docId).update({
      'isActive': !isActive,
    });
  }

  Future<void> _deleteUser(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final c = dialogContext.adminColors;
        return AlertDialog(
          backgroundColor: c.dialogBackground,
          title: Text(
            'Delete User',
            style: GoogleFonts.dmSans(color: c.textPrimary),
          ),
          content: Text(
            'This will permanently delete the user account.',
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
      await FirebaseFirestore.instance.collection('users').doc(docId).delete();
      await ActivityLogService.log(
        type: 'user',
        message: 'User account removed',
      );
    }
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
                'User Management',
                style: GoogleFonts.dmSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: c.textPrimary,
                ),
              ),
              const SizedBox(width: 16),
              ...[
                ['all', 'All'],
                ['customer', 'Customers'],
                ['admin', 'Admins'],
              ].map((f) {
                final active = _roleFilter == f[0];
                return GestureDetector(
                  onTap: () => setState(() => _roleFilter = f[0]),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: active
                          ? BrandColors.accent
                          : c.chipBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: active
                            ? BrandColors.accent
                            : c.border,
                      ),
                    ),
                    child: Text(
                      f[1],
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color:
                            active ? BrandColors.onAccent : c.muted,
                      ),
                    ),
                  ),
                );
              }),
              const Spacer(),
              const AdminProfileBar(),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _query.snapshots(),
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
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Container(
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: c.border),
                  ),
                  child: Column(
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: c.border,
                              width: 0.5,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                'User',
                                style: GoogleFonts.dmSans(
                                  fontSize: 11,
                                  color: c.muted,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                'Email',
                                style: GoogleFonts.dmSans(
                                  fontSize: 11,
                                  color: c.muted,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Role',
                                style: GoogleFonts.dmSans(
                                  fontSize: 11,
                                  color: c.muted,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Joined',
                                style: GoogleFonts.dmSans(
                                  fontSize: 11,
                                  color: c.muted,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                'Status',
                                style: GoogleFonts.dmSans(
                                  fontSize: 11,
                                  color: c.muted,
                                ),
                              ),
                            ),
                            const SizedBox(width: 56),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: docs.length,
                          itemBuilder: (_, i) {
                            final d =
                                docs[i].data() as Map<String, dynamic>;
                            final email =
                                d['email']?.toString().trim() ?? '—';
                            final name = _userDisplayName(d);
                            final photoUrl = _userPhotoUrl(d);
                            final initials =
                                _userInitials(name, email);
                            final role = d['role'] ?? 'customer';
                            final isActive = d['isActive'] ?? true;
                            final ts = d['createdAt'] as Timestamp?;
                            final joined = ts != null
                                ? '${ts.toDate().day}/${ts.toDate().month}/${ts.toDate().year}'
                                : '—';
                            final isAdmin = role == 'admin';

                            return Container(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                10,
                                16,
                                10,
                              ),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: c.border,
                                    width: 0.5,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Row(
                                      children: [
                                        _UserTableAvatar(
                                          photoUrl: photoUrl,
                                          initials: initials,
                                          isAdmin: isAdmin,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            name,
                                            style: GoogleFonts.dmSans(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: c.textPrimary,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      email,
                                      style: GoogleFonts.dmSans(
                                        fontSize: 11,
                                        color: c.muted,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isAdmin
                                              ? const Color(0xFFBC8CFF)
                                                  .withOpacity(0.15)
                                              : const Color(0xFF58A6FF)
                                                  .withOpacity(0.15),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          role[0].toUpperCase() +
                                              role.substring(1),
                                          style: GoogleFonts.dmSans(
                                            fontSize: 10,
                                            color: isAdmin
                                                ? const Color(0xFFBC8CFF)
                                                : const Color(0xFF58A6FF),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      joined,
                                      style: GoogleFonts.dmSans(
                                        fontSize: 11,
                                        color: c.muted,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Transform.scale(
                                      scale: 0.72,
                                      alignment: Alignment.centerLeft,
                                      child: Switch(
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        value: isActive,
                                        activeThumbColor: BrandColors.accent,
                                        activeTrackColor: BrandColors.accent
                                            .withOpacity(0.35),
                                        onChanged: (_) => _toggleStatus(
                                          docs[i].id,
                                          isActive,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 56,
                                    child: Align(
                                      alignment: Alignment.center,
                                      child: IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(
                                          minWidth: 44,
                                          minHeight: 44,
                                        ),
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          size: 23,
                                          color: Color(0xFFF47067),
                                        ),
                                        onPressed: () =>
                                            _deleteUser(docs[i].id),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _UserTableAvatar extends StatelessWidget {
  const _UserTableAvatar({
    required this.photoUrl,
    required this.initials,
    required this.isAdmin,
  });

  final String? photoUrl;
  final String initials;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    final bgTint = isAdmin ? const Color(0xFFBC8CFF) : BrandColors.accent;
    final bgSoft = isAdmin
        ? const Color(0xFFBC8CFF).withOpacity(0.2)
        : BrandColors.accent.withOpacity(0.2);

    final placeholder = Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: bgSoft,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          initials,
          style: GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: bgTint,
          ),
        ),
      ),
    );

    final url = photoUrl;
    if (url == null || url.isEmpty) {
      return placeholder;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 32,
        height: 32,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => placeholder,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: bgSoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: bgTint,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

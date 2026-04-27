// lib/screens/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/booking_background.dart';
import '../../core/nav_insets.dart';
import '../../core/theme.dart';
import '../../services/auth_service.dart';
import '../../services/memories_service.dart';
import '../../models/memory_item.dart';
import '../../models/user_model.dart';
import 'add_memory_screen.dart';
import 'edit_profile_screen.dart';
import 'settings_screen.dart';
import 'dart:convert';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _auth = AuthService();
  final _memories = MemoriesService();
  bool _loading = true;

  String _timeAgo(DateTime? dt) {
    if (dt == null) return '—';
    final now = DateTime.now();
    final d = now.difference(dt);
    if (d.inSeconds < 45) return 'now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    if (d.inDays < 30) return '${d.inDays}d ago';
    final months = (d.inDays / 30).floor();
    return months <= 1 ? '1 month ago' : '$months months ago';
  }

  @override
  void initState() {
    super.initState();
    _ensureAuth();
  }

  Future<void> _ensureAuth() async {
    if (_auth.currentUser != null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      await FirebaseAuth.instance.signInAnonymously();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  void _editProfile() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StreamBuilder<UserModel?>(
          stream: _auth.userStream(uid),
          builder: (context, snap) {
            final user = snap.data;
            if (user == null) {
              return const Scaffold(
                backgroundColor: AppTheme.white,
                body: Center(
                  child: CircularProgressIndicator(color: AppTheme.yellow),
                ),
              );
            }
            return EditProfileScreen(user: user);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppTheme.white,
        body: Center(child: CircularProgressIndicator(color: AppTheme.yellow)),
      );
    }

    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(
        backgroundColor: AppTheme.white,
        body: Center(child: Text('Not signed in')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BookingBackgroundLayer(
        child: StreamBuilder<UserModel?>(
          stream: _auth.userStream(uid),
          builder: (context, snap) {
            final user = snap.data;
            final name = user?.fullName.trim().isNotEmpty == true
                ? user!.fullName
                : 'Traveller';
            final email = user?.email.isNotEmpty == true
                ? user!.email
                : FirebaseAuth.instance.currentUser?.email ?? '';

            return SingleChildScrollView(
              child: Column(
                children: [
                  // ── Hero Header ─────────────────────────────────
                  _buildHero(user, name, email),

            const SizedBox(height: 20),

            // ── Action Buttons ───────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _editProfile,
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.black,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.22),
                              blurRadius: 14,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'Edit Profile',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 44,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => SettingsScreen()),
                      ),
                      icon: const Icon(Icons.settings_outlined, size: 18),
                      label: const Text('Settings'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF111827),
                        side: const BorderSide(color: Color(0xFFE5E7EB)),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Memories Timeline Card ───────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: StreamBuilder<List<MemoryItem>>(
                stream: _memories.myMemoriesStream(limit: 1),
                builder: (context, snap) {
                  final list = snap.data ?? const <MemoryItem>[];
                  final latest = list.isNotEmpty ? list.first : null;
                  final latestAt = latest?.createdAt?.toDate();
                  final ago = _timeAgo(latestAt);

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFEAEAEA)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Memories Timeline',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF111827),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Capture your precious moments',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.schedule,
                                    size: 14, color: Color(0xFF8B5CF6)),
                                const SizedBox(width: 6),
                                Text(
                                  ago,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF8B5CF6),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              latestAt == null ? 'No memories yet' : 'Last memory',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF9CA3AF),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // ── Memories Grid + Add button (DB connected) ──────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Memories',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () async {
                      final added = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(builder: (_) => const AddMemoryScreen()),
                      );
                      // Stream updates automatically; this is just for UX.
                      if (added == true && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Memory added')),
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.add, color: AppTheme.black),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 88,
              child: StreamBuilder<List<MemoryItem>>(
                stream: _memories.myMemoriesStream(limit: 10),
                builder: (context, snap) {
                  final items = snap.data ?? const <MemoryItem>[];
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    scrollDirection: Axis.horizontal,
                    itemCount: items.isEmpty ? 4 : items.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, i) {
                      if (items.isEmpty) {
                        return Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFEAEAEA)),
                          ),
                        );
                      }
                      final m = items[i];
                      final img = m.imageUrl.trim();
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _openMemoryPopup(m),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFEAEAEA)),
                              image: img.isNotEmpty
                                  ? DecorationImage(
                                      image: img.startsWith('data:image')
                                          ? MemoryImage(base64Decode(img.split(',').last))
                                              as ImageProvider
                                          : NetworkImage(img),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            SizedBox(height: FloatingNavLayout.scrollBottomPadding(context)),
                ],
              ),
            );
          },
        ),
      ),
);
  }

  // ── Hero Header ────────────────────────────────────────────
  Widget _buildHero(UserModel? user, String name, String email) {
    final photoUrl = user?.photoUrl ?? '';
    final hasPhoto = photoUrl.trim().isNotEmpty;

    ImageProvider? avatarImage;
    if (hasPhoto) {
      avatarImage = photoUrl.startsWith('data:image')
          ? MemoryImage(base64Decode(photoUrl.split(',').last)) as ImageProvider
          : NetworkImage(photoUrl);
    }

    return SizedBox(
      width: double.infinity,
      height: 220,
      child: Stack(
        children: [
          Positioned(
            left: 18,
            right: 18,
            bottom: 18,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: _editProfile,
                    child: Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFE5E7EB),
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF000000).withValues(alpha: 0.18),
                            blurRadius: 12,
                            offset: const Offset(0, 8),
                          ),
                        ],
                        image: avatarImage != null
                            ? DecorationImage(
                                image: avatarImage,
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: avatarImage == null
                          ? const Icon(Icons.person, size: 40, color: Color(0xFF6B7280))
                          : null,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.mail_outline, size: 14, color: Colors.black54),
                      const SizedBox(width: 6),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 240),
                        child: Text(
                          email,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Top safe-area spacing (keeps content away from notch)
          const Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: SafeArea(child: SizedBox(height: 1)),
          ),
        ],
      ),
    );
  }

  Future<void> _openMemoryPopup(MemoryItem m) async {
    final img = m.imageUrl.trim();
    final title = m.title.trim();
    final story = m.story.trim();

    ImageProvider? provider;
    if (img.isNotEmpty) {
      provider = img.startsWith('data:image')
          ? MemoryImage(base64Decode(img.split(',').last)) as ImageProvider
          : NetworkImage(img);
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (ctx) {
        return Dialog(
          insetPadding: EdgeInsets.zero,
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Center(
            child: FractionallySizedBox(
              widthFactor: 0.98,
              heightFactor: 0.96,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close_rounded),
                          tooltip: 'Close',
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () async {
                            final ok = await showDialog<bool>(
                              context: ctx,
                              builder: (dCtx) => AlertDialog(
                                title: const Text('Delete memory?'),
                                content:
                                    const Text('This will remove it permanently.'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(dCtx, false),
                                    child: const Text('Cancel'),
                                  ),
                                  FilledButton(
                                    onPressed: () => Navigator.pop(dCtx, true),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: Colors.red.shade700,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                            if (ok != true) return;
                            try {
                              await _memories.deleteMemory(memoryId: m.id);
                              if (!ctx.mounted) return;
                              Navigator.pop(ctx);
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Memory deleted')),
                              );
                            } catch (e) {
                              if (!ctx.mounted) return;
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Delete failed: $e')),
                              );
                            }
                          },
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          label: const Text(
                            'Delete',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (provider != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: AspectRatio(
                                aspectRatio: 16 / 10,
                                child: Image(
                                  image: provider,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          const SizedBox(height: 14),
                          Text(
                            title.isEmpty ? 'Memory' : title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.black,
                            ),
                          ),
                          if (story.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(
                              story,
                              style: const TextStyle(
                                fontSize: 14,
                                height: 1.45,
                                color: Color(0xFF374151),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // (Account/Preferences menu helpers removed; moved into SettingsScreen)
}

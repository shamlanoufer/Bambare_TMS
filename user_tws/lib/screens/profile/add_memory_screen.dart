import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme.dart';
import '../../models/memory_item.dart';
import '../../services/memories_service.dart';

class AddMemoryScreen extends StatefulWidget {
  const AddMemoryScreen({
    super.key,
    this.existing,
  });

  final MemoryItem? existing;

  @override
  State<AddMemoryScreen> createState() => _AddMemoryScreenState();
}

class _AddMemoryScreenState extends State<AddMemoryScreen> {
  final _svc = MemoriesService();
  final _title = TextEditingController();
  final _story = TextEditingController();
  XFile? _picked;
  bool _saving = false;
  late final String _modeTitle;

  @override
  void initState() {
    super.initState();
    _modeTitle = widget.existing == null ? 'Add Memory' : 'Edit Memory';
    _title.text = widget.existing?.title ?? '';
    _story.text = widget.existing?.story ?? '';
  }

  @override
  void dispose() {
    _title.dispose();
    _story.dispose();
    super.dispose();
  }

  Future<void> _ensureAnonymousAuth() async {
    if (FirebaseAuth.instance.currentUser != null) return;
    try {
      await FirebaseAuth.instance.signInAnonymously();
    } catch (_) {}
  }

  Future<void> _pick() async {
    final picker = ImagePicker();
    final src = await showDialog<ImageSource>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (ctx) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Spacer(),
                    Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  'Add Memory Photo',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                const Divider(height: 18),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.photo_library_outlined, color: AppTheme.yellow),
                  title: const Text('Choose from Gallery'),
                  onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.camera_alt_outlined, color: AppTheme.yellow),
                  title: const Text('Take a Photo'),
                  onTap: () => Navigator.pop(ctx, ImageSource.camera),
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),
        );
      },
    );
    if (src == null) return;
    final img = await picker.pickImage(source: src, imageQuality: 75);
    if (img == null) return;
    setState(() => _picked = img);
  }

  Future<void> _save() async {
    if (_saving) return;
    final isEdit = widget.existing != null;
    if (!isEdit && _picked == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a photo')),
      );
      return;
    }
    if (_title.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a title')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await _ensureAnonymousAuth();
      if (isEdit) {
        await _svc
            .updateMemory(
          memoryId: widget.existing!.id,
          title: _title.text,
          story: _story.text,
          imageFile: _picked,
        )
            .timeout(const Duration(seconds: 60));
      } else {
        await _svc
            .addMemory(
          title: _title.text,
          story: _story.text,
          imageFile: _picked!,
        )
            .timeout(const Duration(seconds: 60));
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

  @override
  Widget build(BuildContext context) {
    final preview = _picked;
    final existingImage = widget.existing?.imageUrl.trim() ?? '';
    final showExisting = preview == null && existingImage.isNotEmpty;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _modeTitle,
          style: const TextStyle(
            color: AppTheme.black,
            fontWeight: FontWeight.w900,
          ),
        ),
        iconTheme: const IconThemeData(color: AppTheme.black),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pick,
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 14,
                      offset: const Offset(0, 10),
                    ),
                  ],
                  image: preview != null
                      ? DecorationImage(
                          image: kIsWeb
                              ? NetworkImage(preview.path)
                              : FileImage(File(preview.path)) as ImageProvider,
                          fit: BoxFit.cover,
                        )
                      : showExisting
                          ? DecorationImage(
                              image: existingImage.startsWith('data:image')
                                  ? MemoryImage(base64Decode(existingImage.split(',').last))
                                      as ImageProvider
                                  : NetworkImage(existingImage),
                              fit: BoxFit.cover,
                            )
                      : null,
                ),
                alignment: Alignment.center,
                child: preview == null && !showExisting
                    ? const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_a_photo_outlined, size: 32, color: AppTheme.grey),
                          SizedBox(height: 8),
                          Text(
                            'Tap to add a photo',
                            style: TextStyle(color: AppTheme.grey, fontWeight: FontWeight.w700),
                          ),
                        ],
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEFEFEF)),
              ),
              child: TextField(
                controller: _title,
                decoration: const InputDecoration(
                  hintText: 'Memory title',
                  prefixIcon: Icon(Icons.title_rounded),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEFEFEF)),
              ),
              child: TextField(
                controller: _story,
                minLines: 4,
                maxLines: 8,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  hintText: 'Write your story...',
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 72),
                    child: Icon(Icons.notes_rounded),
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              height: 54,
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.yellow,
                  foregroundColor: AppTheme.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        widget.existing == null ? 'Save Memory' : 'Update Memory',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/booking_background.dart';
import '../../models/booking.dart';
import '../../services/auth_service.dart';
import '../../services/tour_guest_review_service.dart';

/// After a trip is completed, user submits text (+ optional photo). Stored as
/// `tours/{tourId}/guest_reviews` with `approved: false` until admin taps Add.
class SubmitTourReviewScreen extends StatefulWidget {
  const SubmitTourReviewScreen({super.key, required this.booking});

  final Booking booking;

  @override
  State<SubmitTourReviewScreen> createState() => _SubmitTourReviewScreenState();
}

class _SubmitTourReviewScreenState extends State<SubmitTourReviewScreen> {
  static const _accent = Color(0xFFE8B800);

  final _comment = TextEditingController();
  final _svc = TourGuestReviewService();
  final _auth = AuthService();

  double _rating = 5;
  bool _loading = true;
  bool _submitting = false;
  bool _alreadySubmitted = false;
  XFile? _picked;

  @override
  void initState() {
    super.initState();
    _checkExisting();
  }

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _checkExisting() async {
    final b = widget.booking;
    if (b.tourId.isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final exists = await _svc.hasReviewForBooking(
        tourId: b.tourId,
        bookingId: b.id,
      );
      if (mounted) {
        setState(() {
          _alreadySubmitted = exists;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickPhoto() async {
    final x = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (x != null && mounted) setState(() => _picked = x);
  }

  Future<void> _submit() async {
    final b = widget.booking;
    if (b.tourId.isEmpty) return;
    final text = _comment.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please write a short comment.',
            style: GoogleFonts.plusJakartaSans(),
          ),
        ),
      );
      return;
    }
    if (FirebaseAuth.instance.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Sign in to submit a review.',
            style: GoogleFonts.plusJakartaSans(),
          ),
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      String userName = b.leadDisplayName;
      String photoUrl = '';
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final profile = await _auth.getUserData(uid);
      if (profile != null) {
        final dn =
            '${profile.firstName} ${profile.lastName}'.trim();
        if (dn.isNotEmpty) {
          userName = dn;
        } else if (profile.email.isNotEmpty) {
          userName = profile.email.split('@').first;
        }
        photoUrl = profile.photoUrl.trim();
      }

      String imageUrl = '';
      if (_picked != null) {
        final up = await _svc.uploadReviewPhoto(
          tourId: b.tourId,
          file: kIsWeb ? _picked! : File(_picked!.path),
        );
        imageUrl = up ?? '';
      }

      await _svc.submitPendingReview(
        tourId: b.tourId,
        bookingId: b.id,
        userName: userName,
        userPhotoUrl: photoUrl,
        rating: _rating,
        commentText: text,
        reviewImageUrl: imageUrl,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Thanks! Your review will show on the tour after admin approval.',
            style: GoogleFonts.plusJakartaSans(),
          ),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not submit: $e',
            style: GoogleFonts.plusJakartaSans(),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final b = widget.booking;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BookingBackgroundLayer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(8, top + 8, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    color: Colors.black87,
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      'Review your trip',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: _accent),
                    )
                  : b.tourId.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'This booking has no tour link, so a review cannot be sent.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                        )
                      : _alreadySubmitted
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Text(
                                  'You already sent a review for this trip.\n\n'
                                  'It will appear on the tour after admin approves it.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    height: 1.45,
                                    color: Colors.black54,
                                  ),
                                ),
                              ),
                            )
                          : SingleChildScrollView(
                              padding: EdgeInsets.fromLTRB(
                                20,
                                8,
                                20,
                                bottom + 24,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    b.tourTitle,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    'Rating',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        _rating.toStringAsFixed(1),
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Slider(
                                          value: _rating,
                                          min: 1,
                                          max: 5,
                                          divisions: 8,
                                          activeColor: _accent,
                                          onChanged: _submitting
                                              ? null
                                              : (v) =>
                                                  setState(() => _rating = v),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Your experience',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _comment,
                                    maxLines: 6,
                                    enabled: !_submitting,
                                    decoration: InputDecoration(
                                      hintText:
                                          'What did you love? Anything for future travellers?',
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(
                                          color: Colors.black12,
                                        ),
                                      ),
                                    ),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  OutlinedButton.icon(
                                    onPressed:
                                        _submitting ? null : _pickPhoto,
                                    icon: const Icon(Icons.add_photo_alternate,
                                        color: _accent),
                                    label: Text(
                                      _picked == null
                                          ? 'Add photo (optional)'
                                          : 'Change photo',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 52,
                                    child: FilledButton(
                                      onPressed:
                                          _submitting ? null : _submit,
                                      style: FilledButton.styleFrom(
                                        backgroundColor: _accent,
                                        foregroundColor: Colors.black87,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                      ),
                                      child: _submitting
                                          ? const SizedBox(
                                              width: 22,
                                              height: 22,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.black87,
                                              ),
                                            )
                                          : Text(
                                              'Submit for approval',
                                              style:
                                                  GoogleFonts.plusJakartaSans(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

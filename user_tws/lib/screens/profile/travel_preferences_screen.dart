import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/booking_background.dart';
import '../../core/theme.dart';
import '../../models/travel_preferences.dart';
import '../../services/travel_preferences_service.dart';

class TravelPreferencesScreen extends StatefulWidget {
  const TravelPreferencesScreen({super.key});

  @override
  State<TravelPreferencesScreen> createState() => _TravelPreferencesScreenState();
}

class _TravelPreferencesScreenState extends State<TravelPreferencesScreen> {
  final _svc = TravelPreferencesService();
  bool _saving = false;

  TravelPreferences _draft = TravelPreferences.defaults;

  static const _allInterests = <String>[
    'Cultural',
    'Wildlife',
    'Wellness',
    'Food',
    'Beach',
    'Adventure',
    'Mountains',
    'City',
  ];

  static const _budgets = <String>['Budget', 'Mid-Range', 'Luxury'];
  static const _durations = <String>['Day Trip', 'Weekend', 'Week+'];

  @override
  void initState() {
    super.initState();
    _ensureAnonymousAuth();
  }

  Future<void> _ensureAnonymousAuth() async {
    if (FirebaseAuth.instance.currentUser != null) return;
    try {
      await FirebaseAuth.instance.signInAnonymously();
    } catch (_) {}
    if (mounted) setState(() {});
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await _svc.upsert(_draft);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preferences saved')),
      );
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
    final topPad = MediaQuery.paddingOf(context).top;
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BookingBackgroundLayer(
        child: StreamBuilder<TravelPreferences>(
          stream: _svc.myPrefsStream(),
          builder: (context, snap) {
            final prefs = snap.data ?? TravelPreferences.defaults;
            // Initialize draft once when stream first resolves.
            if (_draft == TravelPreferences.defaults && snap.hasData) {
              _draft = prefs;
            }

            return ListView(
              padding: EdgeInsets.fromLTRB(18, topPad + 10, 18, bottomPad + 18),
              children: [
                Row(
                  children: [
                    Material(
                      color: Colors.black.withValues(alpha: 0.10),
                      shape: const CircleBorder(),
                      child: IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                        iconSize: 18,
                        color: AppTheme.black,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Travel Preferences',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.black,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE8A3),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFFD66B)),
                  ),
                  child: Row(
                    children: [
                      const Text('💝', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Personalize your experience',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.black,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Select your interests to get tailored tour recommendations',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Your Interests · ${_draft.interests.length} selected',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.black,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final it in _allInterests)
                      _Chip(
                        label: it,
                        icon: _emojiForInterest(it),
                        active: _draft.interests.contains(it),
                        onTap: () {
                          final set = _draft.interests.toSet();
                          if (set.contains(it)) {
                            set.remove(it);
                          } else {
                            set.add(it);
                          }
                          setState(() => _draft = _draft.copyWith(
                                interests: set.toList()..sort(),
                              ));
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                _divider(),
                const SizedBox(height: 12),
                Text(
                  'Budget Range',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.black,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final b in _budgets)
                      _Pill(
                        label: b,
                        active: _draft.budgetRange == b,
                        onTap: () => setState(() => _draft =
                            _draft.copyWith(budgetRange: b)),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                _divider(),
                const SizedBox(height: 12),
                Text(
                  'Trip Duration',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.black,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final d in _durations)
                      _Pill(
                        label: d,
                        active: _draft.tripDuration == d,
                        onTap: () => setState(() => _draft =
                            _draft.copyWith(tripDuration: d)),
                      ),
                  ],
                ),
                const SizedBox(height: 22),
                SizedBox(
                  height: 54,
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFE8B800),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
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
                            'Save Preference',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                          ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _divider() => Divider(
        height: 1,
        color: Colors.black.withValues(alpha: 0.12),
      );

  String _emojiForInterest(String it) {
    switch (it) {
      case 'Cultural':
        return '🏛️';
      case 'Wildlife':
        return '🦁';
      case 'Wellness':
        return '🧘';
      case 'Food':
        return '🍜';
      case 'Beach':
        return '🏖️';
      case 'Adventure':
        return '🏔️';
      case 'Mountains':
        return '⛰️';
      case 'City':
        return '🏙️';
      default:
        return '⭐';
    }
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final String label;
  final String icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: active ? Colors.black.withValues(alpha: 0.75) : Colors.black.withValues(alpha: 0.20),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: active ? Colors.black.withValues(alpha: 0.75) : Colors.black.withValues(alpha: 0.20),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}


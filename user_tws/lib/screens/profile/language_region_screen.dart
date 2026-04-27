import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/booking_background.dart';
import '../../core/theme.dart';
import '../../models/language_region_prefs.dart';
import '../../services/language_region_service.dart';

class LanguageRegionScreen extends StatefulWidget {
  const LanguageRegionScreen({super.key});

  @override
  State<LanguageRegionScreen> createState() => _LanguageRegionScreenState();
}

class _LanguageRegionScreenState extends State<LanguageRegionScreen> {
  final _svc = LanguageRegionService();
  bool _saving = false;
  LanguageRegionPrefs _draft = LanguageRegionPrefs.defaults;

  static const _languages = <_LangOpt>[
    _LangOpt(label: 'English', sub: 'en', flag: 'US'),
    _LangOpt(label: 'Sinhala', sub: 'සිං', flag: 'LK'),
    _LangOpt(label: 'Tamil', sub: 'தமிழ்', flag: 'LK'),
    _LangOpt(label: 'French', sub: 'fr', flag: 'FR'),
    _LangOpt(label: 'German', sub: 'de', flag: 'DE'),
    _LangOpt(label: 'Chinese', sub: '中文', flag: 'CN'),
    _LangOpt(label: 'Japanese', sub: '日本語', flag: 'JP'),
    _LangOpt(label: 'Arabic', sub: 'العربية', flag: 'SA'),
  ];

  static const _currencies = <_CurrencyOpt>[
    _CurrencyOpt(code: 'LKR', label: 'LKR - Rs', flag: 'LK'),
    _CurrencyOpt(code: 'INR', label: 'INR - Rs', flag: 'IN'),
    _CurrencyOpt(code: 'USD', label: 'USD - \$', flag: 'US'),
    _CurrencyOpt(code: 'JPY', label: 'JPY - Y', flag: 'JP'),
    _CurrencyOpt(code: 'AUD', label: 'AUD - A\$', flag: 'AU'),
    _CurrencyOpt(code: 'EUR', label: 'EUR - EUR', flag: 'EU'),
    _CurrencyOpt(code: 'GBP', label: 'GBP - GBP', flag: 'GB'),
  ];

  static const _timezones = <String>[
    'Europe/London (UTC+0)',
    'America/New_York (UTC-5)',
    'Asia/Colombo (UTC+5:30)',
    'Asia/Tokyo (UTC+9)',
    'Asia/Kolkata (UTC+5:30)',
  ];

  static const _dateFormats = <String>[
    'DD/MM/YYYY',
    'MM/DD/YYYY',
    'YYYY-MM-DD',
  ];

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
        const SnackBar(content: Text('Preference saved')),
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
        child: StreamBuilder<LanguageRegionPrefs>(
          stream: _svc.myPrefsStream(),
          builder: (context, snap) {
            final prefs = snap.data ?? LanguageRegionPrefs.defaults;
            if (_draft == LanguageRegionPrefs.defaults && snap.hasData) {
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
                        'Language & Region',
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
                Row(
                  children: [
                    Expanded(
                      child: _topPill(_draft.language, 'Language', active: true),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _topPill(_draft.currency, 'Currency', active: true),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _topPill(_tzBadge(_draft.timezone), 'Timezone', active: true),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _section('Display Language'),
                _card([
                  for (final l in _languages) ...[
                    _radioRow(
                      leading: l.flag,
                      title: l.label,
                      subtitle: l.sub,
                      selected: _draft.language == l.label,
                      onTap: () => setState(() => _draft =
                          _draft.copyWith(language: l.label)),
                    ),
                    if (l != _languages.last) _divider(),
                  ],
                ]),
                const SizedBox(height: 18),
                _section('Currency'),
                _card([
                  for (final c in _currencies) ...[
                    _radioRow(
                      leading: c.flag,
                      title: c.label,
                      subtitle: '',
                      selected: _draft.currency == c.code,
                      onTap: () => setState(() =>
                          _draft = _draft.copyWith(currency: c.code)),
                    ),
                    if (c != _currencies.last) _divider(),
                  ],
                ]),
                const SizedBox(height: 18),
                _section('Timezone'),
                _card([
                  for (final t in _timezones) ...[
                    _radioRow(
                      leading: '🕒',
                      title: t,
                      subtitle: '',
                      selected: _draft.timezone == t,
                      onTap: () =>
                          setState(() => _draft = _draft.copyWith(timezone: t)),
                    ),
                    if (t != _timezones.last) _divider(),
                  ],
                ]),
                const SizedBox(height: 18),
                _section('Date Format'),
                _card([
                  for (final f in _dateFormats) ...[
                    _radioRow(
                      leading: '📅',
                      title: f,
                      subtitle: '',
                      selected: _draft.dateFormat == f,
                      onTap: () => setState(
                          () => _draft = _draft.copyWith(dateFormat: f)),
                    ),
                    if (f != _dateFormats.last) _divider(),
                  ],
                ]),
                const SizedBox(height: 18),
                SizedBox(
                  height: 54,
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFE8B800),
                      foregroundColor: Colors.black,
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

  Widget _topPill(String title, String sub, {required bool active}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFFFE8A3) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: AppTheme.black,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppTheme.grey,
            ),
          ),
        ],
      ),
    );
  }

  String _tzBadge(String tz) {
    final open = tz.indexOf('(UTC');
    if (open < 0) return tz;
    final close = tz.indexOf(')', open);
    if (close < 0) return tz.substring(open + 1);
    return tz.substring(open + 1, close); // e.g. UTC+5:30
  }

  Widget _section(String t) => Padding(
        padding: const EdgeInsets.only(left: 6, bottom: 10),
        child: Text(
          t,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: AppTheme.black,
          ),
        ),
      );

  Widget _card(List<Widget> children) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 16,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(children: children),
      );

  Widget _divider() => Divider(
        height: 1,
        color: Colors.black.withValues(alpha: 0.08),
      );

  Widget _radioRow({
    required String leading,
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: Text(leading, style: const TextStyle(fontSize: 16)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.black,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.grey,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? AppTheme.black : Colors.black26,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _LangOpt {
  const _LangOpt({
    required this.label,
    required this.sub,
    required this.flag,
  });

  final String label;
  final String sub;
  final String flag;
}

class _CurrencyOpt {
  const _CurrencyOpt({
    required this.code,
    required this.label,
    required this.flag,
  });

  final String code;
  final String label;
  final String flag;
}


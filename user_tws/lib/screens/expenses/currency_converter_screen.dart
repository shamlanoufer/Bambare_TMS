import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CurrencyConverterScreen extends StatefulWidget {
  const CurrencyConverterScreen({super.key});

  @override
  State<CurrencyConverterScreen> createState() =>
      _CurrencyConverterScreenState();
}

class _CurrencyConverterScreenState extends State<CurrencyConverterScreen> {
  static const _bg = Color(0xFFF7F8FA);
  static const _muted = Color(0xFF8E8E93);

  // Reference screenshot shows: 1 USD = 298.76 LKR
  static const double _lkrPerUsd = 298.76;

  final _amountCtrl = TextEditingController(text: '10000');
  int _quick = 10000;

  // Simple static rates for UI (no network dependency).
  // Values are "1 unit of currency = X LKR".
  final Map<String, double> _lkrPer = const {
    'USD': _lkrPerUsd,
    'EUR': 328.40,
    'GBP': 382.10,
    'AUD': 196.40,
    'INR': 3.58,
    'JPY': 2.03,
    'CNY': 41.30,
  };

  final List<int> _quickAmounts = const [5000, 10000, 25000, 50000, 100000];

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  int _parseAmount() {
    final raw = _amountCtrl.text.replaceAll(',', '').trim();
    final v = int.tryParse(raw) ?? 0;
    return v < 0 ? 0 : v;
  }

  String _fmtInt(num n) {
    final s = n.round().toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  String _fmt2(double v) => v.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    final amountLkr = _parseAmount();
    final usd = amountLkr / _lkrPerUsd;
    final eur = amountLkr / (_lkrPer['EUR'] ?? _lkrPerUsd);
    final gbp = amountLkr / (_lkrPer['GBP'] ?? _lkrPerUsd);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        foregroundColor: Colors.black,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        title: Text(
          'Currency Converter',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
        children: [
          Text(
            'Rates updated 15 min ago',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 14),
          _LightCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LK LKR Sri Lankan Rupee',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _muted,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _amountCtrl,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                    height: 1.1,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: '0',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: Colors.black.withValues(alpha: 0.25),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final q in _quickAmounts) ...[
                _QuickChip(
                  label: q >= 1000 ? '${(q / 1000).round()}K' : q.toString(),
                  selected: _quick == q,
                  onTap: () {
                    setState(() {
                      _quick = q;
                      _amountCtrl.text = q.toString();
                    });
                  },
                ),
                const SizedBox(width: 10),
              ],
            ],
          ),
          const SizedBox(height: 14),
          _LightCard(
            color: const Color(0xFFFFF1E8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'US USD US Dollar',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.black.withValues(alpha: 0.70),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _fmt2(usd),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '1 USD = $_lkrPerUsd LKR · Live · Updated 9:26 AM',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.black.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'ALL CURRENCIES',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: Colors.black.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.55,
            children: [
              _MiniRate(code: 'EUR', value: _fmt2(eur)),
              _MiniRate(code: 'GBP', value: _fmt2(gbp)),
              _MiniRate(
                code: 'AUD',
                value: _fmt2(amountLkr / (_lkrPer['AUD'] ?? _lkrPerUsd)),
              ),
              _MiniRate(
                code: 'INR',
                value: _fmtInt(amountLkr / (_lkrPer['INR'] ?? 1)),
              ),
              _MiniRate(
                code: 'JPY',
                value: _fmtInt(amountLkr / (_lkrPer['JPY'] ?? 1)),
              ),
              _MiniRate(
                code: 'CNY',
                value: _fmt2(amountLkr / (_lkrPer['CNY'] ?? _lkrPerUsd)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Tip: Amount is in LKR. Tap chips to set quick amounts.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.black.withValues(alpha: 0.45),
            ),
          ),
        ],
      ),
    );
  }
}

class _LightCard extends StatelessWidget {
  const _LightCard({required this.child, this.color});
  final Widget child;
  final Color? color;

  static const _card = Colors.white;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color ?? _card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  static const _accent = Color(0xFFFF8A1F);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? _accent : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? _accent : Colors.black.withValues(alpha: 0.10),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: selected ? Colors.white : Colors.black.withValues(alpha: 0.75),
          ),
        ),
      ),
    );
  }
}

class _MiniRate extends StatelessWidget {
  const _MiniRate({required this.code, required this.value});
  final String code;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            code,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Colors.black.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.black,
              height: 1.05,
            ),
          ),
        ],
      ),
    );
  }
}


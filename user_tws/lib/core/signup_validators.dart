// Signup validation: international phone, ID, DOB, region & address text.

class SignupValidators {
  SignupValidators._();

  static const String invalidMsg = 'Not valid. Try again.';

  static final RegExp _hasLetter = RegExp(r'\p{L}', unicode: true);

  /// City / district / county — any region name, must look like real text.
  static bool isValidDistrict(String raw) {
    return _isValidPlaceField(raw);
  }

  /// State / province / region — same rules as district.
  static bool isValidProvince(String raw) {
    return _isValidPlaceField(raw);
  }

  static bool _isValidPlaceField(String raw) {
    final s = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (s.length < 2 || s.length > 100) return false;
    if (RegExp(r'^\d+$').hasMatch(s)) return false;
    if (!_hasLetter.hasMatch(s)) return false;
    return true;
  }

  /// Street address: length + at least one letter (any script) or digit.
  static bool isValidAddress(String raw) {
    final s = raw.trim();
    if (s.length < 5 || s.length > 200) return false;
    if (!_hasLetter.hasMatch(s) && !RegExp(r'\d').hasMatch(s)) {
      return false;
    }
    return true;
  }

  /// E.164-style: 8–15 digits total (country + national). Allows `+`, `00`, spaces.
  /// Legacy Sri Lanka local `0XXXXXXXXX` (10 digits) still accepted.
  static bool isValidInternationalPhone(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return false;

    // Sri Lanka mobile local 07XXXXXXXX only (not other countries' 0… formats)
    if (digits.startsWith('07') && digits.length == 10) return true;
    if (digits.startsWith('94') && digits.length == 11) return true;

    if (digits.length < 8 || digits.length > 15) return false;
    // International full number should not be only trunk "0" without rest
    if (digits.startsWith('0') && digits.length <= 9) return false;
    if (digits.split('').toSet().length < 2) return false;
    return true;
  }

  /// Passport / national ID — not Sri Lanka–only.
  static bool isValidNic(String raw) {
    final n = raw.trim();
    if (n.length < 4 || n.length > 40) return false;
    if (!RegExp(r'^[a-zA-Z0-9\s\-/.]+$').hasMatch(n)) return false;
    return RegExp(r'[a-zA-Z0-9]').hasMatch(n);
  }

  static final _emailRe = RegExp(
    r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$',
  );

  static bool isValidEmail(String email) {
    final e = email.trim();
    if (e.length < 5 || e.length > 254) return false;
    return _emailRe.hasMatch(e);
  }

  /// Real calendar date; age between [minAge] and 120.
  static String? validateBirthday(String raw, {int minAge = 13}) {
    final t = raw.trim();
    if (t.isEmpty) return invalidMsg;

    DateTime? parsed;

    final iso = DateTime.tryParse(t);
    if (iso != null) {
      parsed = DateTime(iso.year, iso.month, iso.day);
    } else {
      final parts = t
          .split(RegExp(r'[/\-.]'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      if (parts.length != 3) return invalidMsg;
      final a = int.tryParse(parts[0]);
      final b = int.tryParse(parts[1]);
      final c = int.tryParse(parts[2]);
      if (a == null || b == null || c == null) return invalidMsg;
      if (a >= 1900 && a <= 2100 && b >= 1 && b <= 12 && c >= 1 && c <= 31) {
        try {
          parsed = DateTime(a, b, c);
        } catch (_) {}
      }
      if (parsed == null &&
          c >= 1900 &&
          c <= 2100 &&
          b >= 1 &&
          b <= 12 &&
          a >= 1 &&
          a <= 31) {
        try {
          parsed = DateTime(c, b, a);
        } catch (_) {}
      }
    }

    if (parsed == null) return invalidMsg;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (parsed.isAfter(today)) return invalidMsg;

    var age = today.year - parsed.year;
    if (today.month < parsed.month ||
        (today.month == parsed.month && today.day < parsed.day)) {
      age--;
    }
    if (age < minAge || age > 120) return invalidMsg;

    return null;
  }
}

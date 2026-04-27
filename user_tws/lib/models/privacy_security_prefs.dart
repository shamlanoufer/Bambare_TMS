class PrivacySecurityPrefs {
  const PrivacySecurityPrefs({
    required this.twoFactorAuth,
    required this.publicProfile,
    required this.locationSharing,
    required this.analyticsImprovements,
  });

  final bool twoFactorAuth;
  final bool publicProfile;
  final bool locationSharing;
  final bool analyticsImprovements;

  static const defaults = PrivacySecurityPrefs(
    twoFactorAuth: false,
    publicProfile: true,
    locationSharing: false,
    analyticsImprovements: true,
  );

  PrivacySecurityPrefs copyWith({
    bool? twoFactorAuth,
    bool? publicProfile,
    bool? locationSharing,
    bool? analyticsImprovements,
  }) {
    return PrivacySecurityPrefs(
      twoFactorAuth: twoFactorAuth ?? this.twoFactorAuth,
      publicProfile: publicProfile ?? this.publicProfile,
      locationSharing: locationSharing ?? this.locationSharing,
      analyticsImprovements: analyticsImprovements ?? this.analyticsImprovements,
    );
  }

  static PrivacySecurityPrefs fromMap(Map<String, dynamic>? d) {
    final m = d ?? const <String, dynamic>{};
    bool b(String k, bool def) => (m[k] is bool) ? m[k] as bool : def;
    return PrivacySecurityPrefs(
      twoFactorAuth: b('two_factor_auth', defaults.twoFactorAuth),
      publicProfile: b('public_profile', defaults.publicProfile),
      locationSharing: b('location_sharing', defaults.locationSharing),
      analyticsImprovements:
          b('analytics_improvements', defaults.analyticsImprovements),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'two_factor_auth': twoFactorAuth,
      'public_profile': publicProfile,
      'location_sharing': locationSharing,
      'analytics_improvements': analyticsImprovements,
    };
  }
}


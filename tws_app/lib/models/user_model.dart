// lib/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String phone;
  final String firstName;
  final String lastName;
  final String nicNumber;
  final String dateOfBirth;
  final String personalAddress;
  final String district;
  final String province;
  final String photoUrl;
  final String role; // 'customer' or 'admin'
  final bool phoneVerified;
  final int toursCount;
  final double rating;
  final int savedCount;
  final String gender;
  final String nationality;
  final String bio;
  final List<String> travelPreferences;
  final Timestamp? createdAt;
  final Timestamp? lastLogin;
  final Timestamp? passwordUpdatedAt;

  const UserModel({
    required this.uid,
    required this.email,
    required this.phone,
    required this.firstName,
    required this.lastName,
    required this.nicNumber,
    required this.dateOfBirth,
    required this.personalAddress,
    required this.district,
    required this.province,
    this.photoUrl = '',
    this.role = 'customer',
    this.phoneVerified = false,
    this.toursCount = 0,
    this.rating = 0.0,
    this.savedCount = 0,
    this.gender = '',
    this.nationality = '',
    this.bio = '',
    this.travelPreferences = const [],
    this.createdAt,
    this.lastLogin,
    this.passwordUpdatedAt,
  });

  // ── Convert to Firestore Map ─────────────────────────────
  Map<String, dynamic> toMap() => {
        'uid': uid,
        'email': email,
        'phone': phone,
        'firstName': firstName,
        'lastName': lastName,
        'nicNumber': nicNumber,
        'dateOfBirth': dateOfBirth,
        'personalAddress': personalAddress,
        'district': district,
        'province': province,
        'photoUrl': photoUrl,
        'role': role,
        'phoneVerified': phoneVerified,
        'toursCount': toursCount,
        'rating': rating,
        'savedCount': savedCount,
        'gender': gender,
        'nationality': nationality,
        'bio': bio,
        'travelPreferences': travelPreferences,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
        'passwordUpdatedAt': FieldValue.serverTimestamp(),
      };

  // ── Build from Firestore snapshot ────────────────────────
  factory UserModel.fromMap(Map<String, dynamic> m) => UserModel(
        uid: m['uid'] ?? '',
        email: m['email'] ?? '',
        phone: m['phone'] ?? '',
        firstName: m['firstName'] ?? '',
        lastName: m['lastName'] ?? '',
        nicNumber: m['nicNumber'] ?? '',
        dateOfBirth: m['dateOfBirth'] ?? '',
        personalAddress: m['personalAddress'] ?? '',
        district: m['district'] ?? '',
        province: m['province'] ?? '',
        photoUrl: m['photoUrl'] ?? '',
        role: m['role'] ?? 'customer',
        phoneVerified: m['phoneVerified'] ?? false,
        toursCount: m['toursCount'] ?? 0,
        rating: (m['rating'] ?? 0.0).toDouble(),
        savedCount: m['savedCount'] ?? 0,
        gender: m['gender'] ?? '',
        nationality: m['nationality'] ?? '',
        bio: m['bio'] ?? '',
        travelPreferences: List<String>.from(m['travelPreferences'] ?? []),
        createdAt: m['createdAt'] as Timestamp?,
        lastLogin: m['lastLogin'] as Timestamp?,
        passwordUpdatedAt: m['passwordUpdatedAt'] as Timestamp?,
      );

  String get fullName => '$firstName $lastName';
}

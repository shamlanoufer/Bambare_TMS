// lib/services/auth_service.dart
// ─────────────────────────────────────────────────────────────────
// ALL Firebase Authentication + Firestore logic lives here.
// Screens only call these methods — no Firebase code in screens.
// ─────────────────────────────────────────────────────────────────
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode, kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:math';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart' show XFile;
import 'dart:io';
import '../models/user_model.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ── Getters ──────────────────────────────────────────────
  User? get currentUser => _auth.currentUser;
  Stream<User?> get authState => _auth.authStateChanges();

  CollectionReference get _users => _db.collection('users');

  // ── Firebase Storage Upload ──────────────────────────────
  Future<String?> uploadProfilePhoto(dynamic file, String uid) async {
    debugPrint('AuthService: Starting upload for $uid');
    
    // On Web, default to Base64 to bypass CORS and Storage bucket setup issues
    if (kIsWeb) {
      try {
        debugPrint('AuthService: Web detected, using Base64 encoding fallback');
        final bytes = await (file is XFile ? file.readAsBytes() : (file as File).readAsBytes());
        final base64String = base64Encode(bytes);
        final dataUrl = 'data:image/jpeg;base64,$base64String';
        debugPrint('AuthService: Base64 encoding success (length: ${dataUrl.length})');
        return dataUrl;
      } catch (e) {
        debugPrint('AuthService: Base64 encoding error: $e');
        return null;
      }
    }

    try {
      final ref = _storage.ref().child('profiles').child('$uid.jpg');
      UploadTask task;

      if (file is File) {
        task = ref.putFile(file);
      } else if (file is XFile) {
        task = ref.putFile(File(file.path));
      } else {
        throw 'Unsupported file type';
      }

      // Add a timeout to the upload task
      await task.timeout(const Duration(seconds: 30));
      
      final url = await ref.getDownloadURL();
      debugPrint('AuthService: Upload success! URL: $url');
      return url;
    } catch (e) {
      debugPrint('AuthService: Upload error for $uid: $e');
      if (e is FirebaseException && e.code == 'canceled') {
        debugPrint('AuthService: Upload timed out or was canceled');
      }
      return null;
    }
  }

  // ── Update User Data ─────────────────────────────────────
  Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    debugPrint('AuthService: Updating user $uid with data: $data');
    await _users.doc(uid).update(data);
    debugPrint('AuthService: Update successful for $uid');
  }

  /// Phone SMS OTP does not work reliably on Flutter Web (Chrome) without extra reCAPTCHA setup.
  static bool get phoneOtpSupportedThisPlatform => !kIsWeb;

  // ════════════════════════════════════════════════════════
  //  EMAIL LOGIN
  //  Email + Password → Firebase signIn → update lastLogin
  // ════════════════════════════════════════════════════════
  Future<void> loginWithEmail({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    // Update lastLogin timestamp in Firestore
    await _users.doc(cred.user!.uid).update({
      'lastLogin': FieldValue.serverTimestamp(),
    });
  }

  // ════════════════════════════════════════════════════════
  //  PHONE LOGIN — Step 1
  //  Phone number → Firebase sends OTP to phone
  // ════════════════════════════════════════════════════════
  Future<void> sendPhoneLoginOtp({
    required String phone, // must be +94XXXXXXXXX format
    required void Function(String verificationId) onSent,
    required void Function(String error) onError,
  }) async {
    if (kIsWeb) {
      onError(
        '[web] Phone SMS OTP does not work in browser. Install Android app on a real phone or use USB: flutter run',
      );
      return;
    }
    await _auth.verifyPhoneNumber(
      phoneNumber: phone,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (credential) async {
        // Android auto-detect: directly sign in
        try {
          final cred = await _auth.signInWithCredential(credential);
          await _syncUserToFirestore(cred.user!);
        } catch (_) {}
      },
      verificationFailed: (e) => onError(
          '[${e.code}] ${e.message ?? "OTP failed"}'),
      codeSent: (id, _) => onSent(id),
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  // ════════════════════════════════════════════════════════
  //  PHONE LOGIN — Step 2
  //  OTP → verify → signIn → update lastLogin in Firestore
  // ════════════════════════════════════════════════════════
  Future<void> verifyPhoneLoginOtp({
    required String verificationId,
    required String otp,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: otp.trim(),
    );
    final cred = await _auth.signInWithCredential(credential);
    await _syncUserToFirestore(cred.user!);
  }

  // ════════════════════════════════════════════════════════
  //  FORGOT PASSWORD (EMAIL FLOW)
  //  Email → Firebase sends password reset email
  //  User clicks link → enters new password
  //  We then update passwordUpdatedAt in Firestore
  // ════════════════════════════════════════════════════════
  Future<void> sendEmailPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
    // NOTE: Firebase handles the reset link. After user resets,
    // they login again and we update passwordUpdatedAt then.
  }

  // ════════════════════════════════════════════════════════
  //  FORGOT PASSWORD (EMAIL: Re-authenticate + update password)
  //  Call this after user enters their email OTP / reset link
  //  and wants to set a new password while signed in.
  // ════════════════════════════════════════════════════════
  Future<void> updateEmailPassword({
    required String email,
    required String currentOrTempPassword,
    required String newPassword,
  }) async {
    // Re-authenticate first (required by Firebase for password change)
    final credential = EmailAuthProvider.credential(
      email: email.trim(),
      password: currentOrTempPassword,
    );
    await _auth.currentUser!.reauthenticateWithCredential(credential);
    await _auth.currentUser!.updatePassword(newPassword);
    // Save passwordUpdatedAt in Firestore
    await _users.doc(_auth.currentUser!.uid).update({
      'passwordUpdatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ════════════════════════════════════════════════════════
  //  FORGOT PASSWORD (PHONE FLOW) — Step 1
  //  Phone → Firebase sends OTP
  // ════════════════════════════════════════════════════════
  Future<void> sendForgotPasswordOtp({
    required String phone,
    required void Function(String verificationId) onSent,
    required void Function(String error) onError,
  }) async {
    if (kIsWeb) {
      onError(
        '[web] Phone SMS OTP does not work in browser. Install Android app on a real phone or use USB: flutter run',
      );
      return;
    }
    if (kDebugMode) {
      debugPrint('[PhoneAuth] Sending OTP to: $phone');
    }
    await _auth.verifyPhoneNumber(
      phoneNumber: phone,
      timeout: const Duration(seconds: 120),
      verificationCompleted: (_) {},
      verificationFailed: (e) {
        if (kDebugMode) {
          debugPrint('[PhoneAuth] FAILED: ${e.code} — ${e.message}');
        }
        onError('[${e.code}] ${e.message ?? "OTP failed"}');
      },
      codeSent: (id, _) {
        if (kDebugMode) {
          debugPrint('[PhoneAuth] SMS code sent, verificationId received');
        }
        onSent(id);
      },
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  // ════════════════════════════════════════════════════════
  //  FORGOT PASSWORD (PHONE FLOW) — Step 2
  //  OTP verify → signIn → update password → Firestore update
  //  THIS IS THE KEY: after OTP verify, new password is set
  //  AND Firestore passwordUpdatedAt is updated
  // ════════════════════════════════════════════════════════
  Future<void> resetPasswordWithPhoneOtp({
    required String verificationId,
    required String otp,
    required String newPassword,
  }) async {
    // Step 1: verify OTP → sign in with phone
    final phoneCredential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: otp.trim(),
    );
    final userCred = await _auth.signInWithCredential(phoneCredential);
    final user = userCred.user!;

    // Step 2: the user signed in via phone. Now update password.
    // For this to work, the account must also have email linked.
    // We update password through Firebase Auth.
    await user.updatePassword(newPassword);

    // Step 3: Save passwordUpdatedAt in Firestore
    await _users.doc(user.uid).update({
      'passwordUpdatedAt': FieldValue.serverTimestamp(),
      'lastLogin': FieldValue.serverTimestamp(),
    });
  }

  // ════════════════════════════════════════════════════════
  //  REGISTER — Email + password; phone & profile → Firestore only
  //  (No SMS OTP, no email verification mail.)
  // ════════════════════════════════════════════════════════
  Future<void> registerWithoutVerification({
    required String email,
    required String password,
    required UserModel userData,
    dynamic photoFile,
  }) async {
    final emailCred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = emailCred.user!;

    String photoUrl = userData.photoUrl;
    if (photoFile != null) {
      final uploadedUrl = await uploadProfilePhoto(photoFile, user.uid);
      if (uploadedUrl != null) photoUrl = uploadedUrl;
    }

    final completeUser = UserModel(
      uid: user.uid,
      email: email.trim(),
      phone: userData.phone,
      firstName: userData.firstName,
      lastName: userData.lastName,
      nicNumber: userData.nicNumber,
      dateOfBirth: userData.dateOfBirth,
      personalAddress: userData.personalAddress,
      district: userData.district,
      province: userData.province,
      photoUrl: photoUrl,
      role: 'customer',
      phoneVerified: false,
      toursCount: 0,
      rating: 0.0,
      savedCount: 0,
    );
    await _users.doc(user.uid).set(completeUser.toMap());
  }

  // ════════════════════════════════════════════════════════
  //  GOOGLE SIGN-IN  (needs: Firebase Console Google enabled + Android SHA-1)
  // ════════════════════════════════════════════════════════
  /// Returns `false` if user closed the Google picker (cancel).
  Future<bool> signInWithGoogle() async {
    final GoogleSignIn googleSignIn = GoogleSignIn(
      clientId: kIsWeb
          ? '503013545287-0nsd52h7i1hhjjchlgtv335g5qrtu1pg.apps.googleusercontent.com'
          : null,
    );
    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) return false;

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final cred = await _auth.signInWithCredential(credential);
    await _syncUserToFirestore(cred.user!);
    return true;
  }

  // ════════════════════════════════════════════════════════
  //  APPLE SIGN-IN
  // ════════════════════════════════════════════════════════
  Future<void> signInWithApple() async {
    // Generate nonce for security (required by some Firebase versions/flows)
    final rawNonce = _generateNonce();
    final nonce = _sha256ofString(rawNonce);

    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: nonce,
    );

    final OAuthCredential credential = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      rawNonce: rawNonce,
    );

    final cred = await _auth.signInWithCredential(credential);
    
    // Apple only provides full name on the FIRST sign-in.
    // If we have it, we should use it.
    String? firstName = appleCredential.givenName;
    String? lastName = appleCredential.familyName;
    
    await _syncUserToFirestore(cred.user!, firstName: firstName, lastName: lastName);
  }

  // ── Sync User to Firestore ───────────────────────────────
  Future<void> _syncUserToFirestore(User user, {String? firstName, String? lastName}) async {
    final doc = await _users.doc(user.uid).get();
    
    if (!doc.exists) {
      // New User
      final names = (user.displayName ?? '').split(' ');
      final newUser = UserModel(
        uid: user.uid,
        email: user.email ?? '',
        phone: user.phoneNumber ?? '',
        firstName: firstName ?? (names.isNotEmpty ? names.first : ''),
        lastName: lastName ?? (names.length > 1 ? names.last : ''),
        nicNumber: '',
        dateOfBirth: '',
        personalAddress: '',
        district: '',
        province: '',
        photoUrl: user.photoURL ?? '',
        role: 'customer',
        phoneVerified: user.phoneNumber != null,
        toursCount: 0,
        rating: 0.0,
        savedCount: 0,
      );
      await _users.doc(user.uid).set(newUser.toMap());
    } else {
      // Existing User - just update lastLogin
      await _users.doc(user.uid).update({
        'lastLogin': FieldValue.serverTimestamp(),
      });
    }
  }

  // ── Helpers for Apple Sign-in ────────────────────────────
  String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // ════════════════════════════════════════════════════════
  //  GET USER DATA FROM FIRESTORE
  // ════════════════════════════════════════════════════════
  Future<UserModel?> getUserData(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data() as Map<String, dynamic>);
  }

  Stream<UserModel?> userStream(String uid) {
    return _users.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      final data = doc.data();
      if (data == null) return null;
      return UserModel.fromMap(data as Map<String, dynamic>);
    });
  }

  // ════════════════════════════════════════════════════════
  //  SIGN OUT
  // ════════════════════════════════════════════════════════
  Future<void> signOut() async {
    final GoogleSignIn googleSignIn = GoogleSignIn(
      clientId: kIsWeb
          ? '503013545287-0nsd52h7i1hhjjchlgtv335g5qrtu1pg.apps.googleusercontent.com'
          : null,
    );
    await googleSignIn.signOut().catchError((_) => null);
    await _auth.signOut();
  }

  // ── Helper: normalize to E.164 (+[digits]). Legacy SL local 0xx → +94. ──
  static String formatPhone(String phone) {
    final trimmed = phone.trim();
    final noSep = trimmed.replaceAll(RegExp(r'[\s\-().]'), '');
    if (noSep.startsWith('+')) {
      final d = noSep.substring(1).replaceAll(RegExp(r'\D'), '');
      return '+$d';
    }
    if (noSep.startsWith('00')) {
      final d = noSep.substring(2).replaceAll(RegExp(r'\D'), '');
      return '+$d';
    }
    final digitsOnly = noSep.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.startsWith('07') && digitsOnly.length == 10) {
      return '+94${digitsOnly.substring(1)}';
    }
    if (digitsOnly.startsWith('94') && digitsOnly.length == 11) {
      return '+$digitsOnly';
    }
    if (digitsOnly.isNotEmpty) {
      return '+$digitsOnly';
    }
    return '+';
  }

  // ════════════════════════════════════════════════════════
  //  DELETE ACCOUNT (with re-authentication)
  // ════════════════════════════════════════════════════════
  Future<void> deleteAccountWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw 'No user signed in';

    // 1. Re-authenticate (Required for deletion)
    final credential = EmailAuthProvider.credential(
      email: email.trim(),
      password: password,
    );
    await user.reauthenticateWithCredential(credential);

    final uid = user.uid;

    // 2. Delete Firestore data
    await _users.doc(uid).delete();

    // 3. Delete Storage photo if exists
    try {
      await _storage.ref().child('profiles').child('$uid.jpg').delete();
    } catch (_) {}

    // 4. Delete Auth account
    await user.delete();
  }
}

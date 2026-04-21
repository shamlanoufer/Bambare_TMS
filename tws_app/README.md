# tws_app

A new Flutter project.

## Firebase Setup (for real OTP & Password Reset)

For **email** and **phone** password reset + OTP to work with real Firebase:

### 1. Enable Auth Methods
- Go to [Firebase Console](https://console.firebase.google.com) → your project → **Authentication** → **Sign-in method**
- Enable **Email/Password**
- Enable **Phone**

### 2. Phone OTP – Add SHA Fingerprints (Android)
Phone OTP won’t work until SHA-1 is added:
- **Windows:** Run `get_sha.bat` or: `cd android` then `.\gradlew signingReport`
- Copy **SHA-1** and **SHA-256**
- Firebase Console → **Project Settings** → **Your apps** → Android app → **Add fingerprint**
- Paste SHA-1 and SHA-256, then Save

### 3. Email reset link
- **Email = reset LINK, not OTP.** User gets an email with a link to set new password
- Check **spam/junk** folder if email not received
- Firebase Console → Authentication → Templates → customize the password reset email if needed

### 4. Test Phone Numbers (optional)
- Authentication → Sign-in method → Phone → Add test phone numbers for development

### 5. Google & Apple sign-in (social login)

Code alone is not enough — providers must be **enabled** in Firebase and (for Android Google) **SHA-1** must match.

| Step | What to do |
|------|------------|
| **Firebase Console** | **Authentication** → **Sign-in method** → enable **Google** and **Apple** (toggle on, save). |
| **SHA-1 (Android + Google)** | Same as phone OTP: **Project settings** → your Android app → **Add fingerprint** → paste **debug SHA-1** (and SHA-256). Required for Google Sign-In on Android. |
| **Apple** | Needs an **Apple Developer** account: enable **Sign in with Apple** for your App ID, create a **Service ID** / key if using web, and configure the Apple provider in Firebase (Services ID, Team ID, Key ID, private key). iOS: add **Sign in with Apple** capability in Xcode. |

See also: [Firebase Google sign-in](https://firebase.google.com/docs/auth/android/google-signin), [Apple sign-in](https://firebase.google.com/docs/auth/ios/apple).

---

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

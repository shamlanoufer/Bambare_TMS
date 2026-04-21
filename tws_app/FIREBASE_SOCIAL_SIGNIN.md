# Social sign-in (Google & Apple) — Firebase checklist

Social buttons in the app **only work** if these are done in Firebase and (for Apple) Apple Developer.

## 1. Firebase Console — enable providers

1. Open [Firebase Console](https://console.firebase.google.com) → your project  
2. **Build** → **Authentication** → **Sign-in method**  
3. Enable **Google** (set support email, save)  
4. Enable **Apple** (fill Apple config if prompted, save)

Until both are **on**, sign-in from the app will fail.

## 2. Android — SHA-1 for Google Sign-In

Google Sign-In on Android uses the same fingerprints as Phone Auth:

- **Project settings** (gear) → **Your apps** → Android  
- **Add fingerprint** → paste **SHA-1** (and **SHA-256**) from your debug keystore  
- Re-download `google-services.json` only if Firebase asks you to

Without SHA-1, Google often shows `DEVELOPER_ERROR` or auth errors.

## 3. Apple Sign-In — Apple Developer

- Paid **Apple Developer Program** membership  
- App ID: enable **Sign in with Apple**  
- iOS: **Xcode** → Signing & Capabilities → add **Sign in with Apple**  
- Firebase **Apple** provider: Team ID, Services ID, Key ID, private key (as per [Firebase Apple docs](https://firebase.google.com/docs/auth/ios/apple))

Apple sign-in is **not** configured by code alone.

---

**Summary:** Enable **Google + Apple** in Firebase → add **SHA-1** for Android Google → complete **Apple** setup in Apple Developer + Firebase.

# Vera Firebase Project Use Panna

Pudhu Firebase account la project create pannitu, idha connect pannanum na:

---

## Step 1: FlutterFire CLI install

Terminal la:
```bash
dart pub global activate flutterfire_cli
```

---

## Step 2: Pudhu Firebase connect pannunga

Project folder la:
```bash
cd c:\Users\Vidhu\Desktop\tws_app
flutterfire configure
```

- Pudhu Firebase **account** la sign in pannunga (browser open aagum)
- **Create project** (pudhuchu) or **existing project** select pannunga
- Android / iOS / Web apps create aagum — **package name** `com.example.tws_app` same ah irukkanum
- Oru mattum thaan **Android** use pannina, adha select pannunga

---

## Step 3: Auto-update

`flutterfire configure` run pannumbodhu:

- `lib/firebase_options.dart` — pudhu project values ku **replace** aagum
- `android/app/google-services.json` — pudhu file **download** aagum
- iOS irundha `ios/Runner/GoogleService-Info.plist` — adhum update aagum

---

## Step 4: Pudhu Firebase la setup (same as before)

| Item | Enna pannanum |
|------|----------------|
| **Authentication** | Email/Password, Phone, Google, Apple — **Enable** pannunga |
| **SHA-1 & SHA-256** | Project settings → Android app → **Add fingerprint** (debug keystore) |
| **Firestore** | `users` collection — app auto create pannum first user sign-in ku |
| **Storage** | Photo upload use pannina — Storage rules set pannunga |

---

## Summary

1. `dart pub global activate flutterfire_cli`
2. `flutterfire configure` → pudhu account la login → project select
3. Pudhu Firebase Console la Authentication, SHA-1, etc. enable pannunga

App code **change panna venam illa** — `firebase_options.dart` mattum replace aagum.

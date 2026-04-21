# Phone OTP varadhu — full checklist

## 1) Neenga **Chrome / localhost** la test pannina?

**SMS OTP browser-la reliable aa work aagadhu.**  
→ **Android real phone** connect pannunga: `flutter run`  
→ illana **APK** build pannunga phone-la install pannunga.

App code ippove web-la phone OTP block pannum; clear message show aagum.

---

## 2) Firebase — SHA fingerprints (Android app)

1. Project settings → Your apps → **Android** (`com.example.tws_app`)
2. **SHA-1** + **SHA-256** add (debug keystore fingerprints — see chat / `keytool` command)

---

## 3) Phone sign-in **Enable**

Authentication → Sign-in method → **Phone** → **Enable**

---

## 4) Test number (SMS wait panna mudiyala)

Authentication → Phone → **Phone numbers for testing**  
Example: `+94771234567` + fixed OTP `123456`

---

## 5) Real device

- Emulator SMS miss aagum — **real phone** use pannunga  
- Google Play Services update irukkanum

---

**Short:** OTP venum na **Android app on real phone** + Firebase SHA + Phone enable.
